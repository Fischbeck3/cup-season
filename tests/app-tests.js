/* Cup Season in-browser function suite. All targets are classic-block
   globals, so this runs from the console of a locally served app:

     python -m http.server 8791  ->  open localhost:8791/?exit
     paste this file into the console (or inject via the browser MCP)

   Read-only: pure functions + one DOM-scratch odometer check. Prints one
   line per test and a PASS/FAIL summary; returns the summary object. */
(function(){
  const R = [];
  const t = (name, got, want) => {
    const ok = Object.is(got, want) || JSON.stringify(got) === JSON.stringify(want);
    R.push({ name, ok, got, want });
    console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : ` — got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`));
  };

  /* esc — the XSS gate */
  t('esc: angle brackets', esc('<b>hi</b>'), '&lt;b&gt;hi&lt;/b&gt;');
  t('esc: quotes + amp', esc(`a&'"z`), 'a&amp;&#39;&quot;z');
  t('esc: null-safe', esc(null), '');
  t('esc: number passthrough', esc(84), '84');

  /* localDate — the Phoenix off-by-one landmine */
  t('localDate: local not UTC', localDate('2026-07-21').getDate(), 21);
  t('localDate: month index', localDate('2026-01-02').getMonth(), 0);

  /* durMonths — season_months DESCRIBES the window (D143). It used to be
     clamped up to 3 because the CHECK was 3..12, which meant a 2-week season
     stored "3 months" and the stored bylaw contradicted the real dates. The
     CHECK is 1..12 now and lock_league derives the months from the dates, so a
     short season finally describes itself honestly. */
  t('durMonths: 18wk season', durMonths(18), 4);
  t('durMonths: short season is honest', durMonths(4), 1);
  t('durMonths: never zero', durMonths(1), 1);
  t('durMonths: clamps ceiling', durMonths(80), 12);

  /* the named bands — UI speaks bands, never PvI */
  t('bandName: even round is a type', typeof bandName(0), 'string');
  t('bandName: hot round differs from rough day', bandName(-6) === bandName(6), false);
  t('vsPhrase: mentions the number', /number/i.test(vsPhrase(-2.4)), true);

  /* Q-20 · one rule, three implementations (web pointsFor, web bandName,
     server cup_points) — they disagreed at exactly -1.0, where the client
     promised 7 points and the table paid 6. The engine is authoritative and
     half-open; these pin the client to it. db-checks 17 pins the engine. */
  t('bands: -1.0 scores 6, like cup_points', pointsFor(-1.0)[0], 6);
  t('bands: -1.0 is named for the points it pays', bandName(-1.0), 'A little loose');
  t('bands: -0.99 is still played-to-it', [pointsFor(-0.99)[0], bandName(-0.99)], [7, 'Played to it']);

  /* D189 · the door's story. .ob-fold has reserved 54px below the viewport
     since it was written and .ob-more already carried an entrance animation —
     but NO element ever used it: the slot was built and never filled, and 8 of
     8 testers could not say what the product was from the slogan alone. The
     section is static markup so it survives a boot that never ran (D186). */
  (function(){
    const more = document.getElementById('obMore');
    t('door: the story section exists', !!more, true);
    t('door: five rows', more ? more.querySelectorAll('.obm-row').length : 0, 5);
    t('door: the cue points at it', (document.getElementById('obCue')||{}).getAttribute?.('href'), '#obMore');
    /* D117: sourced VERBATIM from the meta description, never a third paraphrase */
    const meta = (document.querySelector('meta[name="description"]')||{}).content || '';
    const line = (document.querySelector('.onboard .ob-hero p')||{}).textContent || '';
    t('door: the sentence is the meta description, verbatim', meta.includes(line.trim()), true);
    /* the Founding League offer is a standing decision to keep OFF the front
       door — it lives in outreach only — and the 1,000 trigger is internal. */
    const txt = more ? more.textContent : '';
    t('door: no Founding League offer on the front door', /founding/i.test(txt), false);
    t('door: no internal pricing trigger on the front door', /1,?000/.test(txt), false);
    t('door: the solo arrival gets a door that needs nobody', !!document.getElementById('obCrewInvite'), true);
  })();

  /* D188 · qaEvent's guard was `state.demo || !window.sb`, and state.demo starts
     TRUE and clears only after the golfer card is saved — so every crew-step
     breadcrumb on the cold-signup path was swallowed. Exactly the shape D185
     fixed for growthEvent, surviving one node deeper. The real precondition is
     a signed-in user; RLS ce_insert_own is the actual gate. */
  (function(){
    const prevSb = window.sb, prevCS = window.CS, prevDemo = state.demo;
    let sent = [];
    window.sb = { from: () => ({ insert: r => { sent.push(r); return { then: () => {} }; } }) };
    state.demo = true;                       /* the diorama flag, as at signup */
    window.CS = { user: { id: 'u1' } };
    qaEvent('crew_step_shown', { how: 'code' });
    t('qaEvent: survives the demo flag when a user is signed in', sent.length, 1);
    sent = []; window.CS = {};               /* signed out */
    qaEvent('crew_step_shown');
    t('qaEvent: still silent with no signed-in user', sent.length, 0);
    window.sb = prevSb; window.CS = prevCS; state.demo = prevDemo;
  })();

  /* D182 · the round that stops at eleven. liveCardHoles used to require that
     NOTHING was scored past hole 9 for a front nine to count, so a 10-hole
     walk-off reported 0 and vanished at finish — the owner lost a real 46-stroke
     ten that way. A complete front nine is now a nine whatever follows it, and
     liveCardDropped names what will not count. Server side proven on Postgres
     16: the same card posts gross 46, holes 9, dropped 1. */
  (function(){
    const prev = state.live;
    const card = a => { state.live = { scores: [a], pmap: { 0: true } }; };
    const nine = [5,4,6,5,5,4,5,6,6];
    card(nine.concat([5]));
    t('liveCardHoles: ten holes is a nine (was 0)', liveCardHoles(0), 9);
    t('liveCardDropped: names the stray hole', liveCardDropped(0), 1);
    card(nine.concat([5,4,5,6,5]));
    t('liveCardHoles: fourteen holes is a nine', liveCardHoles(0), 9);
    t('liveCardDropped: names all five', liveCardDropped(0), 5);
    card(nine);
    t('liveCardHoles: a clean nine is still a nine', liveCardHoles(0), 9);
    t('liveCardDropped: nothing dropped', liveCardDropped(0), 0);
    card([5,4,null,5,5,4,5,6,6,5]);
    t('liveCardHoles: a gap in the front nine still posts nothing', liveCardHoles(0), 0);
    card([4,4,5,4,5,4,4,5,4,4,4,5,4,5,4,4,5,4]);
    t('liveCardHoles: eighteen is unchanged', liveCardHoles(0), 18);
    t('liveCardDropped: eighteen drops nothing', liveCardDropped(0), 0);
    state.live = prev;
  })();

  /* D187 · rcptPvi — ONE producer for the receipt's signed figure. Two call
     sites each carried their own copy of this ternary at 100% while the engine
     paid at 95%, so the same round could show two different figures and two
     different band names a second apart. The worked case below is real: it was
     reproduced end-to-end on Postgres — index 13.6, differential 12.4, a 95%
     league. At 100% it reads 1.2 and pays 9 ("Beat your number"); the engine
     paid 0.5 and 7 ("Played to it"). Home published the 9 for the life of the
     product. */
  t('rcptPvi: prefers the server figure', rcptPvi({ pvi: 0.5, index_at_post: 13.6, differential: 12.4 }), 0.5);
  t('rcptPvi: applies the round\'s own allowance',
    rcptPvi({ index_at_post: 13.6, differential: 12.4, handicap_allowance: 95 }), 0.5);
  t('rcptPvi: the 100% answer is the OLD wrong one',
    rcptPvi({ index_at_post: 13.6, differential: 12.4, handicap_allowance: 100 }), 1.2);
  t('rcptPvi: 95 vs 100 crosses a band', [
      bandName(rcptPvi({ index_at_post: 13.6, differential: 12.4, handicap_allowance: 95 })),
      bandName(rcptPvi({ index_at_post: 13.6, differential: 12.4, handicap_allowance: 100 }))
    ], ['Played to it', 'Beat your number']);
  t('rcptPvi: 90% allowance is honoured too',
    rcptPvi({ index_at_post: 13.6, differential: 12.4, handicap_allowance: 90 }), -0.2);
  t('rcptPvi: null without the inputs', rcptPvi({ index_at_post: null, differential: 12.4 }), null);
  /* The reconciliation contract, stated correctly. The receipt shows the EXACT
     product (index x allowance%), not v_rounds_ranked.playing_index, which is
     rounded to 1dp for display. The engine subtracts the unrounded product, so
     the rounded one does NOT close: 11.0 x 95% displays 10.5, and 10.5 - 11.0
     is -0.5, while the table pays -0.6. Shown exactly (10.45) it closes. */
  (function(){
    /* The reader does this in exact decimal on a napkin, so the check must too
       — doing it in binary float is what produced the 0.1 disagreements this
       whole change exists to remove. Shown product is index x allowance/1000
       in integer thousandths; the differential is exact tenths. Cross-checked
       against Postgres 16 over 36,018 combinations (90/95/100 x index 4.0-30.0
       x differential 2.0-34.0): zero mismatches, zero cards failing to close. */
    let bad = [];
    for (const a of [90, 95, 100]) {
      for (let t = 40; t <= 300; t += 7) {
        const i = t / 10;
        for (const dt of [t - 31, t, t + 24, t + 5]) {
          const d = dt / 10;
          const shownThousandths = Math.round(playingIndexExact(i, a) * 1000);
          const byHand = csRound1(shownThousandths - Math.round(d * 10) * 100, 100);
          const pvi = rcptPvi({ index_at_post: i, differential: d, handicap_allowance: a });
          if (Math.abs(byHand - pvi) > 1e-9) bad.push([a, i, d, byHand, pvi]);
        }
      }
    }
    t('receipt closes by hand: shown product - differential === pvi (90/95/100)', bad.length, 0);
  })();
  /* the float trap this replaced: 11.0 at 95% against 7.9 read 2.5 through
     Math.round and 2.6 in the table — a whole band at the edges. */
  t('rcptPvi: matches Postgres at the .x5 midpoint',
    rcptPvi({ index_at_post: 11.0, differential: 7.9, handicap_allowance: 95 }), 2.6);
  t('rcptPvi: half away from zero on the negative side',
    rcptPvi({ index_at_post: 11.0, differential: 11.0, handicap_allowance: 95 }), -0.6);
  t('playingIndexExact: exact, not pre-rounded', playingIndexExact(11.0, 95), 10.45);
  t('playingIndexExact: three decimals when the maths needs them', playingIndexExact(13.7, 95), 13.015);
  t('bands: the phrase agrees at the edge', /over your number/.test(vsPhrase(-1.0)), true);
  (function(){
    /* the split that shipped was name-vs-points; assert they never diverge */
    const NAME = {12:'Torched it', 9:'Beat your number', 7:'Played to it', 6:'A little loose', 5:'Posted anyway'};
    let bad = null;
    for(let v = -600; v <= 600; v++){ const vs = v/100;
      if(bandName(vs) !== NAME[pointsFor(vs)[0]]){ bad = vs; break; } }
    t('bands: name and points agree across the range', bad, null);
  })();

  /* fmtIdx — plus-handicaps render golf-style (never minus) */
  t('fmtIdx: plus index renders +', fmtIdx(-1.7), '+1.7');
  t('fmtIdx: normal index plain', fmtIdx(12.4), '12.4');

  /* humanError — no raw backend jargon reaches a golfer */
  t('humanError: rls jargon humanized', /row-level|violates|policy/i.test(humanError({ message: 'new row violates row-level security policy' }, 'x')), false);
  t('humanError: returns a sentence', humanError({ message: 'weird unknown' }, 'Could not save.').length > 10, true);

  /* csOdo — the odometer keeps text truth while animating */
  (function(){
    const el = document.createElement('div'); document.body.appendChild(el);
    csOdo(el, '$525');
    t('csOdo: first set instant', el.textContent, '$525');
    csOdo(el, '$600');
    /* csOdo deliberately sets the text and skips the strips under
       prefers-reduced-motion (index.html:3913). Asserting 3 strips there fails
       for the RIGHT behaviour — which is what a headless browser run
       (Playwright defaults many contexts to reduce) reports. Assert the
       contract that holds in both worlds, and the strips only when animating. */
    const rm = matchMedia('(prefers-reduced-motion:reduce)').matches;
    t('csOdo: shows the new value', el.textContent.replace(/\s/g,'').includes('600'), true);
    if (!rm) t('csOdo: builds one strip per digit', el.querySelectorAll('.odostrip').length, 3);
    t('csOdo: dataset carries target', el.dataset.odo, '$600');
    csOdo(el, '$600');
    t('csOdo: same value is a no-op', el.dataset.odo, '$600');
    el.remove();
  })();

  /* the lock — Q-01. The bylaws lock committed four writes and THEN threw on a
     dead reference, so the Pro was told "Lock failed" about a league the server
     had just locked (25 days in prod; one lock_ok against eleven lock_fail).
     What is testable HERE is the half the Pro actually reads: openLockShare()
     must print the join URL as selectable text — that sheet is the only place
     in the file a Pro can read the link, and it is what never opened.
     lockBylaws() itself cannot be unit-tested in the browser: the module's `sb`
     is a const binding that no window.* bridge can stub, so its guarantee is
     covered by preflight's free-identifier check (the `staged` lint) and by
     driving a real lock. Self-cleaning: CS.league is restored. */
  (function(){
    const bridged = typeof window.lockBylaws === 'function' && typeof window.openLockShare === 'function';
    t('lock: lockBylaws + openLockShare bridged for QA', bridged, true);
    if (!bridged || !window.CS) return;

    const realLeague = window.CS.league, realDemo = window.state?.demo;
    window.CS.league = { id: 'l1', name: 'Test Cup', code: 'TESTCODE' };
    if (window.state) window.state.demo = false;

    Promise.resolve(window.openLockShare('draft', 0)).then(() => {
      const txt = document.querySelector('#sheet')?.innerText || '';
      t('lock: share sheet prints the join URL as text', /\?join=TESTCODE/.test(txt), true);
      t('lock: share sheet names the league', /Test Cup/.test(txt), true);
      document.querySelector('#sheet')?.classList.remove('open');
    }).catch(e => {
      t('lock: share sheet opens without throwing', String(e?.message || e), '(no throw)');
    }).finally(() => {
      window.CS.league = realLeague;
      if (window.state) window.state.demo = realDemo;
      console.log('  (the two lock lines are async — they print after the summary)');
    });
  })();

  /* D181 — the reaction bar on moments and settlements. The rule that matters
     is STRUCTURAL: a settled-game row is a role="button" whose click handler
     reads closest('[data-card]'), so a chip rendered inside it would open the
     scorecard on every tap. These assert the bar is a sibling, not a child. */
  (function(){
    const ok = typeof window.momRowHtml === 'function' && typeof window.sysRowHtml === 'function';
    t('social: momRowHtml + sysRowHtml bridged for QA', ok, true);
    if (!ok) return;
    const dom = h => { const d = document.createElement('div'); d.innerHTML = h; return d; };
    const mom = { txt: 'Barrier broken', post_id: 'p1' };
    const set = { txt: 'Skins settled', post_id: 'p2', lrid: 'L1' };

    t('social: a moment with a post row gets a bar',
      !!dom(momRowHtml(mom, 0)).querySelector('.social'), true);
    t('social: a settlement gets a bar',
      !!dom(sysRowHtml(set, 1)).querySelector('.social'), true);
    /* the whole point: the chips must not live inside the door */
    t('social: the settlement bar is OUTSIDE the scorecard door',
      dom(sysRowHtml(set, 1)).querySelector('.social').closest('[data-card]'), null);
    t('social: the door survives the bar',
      !!dom(sysRowHtml(set, 1)).querySelector('[data-card]'), true);
    /* Home and the demo diorama draw the bare row — no index, or no post row */
    t('social: no bar without a wiring index (Home)',
      !!dom(sysRowHtml(set)).querySelector('.social'), false);
    t('social: no bar on a demo item with no post row',
      !!dom(momRowHtml({ txt: 'Demo moment' }, 0)).querySelector('.social'), false);
    t('social: the moment still says what it says',
      /Barrier broken/.test(dom(momRowHtml(mom, 0)).textContent), true);
  })();

  /* D185 — the three that shipped to every stranger. All self-cleaning. */
  (function(){
    /* 1 · `.league-only` must actually hide. It was a class with no rule for
       as long as it existed; the Clubhouse escaped only because a separate
       rule hides that whole view. */
    const had = document.body.classList.contains('noleague');
    document.body.classList.add('noleague');
    const marked = [...document.querySelectorAll('.league-only')];
    t('league-only: the class is used at all', marked.length > 0, true);
    t('league-only: nothing league-scoped is visible without a league',
      marked.filter(e => e.offsetParent !== null).length, 0);
    const head = [...document.querySelectorAll('.grouphead')].find(e => /Your seasons/.test(e.textContent));
    t('league-only: the "Your seasons" head hides with its children',
      head ? head.offsetParent === null : 'head missing', true);
    if (!had) document.body.classList.remove('noleague');

    /* 2 · the monthly floor is a LEAGUE rule. A golfer with no league was told
       their squad loses 5 points a round, on the first screen after signup. */
    if (typeof renderPulse === 'function' && document.querySelector('#homePulse')) {
      const box = $('#homePulse'), realHero = window.renderHomeHero, realLeague = window.CS?.league;
      const realDemo = state.demo, realFloor = state.floor;
      window.renderHomeHero = () => {};
      let hero = document.querySelector('#homeHero'), madeHero = false;
      if (!hero) { hero = document.createElement('div'); hero.id = 'homeHero'; document.body.appendChild(hero); madeHero = true; }
      let foot = hero.querySelector('.hh-foot'), madeFoot = false;
      if (!foot) { foot = document.createElement('div'); foot.className = 'hh-foot'; hero.appendChild(foot); madeFoot = true; }
      state.demo = false; state.floor = 2;
      if (window.CS) window.CS.league = null;
      renderPulse();
      t('floor line: silent for a golfer with no league', (box.innerText || '').trim(), '');
      if (window.CS) window.CS.league = { id: 'x', name: 'Test' };
      try { renderPulse(); t('floor line: still speaks inside a league', /Monthly floor/.test(box.innerText || ''), true); }
      catch (e) { t('floor line: still speaks inside a league', 'threw ' + e.message, true); }
      box.innerHTML = '';
      if (madeFoot) foot.remove();
      if (madeHero) hero.remove();
      window.renderHomeHero = realHero;
      if (window.CS) window.CS.league = realLeague;
      state.demo = realDemo; state.floor = realFloor;
    }

    /* 3 · growthEvent must NOT bail on state.demo. It did, and demo is true
       through the whole of onboarding — which is when profile_created and
       link_opened fire. Zero rows in thirty signups. */
    if (typeof window.growthEvent === 'function' && window.sb) {
      const realRpc = window.sb.rpc, realDemo = state.demo;
      let called = null;
      window.sb.rpc = (name, args) => { called = { name, args }; return Promise.resolve({ data: null, error: null }); };
      state.demo = true;
      window.growthEvent('link_opened', 'join', 'TESTCODE');
      t('growth: a breadcrumb survives the diorama guard', called && called.name, 'log_growth_event');
      t('growth: it carries the node through', called && called.args && called.args.p_node, 'link_opened');
      window.sb.rpc = realRpc; state.demo = realDemo;
    }
  })();

  const fails = R.filter(r => !r.ok);
  console.log(`\n${fails.length ? 'FAIL' : 'PASS'} — ${R.length} tests, ${fails.length} failure(s)`);
  return { total: R.length, failures: fails.map(f => f.name) };
})();
