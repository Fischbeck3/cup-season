(async()=>{
 const $=s=>document.querySelector(s), click=s=>{if(!$(s))throw Error('Missing '+s);$(s).click();};
 const checks=[]; const ok=(v,m)=>{if(!v)throw Error(m);checks.push(m);};
 const action=n=>click('[data-action="'+n+'"]'), step=n=>click('[data-step="'+n+'"]');
 const wait=()=>new Promise(r=>setTimeout(r,450));
 const change=(s,value)=>{const el=$(s);el.value=value;el.dispatchEvent(new Event('input',{bubbles:true}));};
 const fits=()=>ok(document.documentElement.scrollWidth<=innerWidth,'No horizontal overflow: '+$('#stageTitle').textContent);
 click('#keptToggle');action('add');ok(!$('[data-action=replace]'),'Kept live scorecard cannot be replaced by a plan');action('home');click('#keptToggle');action('add');action('resume');ok($('#course').value==='Encanto Golf Course'&&$('#front').value==='42','Existing draft resumes intact');fits();
 action('home');action('add');action('replace');action('gate');action('resume');ok($('#front').value==='42','Cancelling replacement preserves draft');
 action('home');action('add');action('replace');action('confirm-replace');ok($('#course').value==='Papago Golf Course'&&$('#front').value===''&&$('#back').value==='','Plan prefills course/date without score');
 change('#front','42');change('#back','42');action('home');action('add');action('resume');ok($('#back').value==='42','New entries survive returning Home');
 click('#failureToggle');$('#roundForm').requestSubmit();await wait();ok($('#front').value==='42'&&$('#back').value==='42'&&$('#notice').textContent.includes('did not save'),'Failed round save preserves entries');$('#roundForm').requestSubmit();await wait();ok($('.figure').textContent.includes('84'),'Retry shows entered gross');fits();action('receipt');action('home');ok(!$('[data-action="later"]'),'Accepted round removes follow-up');
 step('after');click('#failureToggle');action('later');await wait();ok(!!$('[data-action="later"]')&&$('#notice').textContent.includes('didn’t save'),'Failed answer remains actionable');action('later');await wait();action('home');ok(!$('[data-action="later"]'),'Later hides follow-up for this visit');
 step('after');action('didnt_play');await wait();action('home');ok(!$('[data-action="didnt_play"]'),'Terminal answer hides follow-up');
 click('#draftToggle');click('#legacyToggle');ok(!$('[data-action="later"]')&&!!$('[data-action="plain"]'),'Older server keeps ordinary Home');action('plain');ok(!$('[data-action="replace"]'),'Ordinary entry cannot replace from unsupported plan');action('resume');ok($('#course').value==='Encanto Golf Course','Older server resumes known draft');
 click('button[data-room="dark"]');click('#brand-tab');ok(document.documentElement.dataset.room==='dark'&&$('button[data-room="dark"]').getAttribute('aria-pressed')==='true','Theme survives other clicks');click('[data-treatment="terrain"]');ok(document.querySelectorAll('#applications .topo').length===5,'Contour proposal reaches five proof surfaces');fits();click('[data-treatment="clean"]');ok(document.querySelectorAll('#applications .topo').length===0,'Clean proposal removes supporting contour');
 click('button[data-room="light"]');click('#journey-tab');click('#legacyToggle');step('after');fits();
 return {checks:checks.length,passed:checks};
})()
