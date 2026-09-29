/* Local setup audit. The wizard is mounted without authentication; no publish action is tapped. */
(async () => {
  let checks=0;
  const check=(ok,label)=>{if(!ok)throw new Error(label);checks++;};
  state.demo=false; state.wiz=1; state.phase='setup'; state.structure='squads4';
  state.preset=2; state.cap=3; state.floor=1; state.stake=0;
  state.startISO='2026-10-03'; state.durWeeks=13; state.finish='cup_final';
  const wizard=document.getElementById('view-wizard');
  document.body.append(wizard); wizard.classList.add('on');
  const style=document.createElement('style');
  style.textContent='body > :not(#view-wizard):not(svg):not(#toast){display:none!important} #view-wizard{display:block!important;padding:20px;max-width:1100px;margin:auto}';
  document.head.append(style);
  document.getElementById('setName').value='Saturday Regulars';
  renderSetup(); renderWizard();
  check(!document.getElementById('wizNext').getClientRects().length, 'Setup shows a second primary action beside Review');
  const frequency=document.getElementById('wizardFrequency');
  frequency.value='1'; frequency.dispatchEvent(new Event('change'));
  check(state.cap===3 && state.floor===1, 'Pace silently overwrote custom rules');
  check(!document.getElementById('busyFriendsSuggestion').hidden, 'Suggestion unavailable');
  document.getElementById('useBusyFriends').click();
  check(state.cap===0 && state.floor===0, 'Suggestion did not apply best 2 / no minimum');
  check(state.preset===2 && state.structure==='squads4' && state.startISO==='2026-10-03', 'Suggestion changed unrelated settings');
  frequency.value='2'; frequency.dispatchEvent(new Event('change'));
  check(state.cap===0 && state.floor===0, 'Second pace overwrote the accepted suggestion');
  document.getElementById('capUp').click(); document.getElementById('floorUp').click();
  check(state.cap===1 && state.floor===1, 'Suggested choices are not editable');
  check(document.getElementById('setupMinimumConsequence').textContent.includes('removed from the team total'), 'Wrong Cutthroat consequence');
  state.preset=1; renderSetup();
  check(document.getElementById('setupMinimumConsequence').textContent.includes('5 points per round short'), 'Wrong Standard consequence');
  state.structure='solo'; renderSetup();
  check(document.getElementById('setupMinimumConsequence').textContent.includes('No team penalty'), 'Solo claims team penalty');
  state.structure='squads4'; state.stake=20; state.payout=[70,20,10];
  document.getElementById('payNote').value='Pay Sam'; renderSetup();
  check(document.querySelectorAll('#payNote').length===1, 'Payment input ID is duplicated');
  check(csPayNote()==='Pay Sam', 'Payout display corrupted payment instructions');
  check(!document.getElementById('lockBtn').disabled, 'Valid payment note blocks review');
  document.getElementById('payNote').value=''; csRenderPayNote();
  check(document.getElementById('lockBtn').disabled, 'Paid league can start without payment instructions');
  document.getElementById('payNote').value='Pay Sam'; csRenderPayNote();
  document.getElementById('wizFastPath').click();
  /* D234 · two shapes, one review: the step's own rules card shows at every
     width (the owner's panel found the desk's "Review the rules" step showing
     no rules while the aside stood in for them); at 1100 and up the sticky
     aside is the season's portrait BESIDE it. */
  const review=document.getElementById('bylawsReview'), aside=document.getElementById('wizAside');
  const desk=matchMedia('(min-width:1100px)').matches;
  check(state.wiz===2 && review.getClientRects().length>0 && (!desk || (aside.getClientRects().length>0 && aside.textContent.trim().length>0)), 'Review did not open, or the desk lost its rules');
  check(review.textContent.includes('monthly counting limit') && !review.textContent.includes('scored fresh'), 'Final agreement omits eligibility limitation');
  check(review.textContent.includes('Pay Sam') && review.textContent.includes('4 squads'), 'Review lost money instructions or custom squad count');
  check(state.startISO==='2026-10-03', 'Review moved the chosen first tee');
  check(review.textContent.includes('Oct 3') && review.textContent.includes('Jan 2'), 'Review did not render the chosen season dates');
  document.getElementById('wizBack').click();
  check(state.wiz===1 && state.cap===1 && state.floor===1, 'Back lost custom choices');
  // Leave the supported busy-group setup visible for visual inspection.
  state.stake=0; state.preset=1; csUseBusyFriends(state); frequency.value='1'; renderSetup();
  if(new URLSearchParams(location.search).has('review')) document.getElementById('wizFastPath').click();
  await new Promise(resolve=>setTimeout(resolve,600));
  return {checks, width:innerWidth, view:state.wiz===2?'agreement':'choices'};
})()
