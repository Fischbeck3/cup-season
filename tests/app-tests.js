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

  const fails = R.filter(r => !r.ok);
  console.log(`\n${fails.length ? 'FAIL' : 'PASS'} — ${R.length} tests, ${fails.length} failure(s)`);
  return { total: R.length, failures: fails.map(f => f.name) };
})();
