/* D362 · the round that counts, explained — on the desk, on fixtures.
   Before posting: what this round can add under the league's own cap, from the
   engine's rows. After: the receipt says COUNTING #n OF cap and opens the
   member's rounds that count. No account, no writes. */
(async function(){
  const check=(ok,label)=>{ if(!ok) throw new Error(label); };
  const out={};
  /* a live season with a cap of 4, and the golfer's engine rows this month */
  const month=isoOf(new Date()).slice(0,7);
  window.CS = window.CS || {}; window.CS.season = window.CS.season || { id:'fixture-season', starts_on:'2026-01-01', ends_on:'2026-12-31', status:'active' };
  window.CS.league = window.CS.league || { id:'fixture-league', name:'FIXTURE LEAGUE' };
  window.CS.member = { id:'m-me' }; window.CS.user = { id:'p-me' }; window.CS.members=[{ id:'m-me', profile_id:'p-me' },{ id:'m-jade', profile_id:'p-jade' }];
  const realState=seasonState;
  window.seasonState = () => 'live';
  try{
    /* two counting rounds so far: worth up to the ceiling; best 4 count and you have 2 */
    window.myRanked=[{ played_on:month+'-03', month_rank:1, points:9 },{ played_on:month+'-10', month_rank:2, points:5 },{ played_on:'2025-01-01', month_rank:1, points:12 }];
    const two=csComposerWorthLine(month+'-20', 4);
    check(/worth up to/.test(two) && /best 4 count and you have 2/.test(two),'capped with room: '+two);
    /* a full month: worth up to X MORE; your worst is a 5 */
    window.myRanked=[1,2,3,4].map(i=>({ played_on:month+'-0'+i, month_rank:i, points:[9,8,7,5][i-1] }));
    const full=csComposerWorthLine(month+'-20', 4);
    check(/more/.test(full) && /worst is a 5/.test(full),'a full month: '+full);
    /* a month already made of top-band rounds: cannot add, still builds the number */
    window.myRanked=[1,2,3,4].map(i=>({ played_on:month+'-0'+i, month_rank:i, points:12 }));
    const capped=csComposerWorthLine(month+'-20', 4);
    check(/cannot add/.test(capped) && /builds your number/.test(capped),'top-band month: '+capped);
    /* uncapped: every round counts */
    window.myRanked=[{ played_on:month+'-03', month_rank:1, points:9 }];
    const open=csComposerWorthLine(month+'-20', null);
    check(/Every round you post this month counts/.test(open),'uncapped: '+open);
    /* no live season: nothing is promised */
    window.seasonState = () => 'pre';
    check(csComposerWorthLine(month+'-20', 4)===null,'a ceiling was guessed outside a live season');
    window.seasonState = () => 'live';
    out.composer={ room:two, full, capped, open };

    /* the receipt: COUNTING #2 OF 4, and the door to the rounds that count */
    window.indRows=[{ mid:'m-me', n:'You', r:3, pts:21, me:true, hist:[{ round_id:'r1', played_on:month+'-03', points:9, counting:true },{ round_id:'r2', played_on:month+'-10', points:5, counting:false }] },
                    { mid:'m-jade', n:'FIXTURE · Jade', r:2, pts:18, me:false, hist:[{ round_id:'r3', played_on:month+'-04', points:9, counting:true }] }];
    const body=roundCardBody({ profile_id:'p-me', gross:84, rating:70.1, slope:120, pvi:0.4, points:5, month_rank:2, counting_cap:4 }, 0.4, 4);
    check(/COUNTING #2 OF 4/.test(body),'the denominator is missing: '+body.replace(/<[^>]+>/g,' ').slice(0,200));
    check(/data-counting-for="m-me"/.test(body) && /Your rounds that count/.test(body),'no door to the rounds that count');
    const bumped=roundCardBody({ profile_id:'p-me', gross:90, pvi:-3, points:2, month_rank:5, counting_cap:4 }, -3, 4);
    check(/BUMPED/.test(bumped),'a bumped round did not say so');
    const theirs=roundCardBody({ profile_id:'p-jade', gross:77, pvi:2.6, points:9, month_rank:1, counting_cap:4 }, 2.6, 4);
    check(/Their rounds that count/.test(theirs),'a rival\'s receipt lost its door');
    const elsewhere=roundCardBody({ profile_id:'p-nobody', gross:77, pvi:2.6, points:9, month_rank:1, counting_cap:4 }, 2.6, 4);
    check(!/data-counting-for/.test(elsewhere),'a round outside the open league offered a door it cannot open');
    const uncapped=roundCardBody({ profile_id:'p-me', gross:84, pvi:0.4, points:5, month_rank:2 }, 0.4, Infinity);
    check(/COUNTING #2<\/b>/.test(uncapped),'an uncapped league printed a denominator it does not have');
    /* the door opens the member's history */
    let opened=null; const realHist=window.openMemberHist; window.openMemberHist=(p)=>{ opened=p; };
    const sb_=document.getElementById('shBody'); const prev=sb_.innerHTML; sb_.innerHTML=body;
    sb_.__countingDoor=false;
    /* the listener is installed by the receipt opener; install it the same way here */
    sb_.addEventListener('click', e=>{ const b=e.target.closest('[data-counting-for]'); if(!b) return; const p=(window.indRows||[]).find(x=>String(x.mid)===b.dataset.countingFor); if(p) window.openMemberHist(p); });
    sb_.querySelector('[data-counting-for]').click();
    check(opened && opened.mid==='m-me','the door did not open the member history');
    window.openMemberHist=realHist; sb_.innerHTML=prev;
    out.receipt={ counting:'COUNTING #2 OF 4', door:true };
  } finally { window.seasonState=realState; }
  out.passed=true;
  return JSON.stringify(out);
})()
