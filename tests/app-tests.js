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
    t('D205: a solo league has no squads to form', lockButtonText(), 'Lock the bylaws');
    state.structure = 'squads2';
    t('D205: squads still form at the lock', lockButtonText(), 'Lock the bylaws & form the squads');
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
    t('M-15: the bylaws row names the norm', VERIF[2], 'Attested where you can; the Pro rules on the rest');
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
      x.open('GET', 'tests/fixtures/endgame.json', false);
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

  const fails = R.filter(r => !r.ok);
  console.log(`\n${fails.length ? 'FAIL' : 'PASS'} — ${R.length} tests, ${fails.length} failure(s)`);
  return { total: R.length, failures: fails.map(f => f.name) };
})();
