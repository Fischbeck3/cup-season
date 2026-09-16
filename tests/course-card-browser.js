/* D364 · the course record opens on one tee and lets you change it; the plan
   says its tee and opens the whole scorecard; a saved course says what the
   copy is for (F1 / F2 / F3) — on the desk, on a fixture book, no account. */
(async function(){
  const check=(ok,l)=>{ if(!ok) throw new Error(l); };
  const out={};
  const holes=y=>[...Array(18).keys()].map(i=>({ hole:i+1,
    par:[4,5,3,4,4,5,3,4,4, 4,3,5,4,4,3,4,5,4][i], si:[7,1,15,9,3,5,17,11,13, 8,16,2,10,4,18,12,6,14][i],
    yards:y ? 300+i*11 : null }));
  const book={ id:'fixture-course', club_name:'Fixture Club', course_name:'Fixture Club', city:'Tempe', state:'AZ',
    savedAt:Date.now(), usedAt:Date.now(),
    tees:[{ tee_name:'Blue', gender:'male',   course_rating:71.2, slope_rating:131, number_of_holes:18, total_yards:6412, par_total:72, holes:holes(true) },
          { tee_name:'Gold', gender:'male',   course_rating:73.3, slope_rating:137, number_of_holes:18, total_yards:6980, par_total:72, holes:holes(true) },
          { tee_name:'Blue', gender:'female', course_rating:76.0, slope_rating:140, number_of_holes:18, total_yards:6412, par_total:72, holes:holes(true) }] };
  const prev=localStorage.getItem('cs.courses.v1');
  localStorage.setItem('cs.courses.v1', JSON.stringify([book]));
  window.CS_COURSE_TEE={};
  try{
    /* 1 · the record: one tee leads, every rated tee is a choice, the card carries yardage */
    renderCourseBooks();
    const box=document.getElementById('youCourses');
    const sel=box.querySelector('select[data-cstee]');
    check(sel && sel.options.length===3,'a tee picker with every rated tee');
    check(/Gold/.test(sel.selectedOptions[0].textContent),'the longest rated 18 leads when nothing was chosen: '+sel.selectedOptions[0].textContent);
    check(/6,980/.test(box.textContent),'the lead facts are the Gold tee’s');
    check([...box.querySelectorAll('.cs-leaf table th')].some(th=>th.textContent==='YDS'),'a YDS row on the card');
    /* changing tees changes the facts and the card together; a women's Blue is its own tee */
    sel.value=csTeeKey(book.tees[2]); sel.dispatchEvent(new Event('change',{ bubbles:true }));
    await new Promise(r=>setTimeout(r,60));
    const sel2=box.querySelector('select[data-cstee]');
    check(/Women/.test(sel2.selectedOptions[0].textContent) && /76/.test(box.textContent),'changing tees changes the facts: '+sel2.selectedOptions[0].textContent);
    out.record={ options:sel2.options.length, chosen:sel2.selectedOptions[0].textContent.trim() };

    /* 2 · the plan block: the plan's tee, the door, no graphic, no decisive holes */
    const html=csPlanCourseHtml('fixture-course','Blue');
    check(/data-cs-plan-tee/.test(html) && /Blue tees/.test(html) && /Your tee for this round/.test(html),'the plan names its tee');
    check(/View scorecard/.test(html) && /data-cs-scorecard/.test(html) && /YDS/.test(html),'View scorecard opens the whole card with yardage');
    check(!/cs-plan-card|three that decide|cs-hard/.test(html),'no bar graphic, no decisive holes');
    const none=csPlanCourseHtml('fixture-course', null);
    check(/longest rated 18/.test(none),'no tee named: the longest, said as such');
    out.plan={ tee:(html.match(/data-cs-plan-tee="1"><b>([^<]+)/)||[])[1] };

    /* 3 · the storage line says what the copy is FOR, and when it is from */
    const line=csCourseSavedLine(book);
    check(/^Available offline · saved today$/.test(line),'the storage line: '+line);
    out.saved=line;
  } finally {
    if(prev==null) localStorage.removeItem('cs.courses.v1'); else localStorage.setItem('cs.courses.v1', prev);
    window.CS_COURSE_TEE={};
  }
  return out;
})()
