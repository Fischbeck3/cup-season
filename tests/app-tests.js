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

  /* ── D186 / IOS-029 · the card travels, and the You doors swap ──────────
     The share view is driven through its QA hook with a STUB payload, so the
     card branch is exercised with no network and no live token. */
  (function cardShare(){
    const kill = () => document.getElementById('shareView')?.remove();

    if (typeof window._csShareRender === 'function') {
      /* 1 · the number IS the headline when share_info sends one */
      kill();
      window._csShareRender('11111111-1111-1111-1111-111111111111', {
        kind: 'card', name: 'Jerecho Fischbeck', handle: 'jerecho', marker: 'saguaro',
        city: 'Tempe, AZ', member_since: '2026-07-04', index_current: 12.4,
        career: { rounds: 211, best: 9.2 }, trophies: [], recent: [{ beat: true }, { beat: false }],
        photo: false,
      });
      const sv = document.getElementById('shareView');
      const txt = sv ? (sv.innerText || '') : '';
      t('card share: renders the golfer', /Jerecho Fischbeck/.test(txt), true);
      t('card share: the number is the headline', /12\.4/.test(txt) && /HANDICAP INDEX/.test(txt), true);
      t('card share: the invite is the CTA', !!document.getElementById('svBuddy'), true);
      t('card share: the form row draws a coal per round',
        sv ? sv.querySelectorAll('span[style*="border-radius:3px"]').length : 0, 2);

      /* 2 · discoverable='friends' seen by a non-buddy: share_info withholds
         index_current, and the page must NOT invent one. */
      kill();
      window._csShareRender('22222222-2222-2222-2222-222222222222', {
        kind: 'card', name: 'Dana Reyes', marker: 'island',
        career: { rounds: 46 }, trophies: [], recent: [], photo: false,
      });
      const sv2 = document.getElementById('shareView');
      const txt2 = sv2 ? (sv2.innerText || '') : '';
      t('card share: no number, no invention', /HANDICAP INDEX/.test(txt2), false);
      t('card share: falls back to the rounds line', /ROUNDS POSTED/.test(txt2) && /46/.test(txt2), true);
      t('card share: the invite survives a number-less card', !!document.getElementById('svBuddy'), true);

      /* the dead-token branch is unchanged by D186 and only resolves after an
         awaited RPC, which this synchronous harness cannot observe — it is
         covered by tests/share-card-local.sql check 14 instead (a revoked
         token and a garbage token both answer the identical null). */
      kill();
    }

    /* 4 · IOS-029 call 1 — the gear means SETTINGS, and the card has its own
       labelled door. Both were one control before: a gear that opened a form. */
    t('you: the gear says settings',
      document.getElementById('youProfile')?.getAttribute('aria-label'), 'Settings');
    t('you: the card has a labelled door', !!document.getElementById('youEditCard'), true);
    t('you: the credential itself is a button',
      document.getElementById('youCard')?.getAttribute('role'), 'button');

    /* 5 · E2 — the image shares mint a link before they hand the file over.
       The helper is synchronous to assert only in its existence; its guards
       (no ref / demo) are covered by the migration's own harness and by the
       fact that every caller passes a nullable id. */
    t('share: the image paths have a mint helper', typeof csShareToken, 'function');
  })();

  /* ── D187 · the scan door ────────────────────────────────────────────────
     The loop was never broken: 92 composer opens since it shipped and 0
     invocations. These pin the two things that changed — the value is stated
     where the choice is made, and the tap is finally recorded. */
  (function scanDoor(){
    if (typeof refreshPostPhotoUI !== 'function') return;
    const realDemo = state.demo, realCS = window.CS, realFlag = window.scanFlag, realFrom = window.sb && window.sb.from;
    state.demo = false;
    window.CS = Object.assign({}, window.CS, { user: { id: '11111111-1111-1111-1111-111111111111' } });

    window.scanFlag = { enabled: true }; refreshPostPhotoUI();
    const btn = document.getElementById('postScanBtn'), fine = document.getElementById('postScanFine');
    t('scan: the button shows when the flag is on', btn && getComputedStyle(btn).display !== 'none', true);
    t('scan: the group line rides WITH the button', fine && getComputedStyle(fine).display !== 'none', true);
    t('scan: the line names what you get, not the mechanism',
      /everyone else on the card/.test(fine ? fine.textContent : ''), true);

    window.scanFlag = { enabled: false }; refreshPostPhotoUI();
    t('scan: flag off hides the line too, not just the button',
      fine && getComputedStyle(fine).display, 'none');

    /* the tap is the breadcrumb that did not exist — without it, "nobody taps
       it" and "everyone abandons the confirm" read identically */
    if (window.sb) {
      const seen = [];
      window.sb.from = (tbl) => ({ insert: (row) => { if (tbl === 'client_events') seen.push(row.event);
                                                      return { then: (r) => Promise.resolve({}).then(r) }; } });
      window.scanFlag = { enabled: true }; refreshPostPhotoUI();
      document.getElementById('postScanBtn')?.click();
      t('scan: the tap is recorded', seen.indexOf('scan_tap') >= 0, true);
      window.sb.from = realFrom;
    }
    state.demo = realDemo; window.CS = realCS; window.scanFlag = realFlag;
    refreshPostPhotoUI();
  })();

  /* ── D188 · the store handoff ────────────────────────────────────────────
     The CTA must be silent until there IS a listing, and silent on anything
     that is not an iPhone. A dead App Store link broadcast into a group
     thread is worse than no link at all. */
  (function storeCTA(){
    if (typeof window._csShareRender !== 'function' || !window.sb) return;
    const realRpc = window.sb.rpc;
    const render = (flags) => {
      document.getElementById('shareView')?.remove();
      window.sb.rpc = (name) => Promise.resolve({ data: name === 'door_flags' ? flags : null, error: null });
      window._csShareRender('44444444-4444-4444-4444-444444444444', {
        kind: 'card', name: 'Dana Reyes', marker: 'island', career: { rounds: 12 },
        trophies: [], recent: [], photo: false,
      });
    };
    const store = () => document.getElementById('svStore');

    render({ app_store_url: 'https://apps.apple.com/app/id123' });
    // the UA in this harness is desktop Chromium, so the gate must hold
    t('store: silent on a machine that cannot install it',
      (store() ? store().innerHTML : '').trim(), '');

    render({ app_store_url: null });
    t('store: silent with no listing to point at',
      (store() ? store().innerHTML : '').trim(), '');

    /* caught by driving it: the RPC nullif(trim())s a blank, but a client that
       trusted that alone rendered href="   " — a dead App Store link in
       somebody's group thread. Both layers are asserted. */
    render({ app_store_url: '   ' });
    t('store: a blank flag is not a link', (store() ? store().innerHTML : '').trim(), '');
    render({ app_store_url: 'javascript:alert(1)' });
    t('store: only https ever becomes an href', (store() ? store().innerHTML : '').trim(), '');

    // the box exists on every kind, so the CTA is not a card-only affordance
    t('store: the slot rides every share kind', !!store(), true);
    document.getElementById('shareView')?.remove();
    window.sb.rpc = realRpc;
  })();

  const fails = R.filter(r => !r.ok);
  console.log(`\n${fails.length ? 'FAIL' : 'PASS'} — ${R.length} tests, ${fails.length} failure(s)`);
  return { total: R.length, failures: fails.map(f => f.name) };
})();
