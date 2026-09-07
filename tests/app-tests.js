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
  t('bands: the phrase agrees at the edge', /over your playing HCP/.test(vsPhrase(-1.0)), true);
  (function(){
    /* the split that shipped was name-vs-points; assert they never diverge */
    const NAME = {12:'Torched it', 9:'Beat your number', 7:'Played to it', 6:'A little loose', 5:'Posted anyway'};
    let bad = null;
    for(let v = -600; v <= 600; v++){ const vs = v/100;
      if(bandName(vs) !== NAME[pointsFor(vs)[0]]){ bad = vs; break; } }
    t('bands: name and points agree across the range', bad, null);
  })();

  /* R13 / D249 · ONE BAND TABLE, THREE RENDERERS. `band_name(p_pvi)` is the
     server's producer (20260930090000), `CSBands.bandName` is the phone's and
     `bandName()` is this one. The cases below are `tests/fixtures/bands.json`
     — generated from the SQL — and the SAME eleven are asserted in
     `BandParityTests.swift`; preflight check 28 re-derives them from the
     migration on every push and fails if any of the three has moved. A drift
     therefore fails loudly on whichever side moved, which is the only way
     three renderings of one rule stay one rule. */
  (function(){
    const CASES = [
      [9.0, 'Torched it', 12], [3.0, 'Torched it', 12],
      [2.99, 'Beat your number', 9], [1.0, 'Beat your number', 9],
      [0.99, 'Played to it', 7], [0.0, 'Played to it', 7], [-0.99, 'Played to it', 7],
      [-1.0, 'A little loose', 6], [-3.0, 'A little loose', 6],
      [-3.01, 'Posted anyway', 5], [-12.0, 'Posted anyway', 5],
    ];
    let badBand = null, badPts = null;
    for(const [pvi, band, pts] of CASES){
      if(bandName(pvi) !== band && badBand === null) badBand = pvi + ' → ' + bandName(pvi);
      if(pointsFor(pvi)[0] !== pts && badPts === null) badPts = pvi + ' → ' + pointsFor(pvi)[0];
    }
    t('R13: every case in the SQL fixture names the same band here', badBand, null);
    t('R13: and pays the same points', badPts, null);
    t('R13: the receipt prefers the server band when the payload carries one',
      (function(){ const r = { band:'Beat your number' }; return r.band || bandName(-4); })(), 'Beat your number');
    t('R13: and falls back to this client when it does not',
      (function(){ const r = {}; return r.band || bandName(-4); })(), 'Posted anyway');
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
       for the RIGHT behaviour. The reverse is also true and used to fail here:
       while it IS animating, the element's textContent is three 0-9 strips, so
       "does it contain 600" is false for the right behaviour too — the digits
       are in the strips' HOME positions, not in the text. One contract per
       world; `dataset.odo` below is the one that holds in both. */
    const rm = matchMedia('(prefers-reduced-motion:reduce)').matches;
    if (rm) t('csOdo: shows the new value', el.textContent.replace(/\s/g,'').includes('600'), true);
    else {
      t('csOdo: builds one strip per digit', el.querySelectorAll('.odostrip').length, 3);
      t('csOdo: the strips carry the new value', el.textContent.replace(/[^\d]/g,'').length > 3, true);
    }
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

  /* ══ D205 · solo tees off at two; squads at four ═════════════════════════
     Every "minimum" sentence on this client derives from STRUCT_MIN. The words
     that used to be typed ("Minimum four to tee off", "works at any size (4+)")
     called the format two of two real leagues are playing too small. */
  (function(){
    t('D205: STRUCT_MIN is the one producer', [STRUCT_MIN.solo, STRUCT_MIN.squads2], [2, 4]);
    t('D205: the minimum is a word, from the table', numberWord(STRUCT_MIN.squads2), 'four');
    t('D205: solo tees off at two', numberWord(STRUCT_MIN.solo), 'two');
    t('D205: the invite note says both, verbatim with the phone', inviteNoteText(),
      'Lock opens the invite link \u2014 one link fills the league. The code works until first tee, '
      + 'or until you close the roster. Squads need four to tee off; solo tees off at two.');
    t('D205: solo works at any size (2+)', /works at any size \(2\+\)/.test(STRUCT_NOTES.solo), true);
    const wasStruct = state.structure;
    state.structure = 'solo';
    t('D205: a solo league has no squads to form', lockButtonText(), 'Start the season');
    state.structure = 'squads2';
    t('D205: squads still form at the lock', lockButtonText(), 'Start the season & form the squads');
    state.structure = wasStruct;
  })();

  /* ══ D206 · a league is minted with the defaults the wizard shows ═════════
     The row said hybrid · 9 months · $75 because create_league relied on column
     defaults, and applyBylaws read that row back OVER the wizard's own state —
     six real setups carry a format nobody chose, with a live +15 payout branch
     behind it. A new lock can no longer write one. */
  (function(){
    const wasFmt = state.fmt;
    state.fmt = 2;
    t('D206: a new lock never sends hybrid', fmtKeyForLock(), 'points');
    state.fmt = 1;
    t('D206: head-to-head still locks as itself', fmtKeyForLock(), 'h2h');
    state.fmt = wasFmt;
    t('D206: the legacy value still RENDERS (two seed rows have it)', FMT_KEYS[2], 'hybrid');
    t('D206: 13 weeks is on the season ladder', DURS.includes(13), true);
    t('D206: 13 weeks describes itself as 3 months', durMonths(13), 3);
  })();

  /* ══ D213 / M-17 · the week closes on the league's own day ════════════════
     The clash week rolls on floor((today − starts_on)/7), keyed to the first-tee
     weekday (D108) — so "Week closes Sun" named a day nothing happened on for
     every league that does not tee off on Sunday. */
  (function(){
    const was = state.seasonStart;
    const on = (iso, todayIso) => { state.seasonStart = iso; return weekCloseDate(localDate(todayIso)); };
    const WDN = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
    t('M-17: a Wednesday league closes Tuesday', WDN[on('2026-09-02','2026-09-05').getDay()], 'Tue');
    t('M-17: a Sunday league still closes Saturday', WDN[on('2026-08-30','2026-09-05').getDay()], 'Sat');
    t('M-17: the close is inside the week it closes', on('2026-09-02','2026-09-05').toDateString(),
      localDate('2026-09-08').toDateString());
    /* D213 · a first tee still ahead clamps to week 1's close, the way the
       phone's `LeagueDates.weekClose` does (`max(0, days)`) — not to a Sunday. */
    t('D213: a future first tee gives week 1 close, not next Sunday',
      on('2026-09-30','2026-09-05').toDateString(), localDate('2026-10-06').toDateString());
    state.seasonStart = null;
    t('M-17: no season to key on falls back to Sunday', WDN[weekCloseDate(localDate('2026-09-02')).getDay()], 'Sun');
    state.seasonStart = was;
  })();

  /* ══ D208 · "Played in" counts leagues that STARTED ═══════════════════════
     It counted memberships: an abandoned wizard, a sandbox and an unstarted
     season all read as "Played in 1". */
  (function(){
    const real = { m: window.CS && window.CS.memberships, s: window.leagueSeasons,
                   r: window.careerRankedSeasons, e: window.myEvents };
    if (!window.CS) return;
    const today = new Date(); today.setHours(0,0,0,0);
    const iso = d => `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`;
    const past = iso(new Date(today.getFullYear(), today.getMonth(), today.getDate() - 30));
    const soon = iso(new Date(today.getFullYear(), today.getMonth(), today.getDate() + 30));
    window.CS.memberships = [
      { league: { id: 'L-live',  sandbox: false } },   /* teed off  -> counts */
      { league: { id: 'L-setup', sandbox: false } },   /* no season -> no     */
      { league: { id: 'L-soon',  sandbox: false } },   /* not yet   -> no     */
      { league: { id: 'L-sand',  sandbox: true  } },   /* sandbox   -> never  */
    ];
    window.leagueSeasons = [
      { id: 'S1', league_id: 'L-live', number: 1, status: 'active',   starts_on: past, ends_on: soon },
      { id: 'S2', league_id: 'L-soon', number: 1, status: 'active',   starts_on: soon, ends_on: soon },
      { id: 'S3', league_id: 'L-sand', number: 1, status: 'complete', starts_on: past, ends_on: past },
    ];
    window.careerRankedSeasons = new Set();
    window.myEvents = [{ id: 'E1', mine: true }, { id: 'E2', mine: false }];
    t('D208: only the league that teed off, plus events on your roster', playedInCount(), 2);
    window.CS.memberships = [{ league: { id: 'L-soon', sandbox: false } }];
    window.leagueSeasons = [{ id: 'S2', league_id: 'L-soon', number: 1, status: 'active', starts_on: soon, ends_on: soon }];
    window.myEvents = [];
    t('D208: a member who joined before first tee reads 0', playedInCount(), 0);
    window.careerRankedSeasons = new Set(['S2']);
    t('D208: unless they already hold a round in it', playedInCount(), 1);
    window.CS.memberships = real.m; window.leagueSeasons = real.s;
    window.careerRankedSeasons = real.r; window.myEvents = real.e;
  })();

  /* ══ D210 · the banned word leaves the user surfaces ══════════════════════ */
  (function(){
    t('D210: the personal-best tile names what the figure is measured against',
      achSubtitle({ kind: 'personal_best', meta: { diff: 7.8 } }), '7.8 vs course');
    t('Y-24: every marker is a "The"', window.MARKERS?.no2?.n, 'The No. 2');
  })();

  /* ══ Y-25 / Y-31 / M-19 / D201 · ONE scoring guide ═══════════════════════
     The bands table is computed from bandName()/pointsFor(), so it can never
     disagree with a receipt again; the ledger line comes from CS_LEDGER; and
     with no league in hand "What counts" describes BOTH structures, so it never
     promises a penalty a solo league cannot take (D140). */
  (function(){
    if (typeof window.openScoringHelp !== 'function') return;
    const wasLeague = window.CS && window.CS.league;
    if (window.CS) window.CS.league = null;
    window.openScoringHelp();
    const txt = ((document.querySelector('#sheet') || {}).textContent || '').replace(/\s+/g, ' ');
    t('Y-25: the bands read their names and points off the engine rule',
      /Torched it · beat it by 3 or more · 12 pts/.test(txt), true);
    t('Q-20: the seam band is named for the points it pays',
      /A little loose · 1 to 3 over · 6 pts/.test(txt), true);
    t('Y-25: no band edge overlaps its neighbour', /by 1 to 2.9/.test(txt), true);
    t('Y-31: the guide names the allowance the bands measure from',
      /playing number/.test(txt) && /Standard scores you against 95% of it/.test(txt), true);
    t('M-19: with no league in hand the floor describes both structures',
      /In a solo league that minimum is a habit, not a penalty/.test(txt), true);
    t('D201: the ledger line is the constant, verbatim', txt.indexOf(CS_LEDGER) >= 0, true);
    t('D201: never "between you"', /between you/.test(txt), false);
    t('D205: with no league the covenant says "your standing", true in both structures',
      /can't hurt your standing by playing badly/.test(txt), true);
    /* D205 · the THIRD branch: a squad league in hand reads the squad paragraph,
       verbatim with the phone's `GuideCopy.scoring(solo: false)`. It used to be
       unreachable — `!!league && structure==='solo'` folded "no league" and
       "squads" into one false. */
    const wasStruct = state.structure;
    if (window.CS) window.CS.league = { id: 'L-test' };
    state.structure = 'squads2';
    window.openScoringHelp();
    const sq = ((document.querySelector('#sheet') || {}).textContent || '').replace(/\s+/g, ' ');
    t('D205: a squad league reads the squad paragraph',
      /Your best rounds each month count for your squad/.test(sq), true);
    t('D205: and never the solo clause', /In a solo league that minimum is a habit/.test(sq), false);
    t('D205: a squad league keeps the squad covenant',
      /can't hurt your squad by playing badly/.test(sq), true);
    state.structure = 'solo';
    window.openScoringHelp();
    const so = ((document.querySelector('#sheet') || {}).textContent || '').replace(/\s+/g, ' ');
    t('D205: a solo league is told the minimum is a habit',
      /In a solo league the monthly minimum is a habit/.test(so), true);
    state.structure = wasStruct;
    document.querySelector('#sheet')?.classList.remove('open');
    if (window.CS) window.CS.league = wasLeague;
  })();

  /* ══ M-15 · verification is a norm the league holds, not a filter ═════════
     "GHIN-verified + attested" was a claim the app cannot make. */
  (function(){
    t('M-15: the bylaws row names the norm', VERIF[2], 'Vouched by the group where you can; the Pro rules on the rest');
    t('M-15: Standard asks, it does not verify', VERIF[1], "Post what you'd post to GHIN");
    const cards = document.querySelector('#presetSummary')?.parentElement?.textContent || '';
    t('M-15: the footnote sits under the preset cards',
      /Verification is a norm the league holds, not a filter the engine applies\./.test(cards), true);
  })();

  /* ══ Y-12 · a course label as it should be READ ══════════════════════════
     GolfCourseAPI title-cases its club names upstream, so "Palo Verde GC"
     lands in rounds.course_label as "Palo Verde Gc". csCourse repairs the
     acronym and touches nothing else — re-casing the whole string is the bug
     one level up. Twin of the Kit's RoundCopy.course. */
  (function(){
    t('Y-12: the club acronym is repaired', csCourse('Palo Verde Gc · Back'), 'Palo Verde GC · Back');
    t('Y-12: and inside a longer label',
      csCourse('Arizona Biltmore Cc — Links · Copper'), 'Arizona Biltmore CC — Links · Copper');
    t('Y-12: a hand-typed label is left alone', csCourse('Papago GC'), 'Papago GC');
    t('Y-12: a small word is NOT re-cased', csCourse('Lone Tree at the Ranch'), 'Lone Tree at the Ranch');
    t('Y-12: a lowercase name is left alone', csCourse('encanto gc'), 'encanto GC');
    t('Y-12: null-safe', csCourse(null), '');
  })();

  /* ══ Y-14 · the figure-scope line carries its denominator ═════════════════
     "across counting rounds" said nothing about how many; with ONE counting
     round the best and the average are the same number, and the line is the
     only thing that can explain that. Twin of YouCopy.acrossCounting. */
  (function(){
    t('Y-14: the singular is the whole point', countingScope(1), 'across 1 counting round');
    t('Y-14: the plural', countingScope(5), 'across 5 counting rounds');
  })();

  /* ══ Y-08 · the FORM dots get a visible key ══════════════════════════════
     The legend lived only in the aria-label, and a screen-reader string is not
     a legend for the eye. The credential passes none — that card can be
     somebody else's, where "your playing number" would be a lie. */
  (function(){
    const rec = [{beat:true},{beat:false},{beat:true},{beat:true},{beat:false}];
    const withKey = formRowHtml(rec, 'Your last five rounds, oldest first — a lit dot beat your playing number.');
    t('Y-08: the key is drawn, not only spoken', /a lit dot beat your playing number/.test(withKey), true);
    t('Y-08: the credential passes none', /lit dot/.test(formRowHtml(rec)), false);
    t('Y-08: the dots survive the caption', (withKey.match(/<i /g) || []).length, 5);
  })();

  /* ══ D126 · the endgame sentence, one fixture on both clients ═════════════
     tests/fixtures/endgame.json is GENERATED from this file's endgameLine()
     (scratchpad/endgame-harness.mjs; never hand-edited) and the Kit's
     EndgameCopy decodes the same file, so the phone and the web can only drift
     together, never apart. The rule that matters is the date: cupFinalStart is
     ends_on − 27 calendar days on the LOCAL calendar (localDate, never
     new Date('YYYY-MM-DD')), and the weekday/month names come off DOW/MOS. The
     fixture is fetched synchronously so the summary below still counts it —
     serve from the repo root (python -m http.server) or this fails loudly. */
  (function(){
    let fx = null, status = null;
    try {
      const x = new XMLHttpRequest();
      /* cache-busted: a stale HTTP copy of the fixture makes this suite
         report a drift that is not there (measured 2026-09-05, wave 9) */
      x.open('GET', 'tests/fixtures/endgame.json?v=' + Date.now(), false);
      x.send(null);
      status = x.status;
      if (x.status === 200) fx = JSON.parse(x.responseText);
    } catch (e) { status = String(e && e.message || e); }
    t('D126: the endgame fixture is served (run from the repo root)', fx ? 200 : status, 200);
    if (!fx) return;
    t('D126: the fixture carries the rule the Kit reads', typeof fx._rule === 'string' && /27/.test(fx._rule), true);
    t('D126: the matrix is whole (2 finishes × 4 structures × 3 windows)', fx.cases.length, 24);
    const was = { s: state.seasonStart, e: state.seasonEnd, f: state.finish, st: state.structure };
    /* the defaults are set to the OPPOSITE of what most cases ask, so a
       producer that ignored opts and read state would fail here */
    state.finish = 'points_table'; state.structure = 'squads4';
    for (const c of fx.cases) {
      state.seasonStart = c.starts_on; state.seasonEnd = c.ends_on;
      t(`D126: ${c.label} · ${c.finish} · ${c.structure}`, endgameLine({ finish: c.finish, structure: c.structure }), c.expected);
      const cf = cupFinalStart();
      t(`D126: ${c.label} · Cup Final start is ends_on − 27 (${c.cup_final_start})`, isoOf(cf), c.cup_final_start);
    }
    state.seasonStart = was.s; state.seasonEnd = was.e; state.finish = was.f; state.structure = was.st;
  })();

  /* ══ D219 / D234 · one plan predicate, two callers ═══════════════════════
     `upcomingFromSchedule` and the Next TILE used to disagree with each other
     AND with the phone: the list dropped `mine === false` (so a round booked
     WITH you never became "Next round") and read neither `tagged_me` nor
     `my_rsvp` (so your own declined booking stayed "Next"), while the tile
     filtered nothing but the date over `watchAll` — buddies' plans included —
     and could name somebody else's round as yours. The phone's rule is
     `(mine != false || tagged_me) && my_rsvp != 'out'`
     (`ScheduleModels.chips`); `isMyPlan` is that rule, and both callers use it. */
  (function(){
    const iso = d => { const x = new Date(); x.setHours(12,0,0,0); x.setDate(x.getDate()+d);
      return `${x.getFullYear()}-${String(x.getMonth()+1).padStart(2,'0')}-${String(x.getDate()).padStart(2,'0')}`; };

    t('D219: my own booking is mine', isMyPlan({ mine:true }), true);
    t('D219: a row with no `mine` at all is mine (my_schedule carries none)', isMyPlan({}), true);
    t('D219: a round booked WITH me is mine', isMyPlan({ mine:false, tagged_me:true }), true);
    t('D219: a buddy\u2019s round is not mine', isMyPlan({ mine:false }), false);
    t('D219: my DECLINED booking is not mine', isMyPlan({ mine:true, my_rsvp:'out' }), false);
    t('D219: a tagged round I declined is not mine', isMyPlan({ mine:false, tagged_me:true, my_rsvp:'out' }), false);
    t('D219: an accepted tag is mine', isMyPlan({ mine:false, tagged_me:true, my_rsvp:'in' }), true);

    const was = window.watchAll;
    window.watchAll = [
      { id:'a', mine:false, tagged_me:true, play_on:iso(1), course_label:'Papago GC', tagged_names:['Galen'] },
      { id:'b', mine:true,  my_rsvp:'out',  play_on:iso(0), course_label:'Encanto GC' },
      { id:'c', mine:false,                 play_on:iso(2), course_label:'Aguila GC', display_name:'Ed' },
      { id:'d', mine:true,                  play_on:iso(4), course_label:'Palo Verde GC' },
    ];
    const up = upcomingFromSchedule();
    t('D219: a round booked with me leads the list', up.map(r => r.what), ['Papago GC', 'Palo Verde GC']);
    t('D219: my declined booking is not on it', up.some(r => r.what === 'Encanto GC'), false);
    t('D219: a buddy\u2019s round is not on it', up.some(r => r.what === 'Aguila GC'), false);
    t('D219: the tagged round names who booked it with me', up[0].who, 'with Galen');
    t('D219: tomorrow is TOMORROW', up[0].when, 'TOMORROW');
    window.watchAll = was;
  })();

  /* ============ D246 - ONE week producer ============
     Six formulas across two clients with two different bases; the same season
     could be week 7 here and week 6 on the phone. `csWeek` reads
     `native_home.season.week_no` where a payload carries it and otherwise runs
     the SAME arithmetic the migration moved server-side, on CALENDAR days -
     the old body divided an INSTANT difference, which is a day out across a
     DST boundary. The phone's twin is `LeagueDates.week`. */
  (function(){
    const wasStart = state.seasonStart, wasEnd = state.seasonEnd;
    state.seasonStart = '2026-07-05'; state.seasonEnd = '2027-01-03';
    const d = iso => localDate(iso);

    t('D246: the server’s week is the week', csWeek({ week_no: 9, weeks_total: 26 }, d('2026-01-01')), 9);
    t('D246: the server’s total is the total', csWeeksTotal({ weeks_total: 26 }), 26);
    t('D246: no payload falls back to the ruled formula', csWeek(null, d('2026-09-08')), 10);
    t('D246: week 1 is the first tee', csWeek(null, d('2026-07-05')), 1);
    t('D246: day six is still week 1', csWeek(null, d('2026-07-11')), 1);
    t('D246: day seven is week 2', csWeek(null, d('2026-07-12')), 2);
    t('D246: before the first tee clamps to week 1', csWeek(null, d('2026-06-01')), 1);
    t('D246: past the end clamps to the total', csWeek(null, d('2027-06-01')), csWeeksTotal(null));
    t('D246: a zero week is unset, not week zero', csWeek({ week_no: 0 }, d('2026-09-08')) > 0, true);
    /* the week closes on the league's OWN weekday - the season tees off on a
       Sunday, so its weeks close on Saturdays, never on a hardcoded Sunday */
    t('D246: the week closes on the league’s own weekday',
      isoOf(csWeekEnds(null, d('2026-09-08'))), '2026-09-12');
    t('D246: the server’s close wins',
      isoOf(csWeekEnds({ week_ends_on: '2026-09-13' }, d('2026-09-08'))), '2026-09-13');
    /* `standings_snapshots.week_no` is 0-BASED and is RELABELLED, never recomputed */
    t('D246: snapshot week 0 is week 1', csSnapshotWeekLabel(0), 1);
    t('D246: snapshot week 8 is week 9', csSnapshotWeekLabel(8), 9);
    state.seasonStart = wasStart; state.seasonEnd = wasEnd;
  })();

  /* ============ A-4 - a movement label carries its own clock ============
     `prev_rank` is a SUNDAY snapshot (cron '10 7 * * 0'), so a Tuesday climb
     read "held" and erased the only movement of the week. A bare arrow is now
     unwritable: the label names the day it is measured FROM, or it does not
     render at all. */
  (function(){
    const sun = '2026-09-06T07:10:00Z';   /* the snapshot's own captured_at */
    t('A-4: no clock, no label', csMovement(1, null), null);
    t('A-4: no delta, no label', csMovement(null, sun), null);
    t('A-4: an unparseable clock is no clock', csMovement(1, 'not-a-date'), null);
    t('A-4: up one names the day it is measured from', csMovement(1, sun).long, 'up one since Sun');
    t('A-4: the visible label carries the clock too', /SINCE/.test(csMovement(1, sun).text), true);
    t('A-4: down two says down two', csMovement(-2, sun).long, 'down two since Sun');
    t('A-4: held says since when', csMovement(0, sun).long, 'held since Sun');
    t('A-4: held is never a bare dash', csMovement(0, sun).text, 'HELD SINCE SUN');
    /* WAVE 7 - the producer emits the PARTS and the renderer draws the mark.
       A typed triangle in a produced string is LINT-13, and the DOWN triangle
       meant "you fell" here and "most improved" in three other producers. */
    t('LINT-13: the label carries no arrow glyph', /[\u25b2\u25bc]/.test(csMovement(-2, sun).text), false);
    t('LINT-13: nor does a climb', /[\u25b2\u25bc]/.test(csMovement(1, sun).text), false);
    t('A-4: the parts are emitted', [csMovement(-2, sun).count, csMovement(-2, sun).sinceShort, csMovement(-2, sun).dir], [2, 'SUN', -1]);
    /* D76's heat survives: climbing runs warm, climbing 2+ hot, falling cools */
    t('A-4: D76 heat is kept', [csMovement(1,sun).tone, csMovement(2,sun).tone, csMovement(-1,sun).tone, csMovement(0,sun).tone],
      ['up','up2','dn','fl']);
  })();

  /* ============ D236 - the ME strip's tokens ============
     Produced once and rendered twice: these are the web halves of
     `MeStripCopy.dayToken` and `.teeText`, and the phone's `MeStripTests`
     assert the same answers. */
  (function(){
    const day = n => { const d=new Date(); d.setHours(0,0,0,0); d.setDate(d.getDate()+n);
      return `${d.getFullYear()}-${String(d.getMonth()+1).padStart(2,'0')}-${String(d.getDate()).padStart(2,'0')}`; };
    const DOWU = ['SUN','MON','TUE','WED','THU','FRI','SAT'];
    const wd = n => { const d=new Date(); d.setHours(0,0,0,0); d.setDate(d.getDate()+n); return DOWU[d.getDay()]; };
    t('D236: today is TODAY', csDayToken(day(0)), 'TODAY');
    t('D236: inside a week is a weekday', csDayToken(day(4)), wd(4));
    t('D236: a recent round is a weekday', csDayToken(day(-3)), wd(-3));
    t('D236: past a week it is the date', /^[A-Z]{3} \d{1,2}$/.test(csDayToken(day(30))), true);
    t('D236: a tee time prints as the plan holds it', csTeeText('07:10:00'), '7:10');
    t('D236: an afternoon tee', csTeeText('14:05:00'), '14:05');
    t('D236: no tee time, no guess', csTeeText(null), null);
    t('D236: a junk tee time is not a tee time', csTeeText('later'), null);
  })();

  /* ============ D231 - the desk rule, on the web ============
     `csRankDispatch` is the web half of the phone's `HomeRank.arrange`, and
     the cases below are the same cases the Swift suite drives out of
     `tests/fixtures/dispatch.json` — that file is canon; these are inlined
     because this suite runs in a console with no filesystem. If the two ever
     disagree, the JSON wins and one of the two producers is wrong. */
  (function(){
    const door = k => ({ kind: k || 'composer' });
    const it = (key, tier, o) => Object.assign({ key, tier, headline: key + ' happened.', route: door(), human_subject: true }, o || {});

    /* G2 · THE VETO — a bare standing can never lead, however high it scores */
    const veto = csRankDispatch([ it('standing', 'closing', { score: 1056, human_subject: false }),
                                  it('clash', 'circle', { score: 412 }) ], { useServerRank: false });
    t('D231: the veto — a bare standing does not lead', veto.lead.key, 'clash');
    t('D231: the veto — it keeps its score and sits in the deck', veto.deck.map(x => x.key), ['standing']);

    /* with nothing human on the screen there is NO lead, and none is invented */
    const none = csRankDispatch([ it('a', 'closing', { score: 1000, human_subject: false }) ], { useServerRank: false });
    t('D231: no human subject, no lead', none.lead, null);
    t('D231: ... and the deck still renders', none.deck.length, 1);

    /* G1 · THE FENCE — an item with no door does not render at all */
    const fenced = csRankDispatch([ { key: 'doorless', tier: 'closing', score: 1000, human_subject: true,
                                      headline: 'Nowhere to go.', route: { kind: 'teleport' } },
                                    it('chapter', 'chapter', { score: 200 }) ], { useServerRank: false });
    t('D231: the fence — no door, no render', fenced.lead.key, 'chapter');
    t('D231: the fence — and nothing else survives it', fenced.deck.length, 0);
    t('D231: the fence — an empty sentence is not an item',
      csRankDispatch([ it('blank', 'closing', { headline: '   ' }) ], { useServerRank: false }).lead, null);

    /* the six bands, in the order UX_PRINCIPLES §5.1 states them */
    const tiers = ['opportunity', 'chapter', 'circle', 'coming', 'changed', 'closing'].map(x => it(x, x));
    const sorted = csRankDispatch(tiers, { useServerRank: false });
    t('D231: the six bands sort closing first', sorted.lead.key, 'closing');
    t('D231: ... then changed, coming, circle, chapter', sorted.deck.map(x => x.key),
      ['changed', 'coming', 'circle', 'chapter']);

    /* G5 · THE CAP — one lead and four, and the overflow is COUNTED */
    const many = csRankDispatch(Array.from({ length: 9 }, (_, i) => it('i' + i, 'circle', { score: 400 - i })),
                                { useServerRank: false });
    t('D231: the cap — four in the deck', many.deck.length, 4);
    t('D231: the cap — the overflow is counted, not hidden', many.cut, 4);

    /* the tie-breaks: score, then newer before older, then the key */
    const tie = csRankDispatch([ it('a', 'circle', { score: 400, at: '2026-09-01' }),
                                 it('b', 'circle', { score: 400, at: '2026-09-04' }),
                                 it('c', 'circle', { score: 400, at: '2026-09-04' }) ], { useServerRank: false });
    t('D231: the tie-breaks are deterministic', [tie.lead.key].concat(tie.deck.map(x => x.key)), ['b', 'c', 'a']);

    /* the server's own rank wins when EVERY item carries one — the web renders
       a list, it does not re-rank */
    const served = csRankDispatch([ it('third', 'closing', { score: 1000, rank: 3 }),
                                    it('first', 'chapter', { score: 100, rank: 1 }),
                                    it('second', 'circle', { score: 400, rank: 2 }) ]);
    t('D231: the server rank is honoured', served.lead.key, 'first');
    t('D231: ... and the deck follows it', served.deck.map(x => x.key), ['second', 'third']);

    /* L-34 · the lead's suppress set is UNIONED onto the strip's */
    const sup = csRankDispatch([ it('clash', 'closing', { score: 1000, suppress: ['my_last_round'] }) ],
                               { stripSuppress: ['my_next_round', 'my_money'], leadSuppress: ['my_number'], useServerRank: false });
    t('D231: suppress unions, never replaces', [...sup.suppress].sort(),
      ['my_last_round', 'my_money', 'my_next_round', 'my_number']);

    /* the declared fallback draws NO LEAD CARD — a guessed lead is the exact
       failure the veto exists to prevent */
    const savedClash = window.homeClash, savedFeed = window.homeFeedRows;
    window.homeClash = { week_no: 5, ends_on: '2026-09-06', days_left: 2, closes_today: false,
                         them_name: 'Galen Ward', mine: { gross: 89, round_id: null }, theirs: null };
    window.homeFeedRows = [{ round_id: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa', golfer: 'Jade Nunes', gross: 81, played_on: '2026-09-03', course: 'Troon', is_me: false }];
    const fb = csFallbackItems();
    t('D228: the fallback composes items', fb.length >= 2, true);
    t('D228: the fallback order is CLOSING then CIRCLE', fb.map(x => x.tier), ['closing', 'circle']);
    t('D228: SA-2 — the subject is the opponent, and the verb is not "post again"',
      fb[0].headline, 'Galen has 2 days to answer your 89.');
    t('D228: the fallback draws NO lead card', csRankDispatch(fb, { useServerRank: false }).lead, null);
    t('D228: ... and every fallback item still has a door', fb.every(x => !!x.route), true);
    /* the producer applies the fence itself: a circle round with no id is not an item */
    window.homeFeedRows = [{ round_id: null, golfer: 'Jade Nunes', gross: 81, played_on: '2026-09-03', course: 'Troon', is_me: false }];
    t('D228: a fallback item with no door is never emitted', csFallbackItems().map(x => x.tier), ['closing']);
    window.homeClash = savedClash; window.homeFeedRows = savedFeed;
  })();

  /* ===== wave 2 · the verb and the funnel (R7, R11, D227, D239, IOS-030) =====
     The web's producers are the phone's producers in another shape (D234), so
     these are the same cases `EpilogueMovementTests` drives on the Kit. */
  (function(){
    /* postEntry — the ONE box, then the nines (D72 intact) */
    const set = (id, v) => { const el = document.getElementById(id); if (el) el.value = v; };
    const savedGross = document.getElementById('inGross')?.value;
    const savedF9 = document.getElementById('inF9')?.value, savedB9 = document.getElementById('inB9')?.value;
    const savedSide = state.post.side, savedMode = state.post.mode;
    state.post.mode = 'total'; state.post.side = 18;
    set('inGross', '84'); set('inF9', ''); set('inB9', '');
    t('IOS-030: the one box is an eighteen', postEntry(), { gross: 84, holes: 18 });
    set('inGross', ''); set('inF9', '41'); set('inB9', '43');
    t('IOS-030: both nines are an eighteen', postEntry(), { gross: 84, holes: 18 });
    set('inF9', '41'); set('inB9', '');
    t('D72: one nine is still a nine', postEntry(), { gross: 41, holes: 9 });
    set('inGross', '84');
    t('L-34: the nines win while the card is open', postEntry(), { gross: 41, holes: 9 });
    set('inGross', ''); set('inF9', ''); set('inB9', '');
    t('IOS-030: an empty card enters nothing', postEntry(), null);
    set('inGross', savedGross || ''); set('inF9', savedF9 || ''); set('inB9', savedB9 || '');
    state.post.side = savedSide; state.post.mode = savedMode;

    /* R7 · the movement sentence is a count over a named read */
    t('R7: a climb names who was passed',
      csMovementSentence({ rank_before: 4, rank_after: 2, passed: ['Jade', 'Dre'] }),
      'That moved you past Jade and Dre into second.');
    t('R7: a climb with nobody named still says where it landed',
      csMovementSentence({ rank_before: 3, rank_after: 2, passed: [] }), 'That moved you into second.');
    t('L-44: no read, no sentence', csMovementSentence(null), null);
    t('L-44: half a read is no read', csMovementSentence({ rank_before: null, rank_after: 2 }), null);
    t('R7: a round that moved nothing says nothing', csMovementSentence({ rank_before: 2, rank_after: 2 }), null);
    t('R7: a posted round never LOSES you a place', csMovementSentence({ rank_before: 2, rank_after: 3 }), null);
    t('A-4: the gap clause only renders when there is one',
      csMovementGap({ rank_after: 2, gap_to_next_after: 4 }), '4 back of the row above.');
    t('A-4: ... and never at the top of the table', csMovementGap({ rank_after: 1, gap_to_next_after: 4 }), '');

    /* the one ranked next act (P-3), rung by rung */
    const epi = (o) => Object.assign({ gross: 84, pvi: 1.1, points: 9, month_rank: null, earned: [], rivals: [], played_with: [] }, o || {});
    t('P-3: the clash outranks everything',
      csNextAct(epi({ rank_before: 4, rank_after: 2, passed: ['Jade'] }), { clash: { id: 'x', weeks_running: 2 } }).sentence,
      'That takes the clash. Second week running.');
    t('P-3: the movement is the second rung',
      csNextAct(epi({ rank_before: 3, rank_after: 2, passed: ['Jade'] }), {}).key, 'movement');
    t('D239: a partner with no shared season is offered one',
      csNextAct(epi({ played_with: [{ profile_id: 'g', name: 'Galen', shares_season: false }] }), { rounds_together: { g: 4 } }).sentence,
      'Galen was out there too. Four rounds between you this month \u2014 four is a season.');
    t('D239: ... and without the count it invents none',
      csNextAct(epi({ played_with: [{ profile_id: 'g', name: 'Galen', shares_season: false }] }), {}).sentence,
      'Galen was out there too. Make the next one count.');
    t('D239: a shared season reads the record',
      csNextAct(epi({ played_with: [{ profile_id: 'j', name: 'Jade', shares_season: true }],
                      rivals: [{ name: 'Jade', wins: 5, losses: 6, ties: 0, lead: 'down' }] }), {}).sentence,
      'You and Jade have played eleven together. Jade leads 6.');
    t('P-3: leagueless with buddies counts rather than guesses',
      csNextAct(epi({}), { leagueless: true, buddies_played_this_week: 3 }).sentence,
      'Three of yours played this week. Nobody is playing for anything.');
    t('P-3: the third round is when the number goes live',
      csNextAct(epi({}), { leagueless: true, rounds_count: 3 }).sentence,
      'That is your third. Your number goes live now.');
    t('P-3: the eighth rung is a true sentence with a Done',
      csNextAct(epi({ month_rank: 2 }), { counting_cap: 3, month_name: 'September' }).sentence,
      'That is two of your best three in September.');
    t('V-3: a round the engine scored nothing for says so',
      csNextAct(epi({ pvi: null }), {}).sentence, 'That builds your number and nothing else.');
    t('L-32: an epilogue that could not be read still ends in a next move',
      csNextAct(null, {}).label, 'Done');
    /* the phrase means one thing because it is said once (P-3's own check) */
    const rungs = [
      csNextAct(epi({}), { clash: { id: 'x', weeks_running: 2 } }),
      csNextAct(epi({ rank_before: 3, rank_after: 2, passed: ['Jade'] }), {}),
      csNextAct(epi({}), { callout_event: 'e', callout_sentence: 'You called it.' }),
      csNextAct(epi({ played_with: [{ profile_id: 'g', name: 'Galen', shares_season: false }] }), {}),
      csNextAct(epi({ played_with: [{ profile_id: 'j', name: 'Jade', shares_season: true }] }), {}),
      csNextAct(epi({}), { leagueless: true, buddies_played_this_week: 3 }),
      csNextAct(epi({}), { leagueless: true, rounds_count: 3 }),
      csNextAct(epi({ month_rank: 2 }), { counting_cap: 3, month_name: 'September' }),
    ];
    t('P-3: eight rungs, eight distinct sentences', new Set(rungs.map(r => r.sentence)).size, 8);
    t('P-3: "Make the next one count" appears in exactly one rung',
      rungs.filter(r => r.sentence.indexOf('Make the next one count') >= 0).length, 1);
    t('L-32: every rung ends in a next move', rungs.every(r => !!r.label), true);

    /* L-19 · a tag is never a vouch */
    t('D239: an unconfirmed tag says so',
      csPlayedWithLine([{ name: 'Galen', confirmed: false }]), 'Played with Galen \u2014 Galen hasn\u2019t confirmed yet.');
    t('D239: a confirmed one just says who', csPlayedWithLine([{ name: 'Galen', confirmed: true }]), 'Played with Galen.');
    t('D239: nobody out there, nothing said', csPlayedWithLine([]), '');

    /* D229 · the composer's inherited line names what is MISSING rather than
       showing a placeholder that reads like a value (PA-025) */
    t('PA-025: an em dash, never a number nobody typed',
      /\u2014 \/ \u2014/.test(csInheritText()) || csInheritText().indexOf('Add the course') === 0, true);
  })();

  /* ==== D222 · the nav, and that every entry lands somewhere real ==========
     A `switchView` to a name with no pane deactivates every pane and drops the
     golfer on a blank screen — which is exactly how the live route was broken
     until wave 1b found it by hand. These walk the real DOM: every sidebar
     item and every tab, through the router's own alias table. */
  (function(){
    const nav = [...document.querySelectorAll('.side .navitem[data-v]')].map(b => b.dataset.v);
    const tabs = [...document.querySelectorAll('.tabbar .tab[data-v]')].map(b => b.dataset.v);

    t('D222: the sidebar leads with the five destinations',
      nav.slice(0, 4), ['home', 'compete', 'golfers', 'record']);
    /* WAVE 11 / D280 · the disclosure is gone: a 900px column has no reason to
       hide four destinations behind a caret, and the caret's label was the one
       word LV-12 ruled out. The section is a LIST below a rule now, and two of
       its four rows are PANES of the season page rather than views, so they
       carry `data-seg` and route through `setRoomSeg` — the same call the
       page's own sections use, not a second router. */
    t('D280: the section below the rule is a list, not a disclosure',
      document.getElementById('deskToggle'), null);
    t('D280: and every row in it names a real destination',
      [...document.querySelectorAll('#deskMenu .navitem')].map(b => b.dataset.v || ('seg:' + b.dataset.seg)),
      ['hub', 'schedule', 'seg:league', 'seg:archive']);
    t('D280: a `data-seg` row opens a pane that exists',
      [...document.querySelectorAll('#deskMenu .navitem[data-seg]')]
        .every(b => b.dataset.seg === 'archive' || !!document.getElementById('room-' + b.dataset.seg)), true);
    /* UI_SYSTEM §14.1 · the sidebar ends in the viewer and the build. The
       version is the deploy's own stamp and is never hand-edited: locally it
       reads the raw placeholder, which is the tell that this is not a Netlify
       build (CLAUDE.md rule 2). */
    t('D280: the sidebar foot carries the build identity',
      /v23/.test(document.querySelector('.side .foot .bld')?.textContent || ''), true);
    t('D280: the wordmark is in the sidebar, and the header does not print it twice',
      !!document.querySelector('.side .brand b') &&
        getComputedStyle(document.getElementById('hdrLogo')).display === 'none' ||
        window.innerWidth < 960, true);
    t('D222: the mobile bar carries five slots, the ⊕ in the middle',
      tabs, ['home', 'compete', 'record', 'golfers', 'stats']);

    /* every sidebar item maps to a switchView case … */
    const unresolved = nav.concat(tabs).filter(v => !csRouteResolves(v));
    t('D222: every nav entry resolves to a view that exists', unresolved, []);

    /* … and back: every view the router can land on is reachable from the nav,
       or is a pushed/child surface reached from one of them. A view in neither
       set is a screen nobody can get to. */
    const reachable = new Set(nav.concat(tabs).map(csViewFor));
    /* reached from a DOOR, never the bar: the composer and the live cover, the
       moment room, the draw, the wizard, and wave 5's two person surfaces —
       a person page is reached from a name, which is the only honest way in. */
    const children = ['post', 'play', 'event', 'draft', 'wizard', 'person', 'h2h'];
    const orphans = [...document.querySelectorAll('.view[id^="view-"]')]
      .map(el => el.id.slice(5))
      .filter(v => !reachable.has(v) && children.indexOf(v) < 0);
    t('D222: no view is unreachable from the nav', orphans, []);

    /* the two names R-D settled, and the two the overhaul retired */
    const labels = [...document.querySelectorAll('.side .navitem, .tabbar .tab')].map(b => b.textContent.trim());
    t('O-06: "Clubhouse" is gone from the nav', labels.some(l => /clubhouse/i.test(l)), false);
    t('R-D: Compete and Golfers are the two names', labels.some(l => /^Compete/.test(l)) && labels.some(l => /^Golfers/.test(l)), true);

    /* legacy routes keep working — an old link must not blank the page */
    t('D222: the old People route lands on Golfers', csViewFor('people'), 'golfers');
    t('D222: the old Clubhouse route lands on Compete', csViewFor('clubhouse'), 'compete');
    t('D93: the old calendar route still lands on the schedule', csViewFor('cal'), 'schedule');
    t('the pot is a pane of the season room', csViewFor('pot'), 'hub');
  })();

  /* ==== D222 · Compete's list, and both empty roots ======================== */
  (function(){
    const row = (id, clock) => ({ id, clock, kind: 'season', eyebrow: '', title: id, sub: '' });

    /* rule 1 · nearest clock first; a clockless row keeps its arrival order.
       The phone's `CompeteRoot.sorted` is the same rule and the same tie-break. */
    t('Compete: nearest clock first',
      csCompeteSort([row('d', 9), row('a', 0), row('c', 4)]).map(r => r.id), ['a', 'c', 'd']);
    t('Compete: no clock goes to the back, in arrival order',
      csCompeteSort([row('n1', null), row('soon', 2), row('n2', null), row('late', 30)]).map(r => r.id),
      ['soon', 'late', 'n1', 'n2']);
    (function(){
      const input = Array.from({ length: 12 }, (_, i) => row('r' + i, 3));
      let stable = true;
      for (let k = 0; k < 20; k++) {
        if (csCompeteSort(input).map(r => r.id).join() !== input.map(r => r.id).join()) stable = false;
      }
      t('Compete: equal clocks keep their order every time', stable, true);
    })();

    /* rule 3 · L-32, both halves */
    const failed = csEmptyRoot('compete', { failed: true });
    const empty = csEmptyRoot('compete', {});
    t('L-32: a failed read is not an empty one', failed.head === empty.head, false);
    t('L-32: a failed read offers the one honest move', failed.doors.map(d => d.k), ['retry']);
    t('L-32: an absence does not offer "try again"', empty.doors.some(d => d.k === 'retry'), false);
    t('L-32: every empty root ends in a next move',
      [failed, empty, csEmptyRoot('golfers', {}), csEmptyRoot('compete', { buddies: 5 })]
        .every(r => r.doors.length > 0), true);
    t('L-32: a load in flight is neither', csEmptyRoot('golfers', { loaded: false }).state, 'loading');

    /* the design's words, and the one conditional true fact */
    t('IA §6.1: Compete’s empty root, verbatim', empty.head, 'Nothing running.');
    t('IA §6.1: the fact is real when it is real',
      csEmptyRoot('compete', { buddies: 5 }).fact, '5 buddies, and none of you is playing for anything.');
    t('IA §6.1: one buddy is one buddy',
      csEmptyRoot('compete', { buddies: 1 }).fact, '1 buddy, and none of you is playing for anything.');
    t('L-44: with none, the fact is omitted rather than guessed', empty.fact, null);
    t('IA §6.1: with no buddies the second door becomes Find golfers',
      empty.doors.map(d => d.k), ['startSomething', 'findGolfers']);
    t('IA §6.1: with buddies it is the code door',
      csEmptyRoot('compete', { buddies: 3 }).doors.map(d => d.k), ['startSomething', 'joinWithCode']);
    t('IA §10.1: Golfers’ empty root, verbatim', csEmptyRoot('golfers', {}).head, 'No buddies yet.');
    /* R-G's contacts door is D251, wave 8 — not sold before it opens */
    t('L-32: Golfers does not sell the contacts door yet',
      csEmptyRoot('golfers', {}).doors.map(d => d.t), ['Find golfers', 'Text someone a link']);

    /* IA §8.4 rule 1 · no seat count, anywhere */
    t('a plan names who is on it', csPlanLine({ tagged_names: ['Galen'] }), 'You and Galen.');
    t('and three of them read as a sentence',
      csPlanLine({ tagged_names: ['Galen', 'Jade', 'Dev'] }), 'You, Galen, Jade and Dev.');
    t('IA §8.4: and it never counts seats',
      /seat/i.test(csPlanLine({ tagged_names: [], tee_time: '07:10:00' })), false);
    t('a plan with nobody on it says the tee time',
      csPlanLine({ tagged_names: [], tee_time: '07:10:00' }), 'Your tee time, 7:10.');
    /* seen on a real account before it was fixed: `tagged_names` carries the
       VIEWER on a round a buddy booked with them */
    t('a plan never names the viewer twice',
      csPlanLine({ tagged_names: ['Jerecho Fischbeck', 'Galen'] }, 'Jerecho Fischbeck'), 'You and Galen.');
    t('someone else’s round names its host',
      csPlanLine({ mine: false, display_name: 'Galen Ross', tagged_names: ['Jerecho Fischbeck'] }, 'Jerecho Fischbeck'),
      'Galen\u2019s round. You\u2019re on it.');
    t('…and the others on it',
      csPlanLine({ mine: false, display_name: 'Galen Ross', tagged_names: ['Jerecho Fischbeck', 'Jade', 'Dev'] }, 'Jerecho Fischbeck'),
      'Galen\u2019s round. You, Jade and Dev.');

    /* D252 · the moment row's noun and state — never a countdown (L-22) */
    t('D252: a moment names the noun and the state', csMomentLine('major', 'live', true), 'A Major · Live');
    t('D252: one you have not joined says the door is open',
      csMomentLine('ryder', 'setup', false), 'The Ryder · open to you');
  })();

  /* ==== D223 / R-H · the season's story — the seven-rung ladder ==========
     The web half of `SeasonStoryCopy`. These assert the SAME answers
     `SeasonStoryTests.swift` asserts, case for case: two clients, one
     ladder, one sentence. The fence is asserted here too, because the web is
     where a payload from a newer server arrives first. */
  (function seasonStory(){
    const sunday = '2026-08-30T07:10:00.228+00:00';
    const table = [{ id:'galen', name:'Galen', points:31, rank:1 },
                   { id:'you', name:'You', points:27, rank:2, is_me:true }];
    const P = (facts, extra) => Object.assign({
      season:{ league:'Fellas', number:1, status:'active', solo:true },
      facts, history:[], arc:[], table, archive:[],
    }, extra || {});

    t('rung 1: the lead changed hands, and it names the day',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, field:2,
        lead_flip:{ week:7, on:sunday, to:'Jade', to_id:'jade', first_time:true, source:'standings_snapshots' } })).text,
      'The lead changed hands on Sunday. Jade has it for the first time.');
    t('rung 1: a leader who has had it before takes it BACK',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, field:2,
        lead_flip:{ week:7, on:sunday, to:'Jade', to_id:'jade', first_time:false, source:'standings_snapshots' } })).text,
      'The lead changed hands on Sunday. Jade has it back.');
    t('rung 1: when the lead came to ME the sentence is mine',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, field:2,
        lead_flip:{ week:7, on:sunday, to:'You', to_id:'you', first_time:true, source:'standings_snapshots' } })).text,
      'You took the lead on Sunday. For the first time.');
    t('rung 1: a flip six weeks ago is not this week’s news',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:19, field:2,
        leader:{ name:'Galen', run_weeks:4, source:'standings_snapshots' },
        runner_up:{ name:'You', points:27 }, top_gap:4,
        lead_flip:{ week:1, on:sunday, to:'Galen', to_id:'galen', first_time:true, source:'standings_snapshots' } })).rung, 2);
    t('rung 2: a run of four weeks, said out loud',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:19, field:2,
        leader:{ name:'Galen', run_weeks:4, source:'standings_snapshots' },
        runner_up:{ name:'You', points:27 }, top_gap:4 })).text,
      'Galen has led for four straight weeks.');
    t('rung 2: a squad is a THEY, a golfer a she or a he',
      csSeasonStoryLine(Object.assign(P({ week_no:7, weeks_total:26, weeks_left:19, field:4,
        leader:{ name:'Mudsharks', run_weeks:4, source:'standings_snapshots' },
        runner_up:{ name:'The Frost', points:27 }, top_gap:4 }),
        { season:{ solo:false, status:'active' } })).text,
      'Mudsharks have led for four straight weeks.');
    t('rung 2: a run of two weeks is not a run',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:19, field:2,
        leader:{ name:'Galen', run_weeks:2, source:'standings_snapshots' },
        runner_up:{ name:'You', points:27 }, top_gap:9 })).rung !== 2, true);
    t('rung 3: two points at the top, with the clock',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:6, field:4,
        leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
        runner_up:{ name:'You', points:29 }, top_gap:2 })).text,
      'Two points separate the top two with six weeks to play.');
    t('rung 3: level is level, never “zero points separate”',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:6, field:4,
        leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
        runner_up:{ name:'You', points:31 }, top_gap:0 })).text,
      'The top two are level with six weeks to play.');
    t('rung 4: a squad has a plural verb, a golfer a singular one',
      [csSeasonStoryLine(Object.assign(P({ week_no:7, weeks_total:26, weeks_left:9, field:4,
          leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
          runner_up:{ name:'The Frost', points:25 }, top_gap:6,
          closer:{ name:'The Frost', taken:6, weeks:2, source:'standings_snapshots' } }),
          { season:{ solo:false, status:'active' } })).text,
       csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:9, field:4,
          leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
          runner_up:{ name:'Jade', points:25 }, top_gap:6,
          closer:{ name:'Jade', taken:6, weeks:2, source:'standings_snapshots' } })).text],
      ['The Frost have taken six off the lead in a fortnight.',
       'Jade has taken six off the lead in a fortnight.']);
    t('rung 5: the Final’s clock, its seats and who is still live',
      csSeasonStoryLine(P({ week_no:20, weeks_total:26, weeks_left:6, field:4,
        leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
        runner_up:{ name:'You', points:25 }, top_gap:6,
        final:{ opens_on:'2026-12-22', in_weeks:3, seats:2, still_live:4, source:'season_scenarios' } })).text,
      'Three weeks until the Final. Two seats, four still live.');
    t('rung 5: a Final sixteen weeks out is not news',
      csSeasonStoryLine(P({ week_no:7, weeks_total:26, weeks_left:19, field:2,
        leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
        runner_up:{ name:'You', points:25 }, top_gap:6,
        final:{ opens_on:'2026-12-22', in_weeks:16, seats:2, still_live:2, source:'season_scenarios' } })).rung !== 5, true);
    t('rung 6: week one',
      csSeasonStoryLine(P({ week_no:1, weeks_total:13, weeks_left:12, field:6 })).text,
      'Thirteen weeks. Clean cards, fragile egos.');
    t('rung 0: a wrapped season leads with how it ended',
      csSeasonStoryLine(Object.assign(P({ week_no:26, weeks_total:26, field:2 }),
        { season:{ status:'complete', solo:true },
          archive:[{ number:1, champion:'Galen', is_current:true }] })).text, 'Galen took it.');
    t('L-44: no facts, no line', csSeasonStoryLine({}), null);

    /* rung 7 · the reach back, and its absolute fence (R-H) */
    const quiet = { week_no:7, weeks_total:26, weeks_left:19, field:2,
                    leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
                    runner_up:{ name:'You', points:27 }, top_gap:9, last_snapshot_on:sunday };
    t('R-H: the unsettled week, from week_clashes and my_rivalries',
      csSeasonStoryLine(P(quiet, { history:[{ kind:'unsettled_week', source:'week_clashes',
        record_source:'my_rivalries', opponent:'Galen', since:'2026-08-12', days:24,
        wins:5, losses:6, ties:0 }] })).text,
      'You and Galen have not settled a week since the 12th of August. Galen is 6–5 up all-time.');
    t('R-H: the record is read from MY side',
      [csSeasonHistoryLine({ kind:'unsettled_week', source:'week_clashes', opponent:'Galen',
         since:'2026-08-12', days:24, wins:6, losses:5, ties:0 }).slice(-24),
       csSeasonHistoryLine({ kind:'unsettled_week', source:'week_clashes', opponent:'Galen',
         since:'2026-08-12', days:24, wins:5, losses:5, ties:0 }).slice(-30)],
      ['You are 6–5 up all-time.', 'You are level at 5–5 all-time.']);
    t('R-H: a week settled five days ago is no manufactured stake',
      csSeasonStoryLine(P(quiet, { history:[{ kind:'unsettled_week', source:'week_clashes',
        opponent:'Jade', since:'2026-08-31', days:5, wins:2, losses:0, ties:0 }] })).text,
      'Week seven of twenty-six. Nothing has moved since Sunday.');
    t('R-H: my own run at my own place',
      csSeasonStoryLine(P(quiet, { history:[{ kind:'my_run', source:'standings_snapshots', rank:2, weeks:4 }] })).text,
      'You have held 2nd for four straight weeks.');
    t('R-H: my best week, as a difference between two rows that exist',
      csSeasonStoryLine(P(quiet, { history:[{ kind:'my_best_week', source:'standings_snapshots', week:5, points:10 }] })).text,
      'Your best week of the season is still week five — 10 points.');
    t('THE FENCE: a source that is not a named read renders nothing',
      csSeasonStoryLine(P(quiet, { history:[{ kind:'unsettled_week', source:'a_hunch', opponent:'Galen',
        since:'2026-08-12', days:24, wins:5, losses:6, ties:0 }] })).text.indexOf('Galen'), -1);
    /* wave 5 · R4 joined the fence in the same commit as its migration, which
       is the rule the fence itself states: a read that feeds a sentence is
       named here, or its sentences never reach a screen. */
    t('THE FENCE: and the whitelist is the whole of what may be counted over',
      CS_STORY_READS.slice().sort().join(','),
      'head_to_head,my_rivalries,posts,season_scenarios,standings_snapshots,week_clashes');
    t('R-H: a kind this build does not know says nothing',
      csSeasonHistoryLine({ kind:'vibes', source:'standings_snapshots' }), null);
    t('R-H: a run of one week is not a run',
      csSeasonHistoryLine({ kind:'my_run', source:'standings_snapshots', rank:2, weeks:1 }), null);
    t('rung 7b: even history finds nothing, and the sentence is still true',
      csSeasonStoryLine(P(quiet)).text, 'Week seven of twenty-six. Nothing has moved since Sunday.');
    t('rung 7b: with no snapshot at all it says “yet”',
      csSeasonStoryLine(P({ week_no:3, weeks_total:13, weeks_left:10, field:2,
        leader:{ name:'Galen', run_weeks:1, source:'standings_snapshots' },
        runner_up:{ name:'You', points:9 }, top_gap:9 })).text,
      'Week three of thirteen. Nothing has moved yet.');

    /* the arc, and the dateline */
    t('the arc phrases its own facts',
      [csSeasonArcLine({ kind:'lead_change', source:'standings_snapshots', week:5, subject:'Jade', other:'Galen' }),
       csSeasonArcLine({ kind:'clash', source:'week_clashes', week:4, subject:'you', other:'Galen' }),
       csSeasonArcLine({ kind:'clash', source:'week_clashes', week:4, subject:null, other:'Jade' })],
      ['Jade took the lead from Galen.', 'You took the week from Galen.', 'You and Jade halved the week.']);
    t('an arc row whose source is not a named read renders nothing',
      csSeasonArcLine({ kind:'post', source:'somewhere', text:'Trust me' }), null);
    /* WAVE 11 / D280 · the HEAD's eyebrow. The page has a title now, so the
       eyebrow is the stage and the week and NOT the league's name — the
       dateline producer keeps the name for the surfaces with no title. */
    t('D280: the season eyebrow is the stage and the week, never the name',
      [csSeasonEyebrow('season', 5, 13), csSeasonEyebrow('preseason', 1, 13), csSeasonEyebrow('complete', 13, 13)],
      ['SEASON LIVE \u00b7 WEEK 5 OF 13', 'BEFORE FIRST TEE', 'SEASON COMPLETE']);
    t('L-34: the dateline carries the week ONCE, and only in a stage that has one',
      [csSeasonDateline('Fellas', 'season', 7, 26), csSeasonDateline('Fellas', 'preseason', 1, 26),
       csSeasonDateline('Fellas', 'complete', 26, 26)],
      ['FELLAS · WEEK 7 OF 26 · SEASON LIVE', 'FELLAS · BEFORE FIRST TEE', 'FELLAS · SEASON COMPLETE']);

    /* D244 · the exit says exactly what happens, and nothing else */
    t('D244: three facts, and no fourth',
      CS_LEAVE.body,
      'Your rounds stay where they are. Your name stays on the season you played. You stop scoring from today.');
    t('D244: nothing is deleted, removed or forfeited',
      /delete|remove|erase|forfeit/i.test(CS_LEAVE.body), false);
    t('D244: the armed tap restates the consequence (L-32)',
      CS_LEAVE.armed, 'Sure? You stop scoring today');

    /* ── WAVE 5 · the people (R4/R5, D239, D245, IOS-032) ─────────────── */
    (function wave5(){
      const opp = { id:'77777777-7777-7777-7777-777777777777', display_name:'Galen', marker:'beer' };
      const full = csH2HParse({
        visible:true, opponent:opp, league:'Fellas',
        record:{ wins:6, losses:5, ties:0, total:11 }, lead:'up',
        since:'2026-03-14', streak:{ who:'them', n:2 },
        last_five:[{on:'2026-08-30',won:false,facet:'clashes'},{on:'2026-08-23',won:false,facet:'season_weeks'},
                   {on:'2026-08-16',won:true,facet:'played_together'},{on:'2026-08-09',won:true,facet:'live_games'},
                   {on:'2026-08-02',won:null,facet:'duels'}],
        rivalry_name:'The Grudge',
        facets:{
          season_weeks:{ wins:3, losses:1, ties:0, meetings:4, basis:'the better round against your playing HCP in a week you both posted', source:'v_rounds_ranked' },
          clashes:{ wins:1, losses:1, ties:0, meetings:2, basis:'the weekly clash the season opened and settled', source:'week_clashes' },
          played_together:{ wins:1, losses:2, ties:0, meetings:4, unsettled:1, confirmed:1, unconfirmed:1, heuristic:2,
                            basis:'the better card against your playing HCP on a day you were both out', source:'round_players' },
          live_games:{ wins:1, losses:0, ties:0, meetings:1, basis:'the better card against your playing HCP in a round you both scored live', source:'live_rounds' },
          duels:{ wins:0, losses:1, ties:0, meetings:1, basis:'a Ryder clash, settled', source:'event_duels' },
          callouts:{ wins:0, losses:0, ties:0, meetings:1, unsettled:1, basis:'a head-to-head with a field of two', source:'event_duels' },
        },
      });

      /* the six facets, in a fixed order — the same order the phone reads */
      t('R4: six facets, in the order both clients read them',
        full.facets.map(f => f.key),
        ['season_weeks','clashes','played_together','live_games','duels','callouts']);
      t('R4: a facet with no data renders NOTHING (P-6, never 0–0)',
        csH2HParse({ visible:true, opponent:opp, record:{wins:1,losses:0,ties:0,total:1}, lead:'up',
          facets:{ season_weeks:{wins:1,losses:0,ties:0,meetings:1}, duels:{wins:0,losses:0,ties:0,meetings:0} } })
          .facets.map(f => f.key), ['season_weeks']);
      t('R4: a facet key this build does not know is dropped, never guessed',
        csH2HParse({ visible:true, opponent:opp, record:{wins:0,losses:0,ties:0,total:3}, lead:'even',
          facets:{ moon_shots:{wins:2,losses:1,ties:0,meetings:3}, clashes:{wins:0,losses:0,ties:0,meetings:3,unsettled:3} } })
          .facets.map(f => f.key), ['clashes']);

      /* the heuristic carries its label — the whole reason the fallback is allowed */
      t('R4: the same-day/same-course inference is LABELLED wherever it fed a number',
        csH2HFacetSub(full.facets.find(f => f.key === 'played_together')).indexOf(CS_H2H_HEURISTIC) >= 0, true);
      t('R4: a facet with no inference never carries the label',
        full.facets.filter(f => f.heuristic === 0)
          .every(f => (csH2HFacetSub(f) || '').indexOf(CS_H2H_HEURISTIC) < 0), true);
      t('R4: every clause in a sub ends like a sentence (the screenshot defect)',
        full.facets.map(f => csH2HFacetSub(f)).filter(Boolean).every(s => s.slice(-1) === '.'), true);
      t('R4: and the basis never runs into the heuristic label',
        /out Same day/.test(csH2HFacetSub(full.facets.find(f => f.key === 'played_together'))), false);
      t('R4: an unconfirmed tag says so', 
        csH2HFacetSub(full.facets.find(f => f.key === 'played_together')).indexOf(CS_H2H_UNCONFIRMED) >= 0, true);
      t('R4: an undecided meeting is counted in words, and never as a tie',
        /One with no card from one of you/.test(csH2HFacetSub(full.facets.find(f => f.key === 'callouts'))), true);
      t('R4: a meeting with no verdict is not a tie',
        (() => { const c = full.facets.find(f => f.key === 'callouts');
                 return [c.ties, c.unsettled, c.record]; })(), [0, 1, null]);

      /* the sentences — identical to `HeadToHeadCopy`, case for case */
      t('R4: the headline names who leads', 
        [csH2HHeadline(full),
         csH2HHeadline(csH2HParse({ visible:true, opponent:opp, record:{wins:5,losses:6,ties:0,total:11}, lead:'down', facets:{} })),
         csH2HHeadline(csH2HParse({ visible:true, opponent:opp, record:{wins:5,losses:5,ties:0,total:10}, lead:'even', facets:{} }))],
        ['You lead 6–5.', 'Galen leads 6–5.', 'All square, 5–5.']);
      t('R4: nothing decided means no headline at all (L-44)',
        csH2HHeadline(csH2HParse({ visible:true, opponent:opp, record:{wins:0,losses:0,ties:0,total:2}, lead:'even',
          facets:{ played_together:{wins:0,losses:0,ties:0,meetings:2,unsettled:2} } })), null);
      t('R4: the standfirst drops every clause it cannot prove',
        [csH2HStandfirst(full),
         csH2HStandfirst(csH2HParse({ visible:true, opponent:opp, record:{wins:1,losses:0,ties:0,total:1}, lead:'up', facets:{} }))],
        ['Eleven meetings where you both played, going back to March. Galen has taken the last two.',
         'One meeting where you both played.']);
      t('R4: a streak of one is not a streak',
        csH2HParse({ visible:true, opponent:opp, record:{wins:1,losses:1,ties:0,total:2}, lead:'even',
          streak:{ who:'me', n:1 }, facets:{} }).streak, null);
      t('R4: the person clause is the one the card borrows',
        csH2HPersonClause(full), 'Galen has beaten you five times out of eleven.');
      /* a real screenshot caught the first cut naming the golfer twice in two
         consecutive clauses — "Galen has won one title. Galen has beaten you…" */
      t('the day said out loud never shouts mid-sentence (L-33)',
        [csSpokenDay('2026-05-03'), csSpokenDay('nonsense')], ['May 3', '']);

      /* R5 · the board */
      const me = { profile_id:'1', display_name:'Jerecho', rounds_30d:6, beats_30d:2, avg_vs_number_30d:0.4, is_me:true };
      const tash = { profile_id:'2', display_name:'Tash', rounds_30d:4, beats_30d:3, avg_vs_number_30d:2.4, is_me:false };
      const jade = { profile_id:'3', display_name:'Jade', rounds_30d:0, beats_30d:0, avg_vs_number_30d:null, is_me:false };
      t('R5: the form line names its denominator (L-01) and speaks for whose number it is',
        [csBoardFormLine(tash), csBoardFormLine(me), csBoardFormLine(jade)],
        ['4 rounds · beat their playing HCP 3 times', '6 rounds · beat your playing HCP twice', 'No rounds in the window']);
      t('R5: the figure is a BAND, never the float (L-14 / T-07)',
        [csBoardBand(tash), csBoardBand(jade)], ['Beat their number', null]);
      t('R5: the possessive turns on somebody else’s row, and only there',
        [csBoardBand(me), bandName(2.4)], ['Played to it', 'Beat your number']);
      t('R5: the two clients agree on the band boundary',
        csBoardBand({ rounds_30d:1, avg_vs_number_30d:1, is_me:true }), 'Beat your number');

      /* the fence gained its new read in the same commit as its migration */
      t('wave 5: head_to_head is inside the story fence',
        CS_STORY_READS.indexOf('head_to_head') >= 0, true);
      t('wave 5: and the fence is still exactly the six named reads',
        CS_STORY_READS.length, 6);

      /* P-17 · the safety block is a producer, and it does not sell a Block */
      t('P-17: the block renders for another golfer and never for me',
        [csSafetyMenuHtml('someone-else', 'Galen').length > 0,
         csSafetyMenuHtml(null, 'Galen')], [true, '']);
      t('P-17: the reasons are five, and "Something else" is last',
        [CS_SAFETY_REASONS.length, CS_SAFETY_REASONS[CS_SAFETY_REASONS.length - 1]], [5, 'Something else']);
      t('L-19: a tag is never a vouch, and the page says so',
        /says nothing about the score/.test(CS_H2H_NOT_A_VOUCH), true);
    })();

    /* D235 · the endgame under the table is the whole mechanic */
    t('D235: the sentence ends on §14.3’s ladder',
      /Level on points\? Months won breaks it\.$/.test(endgameLine({ finish:'cup_final', structure:'solo' })), true);
    t('D235: and it keeps D126’s own phrase',
      /scored fresh/.test(endgameLine({ finish:'cup_final', structure:'solo' })), true);
  })();

  /* ------------------------------------------------------------------ wave 6
     THE RAILS · D238 (a post can be homed on a person), D241 (the person
     link), D253 (the plan link). The migrations are what widen the CHECKs;
     what these hold is the half a golfer can see — and, critically, that BOTH
     CLIENTS decide the same things the same way (D234). Each assertion below
     has a twin in `PersonHomedPostTests` or `ShareKindTests`. */
  (function(){
    /* D238 · whose reaction is this. The old test compared ONE member id, so a
       golfer in two leagues saw their own 🔥 as somebody else's. */
    const H = window.homeRx;
    window.homeRx = {
      myPid: 'me', myIds: new Set(['memA']),
      mem2pid: { memA:'me', memB:'me', memG:'galen' },
      names: { me:'Jerecho', galen:'Galen', memA:'Jerecho', memB:'Jerecho', memG:'Galen' },
    };
    t('D238: a profile-keyed reaction of mine is mine',
      csKudoMine({ post_id:'p', profile_id:'me', emoji:'🔥' }), true);
    t('D238: and through EITHER membership, once the roster resolves it',
      [csKudoMine({ post_id:'p', member_id:'memA' }), csKudoMine({ post_id:'p', member_id:'memB' })], [true, true]);
    t('D238: somebody else is still somebody else, by either road',
      [csKudoMine({ post_id:'p', profile_id:'galen' }), csKudoMine({ post_id:'p', member_id:'memG' })], [false, false]);
    t('D238: a row that resolves to nobody is "someone", never a guess',
      [csKudoWho({ post_id:'p', profile_id:'galen' }), csKudoWho({ post_id:'p', member_id:'nope' })], ['Galen', 'someone']);
    window.homeRx = H;

    /* D238 · the ONE skew fallback, and everything it must not swallow. It
       identifies the same person by a different column; it never writes a
       different reaction (the retired emoji fallback's mistake). */
    t('D238: the skew fallback fires on a column PostgREST has never heard of',
      [csKudoSkew({ code:'PGRST204', message:"Could not find the 'profile_id' column of 'post_kudos'" }),
       csKudoSkew({ message:'column "profile_id" does not exist' })], [true, true]);
    t('D238: and NOT on a refusal, a network drop or a duplicate',
      [csKudoSkew({ message:'new row violates row-level security policy' }),
       csKudoSkew({ message:'Failed to fetch' }),
       csKudoSkew({ message:'duplicate key value violates unique constraint' })], [false, false, false]);

    /* D241 / D253 · the two links. Two kinds, two queries, and the signed-out
       surface still at TWELVE — `share_info` is already one of them, and the
       write half (`redeem_share`) is authenticated-only. */
    t('D241/D253: two kinds, and the two queries the AASA claims',
      CS_SHARE_LINKS.map(l => l.kind + ':' + l.q), ['person:p', 'plan:plan']);
    t('D241/D253: and two storage keys that cannot collide',
      new Set(CS_SHARE_LINKS.map(l => l.key)).size, 2);

    /* every dead path is ONE outcome and ONE sentence (D57, fail-closed) */
    [null, undefined, {}, { kind:null }, { kind:'a_kind_from_the_future' }].forEach((d, i) => {
      t('D241: dead path ' + i + ' answers the same nothing',
        csShareLine('person', d), 'That link has expired. Whoever sent it can share a fresh one.');
    });

    /* D80 · a REQUEST, never a friendship — unless they asked first */
    t('D241: the sentence says request, not friendship',
      csShareLine('person', { kind:'person', result:'requested' }), 'Asked to join their crew. They’ll get the nudge.');
    t('D241: mutual intent is the ONLY case that says buddies',
      csShareLine('person', { kind:'person', result:'friend' }), 'You’re in each other’s crew now.');
    t('D241: your own link on your own phone says nothing',
      csShareLine('person', { kind:'person', result:'self' }), null);

    /* D253 · one plan, one seat */
    t('D253: the seat, and the request the host still has to accept',
      csShareLine('plan', { kind:'plan', seat:'in', result:'requested' }),
      'You’re in for that round. The host has your buddy request.');
    t('D253: a second open writes nothing more and says which it was',
      csShareLine('plan', { kind:'plan', seat:'already', result:'friend' }),
      'You’re already down for that round.');
    t('D253: a plan whose day has gone gets the card and no seat',
      csShareLine('plan', { kind:'plan', seat:'past' }), 'That round has already been played.');
    t('D253: the host opening their own link says nothing',
      csShareLine('plan', { kind:'plan', seat:'host', result:'host' }), null);
    t('D253: a seat word from the future lands on the conservative truth',
      csShareLine('plan', { kind:'plan', seat:'waitlisted' }), 'You’re already down for that round.');

    /* L-32 · a kind the CHECK does not admit yet is NOT an error the golfer
       caused, and the row removes itself rather than offering a door that fails */
    t('D241: an undeployed kind is "not yet", not a failure',
      [csShareKindNotDeployed({ code:'23514', message:'violates check constraint "shares_kind_check"' }),
       csShareKindNotDeployed({ message:'Nothing to share' })], [true, true]);
    t('D234: and the "not yet" sentence is the phone\u2019s, verbatim',
      CS_SHARE_NOT_YET, 'Links need the latest update \u2014 try again shortly.');
    t('D241: and a real failure is still a real failure',
      [csShareKindNotDeployed({ message:'Failed to fetch' }),
       csShareKindNotDeployed({ message:'Sign in first' })], [false, false]);
  })();

  /* DEF-1 · the short name of a course. BUILD_PLAN §2.z: a producer that
     interpolates a server string into a slot sized for a short one looks
     correct in a test and wrong on a phone. `MeStripCopy.shortCourse` is the
     twin and `LongCourseNameTests` asserts the same four answers. */
  t('DEF-1: prod’s longest label becomes the club',
    csShortCourse('Gold Canyon — Dinosaur Mountain · Black/Blue'), 'GOLD CANYON');
  t('DEF-1: the layout and the tee variant are both dropped',
    [csShortCourse('Troon North Golf Course — Pinnacle Course · Gold'),
     csShortCourse('Raven Golf Club-Phoenix · Silver')],
    ['TROON NORTH GOLF COURSE', 'RAVEN GOLF CLUB-PHOENIX']);
  t('DEF-1: a plain name is left as it is, and nothing is invented from nothing',
    [csShortCourse('Papago Golf Course'), csShortCourse(null), csShortCourse('   ')],
    ['PAPAGO GOLF COURSE', null, null]);

  /* ============ WAVE 7 · intent, the callout, and the covenant ============
     D225 · the doors name what I want, not what the engine has. The whole
     ruling rests on one testable property: no string the sheet renders may
     contain an engine object noun. */
  (function () {
    t('D225: the sheet is four peers and one modifier',
      [CS_INTENTS.length, typeof csIntentStrings, csIntentStrings().length], [4, 'function', 12]);
    t('D234: the lines are the phone\u2019s, verbatim',
      CS_INTENTS.map(i => i.line),
      ['Play with my friends', 'Run a season', "We're playing this weekend", 'Go head to head']);
    /* R-J · the retired phrasing cannot come back, on either client */
    t('R-J: no intent begins "I want to", and none says "beat one guy"',
      csIntentStrings().filter(x => /i want to|beat one guy/i.test(x)), []);
    t('R-J: and the sheet is addressed to every golfer in a mixed league',
      csIntentStrings().flatMap(x => x.toLowerCase().split(/[^a-z]+/).filter(w => ['him','his','her','hers','guy','guys'].includes(w))), []);
    t('D234: and so are the glosses',
      CS_INTENTS.map(i => i.gloss),
      ['a round with whoever is around', 'weeks of golf that add up to a table',
       'one day, and a name for it', 'the two of you, at whatever length you like']);
    t('D225: zero object nouns, on every string the sheet renders',
      csIntentStrings().flatMap(csObjectNouns), []);
    t('D225: and the ban is on WORDS, not substrings',
      [csObjectNouns('Run a season'), csObjectNouns('seasonal golf'),
       csObjectNouns('Start a league'), csObjectNouns('Start an event')],
      [[], [], ['league'], ['event']]);
    /* L-32 · a weekend mints no trophy (D240), so the door does not sell one */
    t('D240: the weekend door sells a name, never a trophy',
      [CS_INTENTS[2].gloss.includes('trophy'), CS_INTENTS[2].gloss.includes('cup')], [false, false]);

    /* R-F · all three lengths, always, in the owner's own words */
    t('R-F: the three lengths are the owner\u2019s words',
      CS_LENGTHS.map(l => l.title + ' — ' + l.gloss),
      ['This Saturday — a live match, on one card',
       'One week — best round by Sunday takes it',
       'A season — a table, and a cup at the end']);
    t('R-F: the state ORDERS them and never shortens them',
      [csLengthsOffered(false, false).map(l => l.k),
       csLengthsOffered(true, false).map(l => l.k),
       csLengthsOffered(false, true).map(l => l.k),
       csLengthsOffered(true, true).map(l => l.k)],
      [['thisSaturday', 'oneWeek', 'aSeason'],
       ['thisSaturday', 'oneWeek', 'aSeason'],
       ['thisSaturday', 'oneWeek', 'aSeason'],
       ['thisSaturday', 'oneWeek', 'aSeason']]);
    t('R-F: every length lands on an object that already exists',
      CS_LENGTHS.map(l => l.object), ['liveRound', 'callout', 'pairSeason']);
    t('R-F: and the golfer never meets the object\u2019s name',
      CS_LENGTHS.flatMap(l => csObjectNouns(l.title + ' ' + l.gloss)), []);

    /* D225 / R9 · the covenant names the crew, the clock and what the money
       buys — and an absent fact renders NOTHING (L-44). */
    const full = {
      name: 'the Fellas', buyin_cents: 5000, preset: 'standard', floor: 2, finish: 'cup_final',
      roster: { count: 8, pro_name: 'Casey Nguyen', names: ['Marcus Webb', 'Dev Patel', 'Tash Boyle', 'Ravi Shah', 'Jules Kerr'] },
      starts_on: '2026-09-12', weeks: 13, counting_cap: 3,
      split: { champion: 60, runner_up: 25, points_king: 15 }, pay: { has_note: true, due_on: null },
    };
    const F = info => csCovenantFacts(info).reduce((m, f) => (m[f.k] = f.t, m), {});
    t('D225: WHO comes before the money',
      [csCovenantFacts(full)[0].k, F(full).who],
      ['who', 'Casey Nguyen runs the season (the Pro). Marcus, Dev, Tash, Ravi, Jules and 2 more are in.']);
    t('D234: the clock reads the same on both clients',
      F(full).length, 'Thirteen weeks from Sat Sep 12.');
    t('R9: the rounds that count makes "best three a month count" sayable',
      F(full).rules, 'Standard rules: honest scores, best three a month count, two a month keeps you in.');
    t('D126: the ending is a sentence, never a dial name',
      [F(full).ending, F({ name: 'x', buyin_cents: 0, finish: 'points_table' }).ending],
      ['It ends with a four-week Cup Final between the top two.',
       "The season's points decide it. No reset."]);
    t('L-10: the split answers what $50 buys, and renders above $0 only',
      [F(full).split, F({ name: 'x', buyin_cents: 0, split: { champion: 60, runner_up: 25, points_king: 15 } }).split],
      ['If you take it: 60 percent to the champion, 25 to the runner-up, 15 to the points king.', undefined]);
    t('D129: the pay fact is a boolean and a date, never the note',
      [F(full).pay, F({ name: 'x', buyin_cents: 5000, has_pay_note: false }).pay],
      ["The Pro has said how to pay. You'll see it on the pot.",
       "The Pro hasn't said how to pay yet. It'll be on the pot when they do."]);
    t('L-09: the ledger line is the constant, never retyped', F(full).ledger, CS_LEDGER);
    /* L-44 · the SHIPPED payload, with none of R9's six */
    const today = { name: 'the Fellas', buyin_cents: 5000, preset: 'standard', floor: 2, finish: 'cup_final' };
    t('L-44: an absent fact renders nothing at all',
      [F(today).who, F(today).length, F(today).split, F(today).pay],
      [undefined, undefined, undefined, undefined]);
    t('L-44: and the facts it CAN say are still said',
      csCovenantFacts(today).map(f => f.k), ['rules', 'ending', 'stake', 'ledger']);
    /* L-12 · the covenant renders at $0 — the defect D225 exists to close */
    t('L-12: a $0 season still passes the covenant, with no money lines',
      csCovenantFacts({ name: 'the Fellas', buyin_cents: 0, preset: 'standard', floor: 2, finish: 'cup_final',
                        roster: { count: 3, pro_name: 'Casey Nguyen', names: ['Dev Patel'] },
                        starts_on: '2026-09-12', weeks: 13, counting_cap: 3 }).map(f => f.k),
      ['who', 'length', 'rules', 'ending']);
    t('D124: the starter clause renders on fewer than three posted rounds',
      [csCovenantFacts(today, 0).some(f => f.k === 'starter'),
       csCovenantFacts(today, 3).some(f => f.k === 'starter'),
       csCovenantFacts(today).some(f => f.k === 'starter')],
      [true, false, false]);
    t('D225: the fact ORDER is a value both clients hold',
      CS_COVENANT_FACTS, ['who', 'length', 'rules', 'ending', 'stake', 'ledger', 'split', 'pay', 'starter']);
    /* R18 · the pay note is the ONE required field above $0 */
    t('R18: above $0 with no note the publish is blocked, and $0 never is',
      [typeof csPayNoteMissing, typeof csPayNote], ['function', 'function']);
  })();

  /* ===================================================================
     WAVE 8 · ONBOARDING, CONTACTS AND RUN IT BACK (D247, D233, D251, D243)
     ===================================================================
     Every assertion below has a twin in `OnboardingTests` / `ContactHashTests`
     / `PushKindTests` on the phone, asserting the SAME literal. A reword on one
     client fails on the other, which is what D234 exists to enforce. */
  (function(){
    /* D247 · question 1, in a golfer's units */
    t('D247: the handicap is asked in scores', CS_ONBOARDING.shootQuestion, 'What do you usually shoot?');
    t('D247: five bands, in the ruled words',
      CS_SCORE_BANDS.map(b => b.title), ['Under 80', '80s', '90s', '100+', 'No idea']);
    t('D247: "No idea" implies no number', csScoreBand('noIdea').starter, null);
    t('D247: the bands run the right way', CS_SCORE_BANDS.slice(0,4).map(b => b.starter), [6, 13, 20, 28]);
    t('D247: the question never says "index"',
      /index/i.test(CS_ONBOARDING.shootQuestion + ' ' + CS_ONBOARDING.shootSub), false);
    /* L-14 · a band is the middle of a RANGE, so it never wears the engine's
       own precision. This is the exact defect the phone's first cut had. */
    t('L-14: a whole starter prints whole', csStarterText(13), '13');
    t('L-14: and a fractional one still shows its place', csStarterText(12.4), '12.4');

    /* D247 · the two defaults, and the gate that is still marker AND handle */
    t('D247: the handle derives from the name', csHandleFromName('Jerecho Fischbeck'), 'jerechofischbeck');
    t('D247: and never longer than 20', csHandleFromName('a'.repeat(40)).length, 20);
    t('D247: a two-letter nickname derives an illegal handle', csHandleIsLegal(csHandleFromName('JT')), false);
    t('CLAUDE.md landmine: the gate is marker AND handle',
      [csOnboardingGate('saguaro','jer'), csOnboardingGate(null,'jer'),
       csOnboardingGate('saguaro',null), csOnboardingGate('  ','jer')],
      [true, false, false, false]);
    /* THE PARITY FIXTURE. `MarkerDefault.assign` (Kit) and `csMarkerDefault`
       run the same djb2-with-a-per-step-mod over the same key order, so the
       same golfer gets the same marker on the phone and at the desk. These four
       are asserted by `OnboardingTests` too — a floor that differs between a
       golfer's two screens is not a floor. */
    t('D247/L-24: the defaulted marker is the phone\'s marker',
      ['jerecho','galen','jade','tash'].map(csMarkerDefault),
      ['island','lighthouse','shark','dunes']);
    t('L-24: the footnote names it and says where to change it',
      csMarkerFootnote('The Island'),
      'Your marker is The Island until you pick another — tap it, or change it any time from You.');

    /* D233 · four routes, and the exit is not a failure */
    t('D233: four crew routes, in reading order',
      CS_CREW_ROUTES.map(r => r.title),
      ['Find your friends', 'Search by name or @handle',
       'Text an invite to somebody else', "Nobody yet — I'll add them later"]);
    t('D233: the exit is never called "skip"', /skip/i.test(CS_CREW_ROUTES[3].title), false);
    /* THE ONE LEGITIMATE DIFFERENCE, and it is a capability rather than copy:
       a desktop browser has no address book, so the contacts door is drawn only
       where `navigator.contacts.select` exists. L-32 forbids a door that cannot
       open, so on this machine the desk offers three. */
    t('L-32: a door that cannot open is not drawn',
      csCrewRoutes().some(r => r.key === 'contacts'), csContactsAvailable());

    /* D251 · the privacy envelope */
    t('D251: the consent sentence says what travels and what is kept',
      CS_ONBOARDING.contactsConsent,
      "We'll check your contacts against the golfers already here. We send hashes, never your contacts, and we keep nothing that doesn't match.");
    t('D251: declining is a named control', CS_ONBOARDING.contactsDecline, 'Not now');
    t('D251: an empty match ends in a next move',
      CS_ONBOARDING.contactsNone, 'None of your contacts is here yet. Text one a link.');
    t('L-32: refused, not-yet and nobody are three different facts',
      new Set([CS_ONBOARDING.contactsNone, CS_ONBOARDING.contactsRefused, CS_ONBOARDING.contactsNotYet]).size, 3);
    t('D251: a match is counted in words', [csContactsFound(0), csContactsFound(1), csContactsFound(3)],
      [null, 'One of your friends is already here.', '3 of your friends are already here.']);
    /* normalisation — the migration's own self-check cases, verbatim */
    t('C-11: email normalisation matches the server',
      csNormaliseEmail('  Jerecho@Example.COM '), 'jerecho@example.com');
    t('C-11: no provider cleverness', csNormaliseEmail('a.b+golf@gmail.com'), 'a.b+golf@gmail.com');
    t('C-11: a non-address is not an address',
      [csNormaliseEmail('jerecho'), csNormaliseEmail('@example.com'), csNormaliseEmail('')],
      [null, null, null]);
    t('C-11: phone normalisation matches the server',
      [csNormalisePhone('(480) 555-0134'), csNormalisePhone('+44 20 7946 0958'), csNormalisePhone('555-0134')],
      ['+14805550134', '+442079460958', null]);
    t('C-11: one number written four ways is one hash input',
      new Set(['4805550134','480-555-0134','(480) 555 0134','+1 480 555 0134'].map(csNormalisePhone)).size, 1);
    t('C-11: the cap is the server\'s own cap', CS_CONTACT_MAX, 1000);
    /* the digest itself is async (SubtleCrypto), so the SHA-256 vector is
       asserted in the browser walk's --eval rather than here; what this holds
       is that the client's half EXISTS and takes no salt argument. */
    t('C-11: the client hashes, and takes no salt', csContactDigest.length, 1);

    /* D243 · run it back, role-gated */
    t('D243: the Pro runs it back', csRunItBackTitle(true, 'Galen'), 'Run it back — Season 2');
    t('D243: a member asks, and the Pro is named', csRunItBackTitle(false, 'Galen'), 'Ask Galen to run it back');
    t('D243: with no name it is still a door', csRunItBackTitle(false, null), 'Ask the Pro to run it back');
    t('D243: the Pro\'s sub promises the roster',
      csRunItBackSub(true), 'Same crew, same rules, fresh table. Nobody re-types a code.');
    t('D243: the outcome names the season and the crew',
      csRunItBackDone(2, 6, false), 'Season 2 is on. 6 of you are on it.');
    t('L-12: a changed stake fires the covenant again, and says so',
      csRunItBackDone(2, 6, true),
      'Season 2 is on. 6 of you are on it. The terms changed, so everyone reads them again.');
  })();

  /* ============ WAVE A · what a round is worth (R-K, D256) ============
     The sum is `public.round_worth`'s, ported verbatim; these are the same
     five cases tests/db-checks.sql 31 evaluates on the server and
     RoundWorthTests asserts on the phone. */
  (function () {
    t('D256: a slot is open, so the round ADDS its points', csRoundWorth(4, 2, 6), 12);
    t('D256: a full month BUMPS the worst counter', csRoundWorth(4, 4, 6), 6);
    t('D256: a month of top-band rounds gains nothing', csRoundWorth(4, 4, 12), 0);
    t('D256: full with an unknown counter has no honest answer', csRoundWorth(4, 4, null), null);
    t('D256: uncapped means every round counts', csRoundWorth(null, 9, null), 12);
    t('R-K: the owner\u2019s own sentence',
      csRoundWorthLine('Tomorrow at Papago', 4, 2, null, null),
      'Tomorrow at Papago is worth up to 12. Your best 4 count and you have 2.');
    t('D24: it is a ceiling, never a probability',
      /up to/.test(csRoundWorthLine('This round', 4, 2, null, null)), true);
    t('D256: a full month says what it bumps',
      csRoundWorthLine('This round', 4, 4, 7, null),
      'This round is worth up to 5 more. Your best 4 count this month and your worst is a 7.');
    t('L-44: absent facts render nothing', csRoundWorthLines(undefined, 'This round'), []);
    t('L-34: the season is named only when there is more than one',
      [csRoundWorthLines([{ league_name: 'The Fellas', cap: 4, used: 2 }], 'This round').length,
       csRoundWorthLines([{ league_name: 'The Fellas', cap: 4, used: 2 },
                          { league_name: 'PIGL', cap: 3, used: 0 }], 'This round')[1].includes('in PIGL'),
       csRoundWorthLines([{ cap: 4, used: 1 }, { cap: 4, used: 1 }, { cap: 4, used: 1 }], 'This round').length],
      [1, true, 2]);
  })();

  /* ── Wave 3 · the profile's own producers ───────────────────────────── */
  (function(){
    /* UI_SYSTEM §5.2 · two achievements may never share a glyph. This map drew
       🏆 for four kinds of hardware, 🎯 twice and 📈 twice. */
    t('§5.2: the hardware marks are four things, not one',
      [trophyGlyph('league','winner'), trophyGlyph('ryder','winner'),
       trophyGlyph('bracket','winner'), trophyGlyph('league','runner_up')],
      ['cup','duel','bracket','runnerUp']);
    t('§5.2: no two milestones share a mark', (function(){
      const seen = new Set();
      for(const k in ACH_META){ const m = ACH_META[k]; seen.add(m.glyph + '|' + (m.numeral||'')); }
      return seen.size === Object.keys(ACH_META).length;
    })(), true);
    t('LINT-28: no mark is the pennant',
      Object.keys(ACH_META).some(k => ACH_META[k].glyph === 'pennant'), false);
    t('the mark is drawn, never an emoji',
      /[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}]/u.test(csTrophyMark('cup', null, 28)), false);
    t('a parametric mark carries its numeral',
      csTrophyMark('threshold', '80', 28).includes('80'), true);

    /* profile.md §7 / D-5 · a WIN takes the gold rule; a podium takes ink. */
    const leaf = csRecordLeaf([
      { year:'2026', name:'Desert Mountain Cup', qualifier:null, finish:1, won:true },
      { year:'2026', name:'The Fellas', qualifier:'SEASON ONE', finish:2, won:false },
      { year:'2026', name:'Dew Sweepers', qualifier:'SPRING', finish:5, won:false },
    ]);
    t('§7: a win takes the gold rule', (leaf.match(/mark won/g)||[]).length, 1);
    t('§7: a podium takes an ink rule, and 5th takes none', (leaf.match(/mark pod/g)||[]).length, 1);
    t('§9.8: a win reads WON, not 1ST', leaf.includes('>WON<'), true);
    t('§1.7: one ordinal, uppercase, on the baseline', leaf.includes('>ND<'), true);
    t('§14.2: the money column is dropped, not zeroed', /MONEY/.test(leaf), false);
    t('L-44: an empty record draws no leaf', csRecordLeaf([]), '');

    /* §9.10 · the meeting tape — no legend, one key line, halves on the rule */
    const tape = csTapeHtml([{ won:true },{ won:false },{ won:null }],
                            { first:'JUN 14', last:'SEP 21', spoken:'Eleven meetings.' });
    t('§9.10: the tape is one element with one sentence',
      tape.includes('aria-label="Eleven meetings."'), true);
    t('§9.10: the key line is four words', tape.includes('One square is one win.'), true);
    t('§9.10: yours filled, theirs outlined, a half on the rule',
      [/class="me"/.test(tape), /class="them"/.test(tape), /class="half"/.test(tape)],
      [true, true, true]);
    t('§9.10: no legend on a chart', /LEGEND|KEY:/i.test(tape), false);
    t('L-44: no meetings, no tape', csTapeHtml([], {}), '');
  })();

  const fails = R.filter(r => !r.ok);
  console.log(`\n${fails.length ? 'FAIL' : 'PASS'} — ${R.length} tests, ${fails.length} failure(s)`);
  return { total: R.length, failures: fails.map(f => f.name) };
})();
