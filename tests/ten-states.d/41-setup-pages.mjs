/* Cup Season · ten-capture states: SCHEDULE & PLAN · WIZARD · COURSES & THE
 * COURSE CARD · SETTINGS & THE SHEETS · GET / SUPPORT / LEGAL · THE DESK
 * (WX lane, 2026-09-28). The answers behind them are
 * tests/fixtures/ten/rpc/40-links-setup.mjs; the ids are
 * tests/fixtures/ten/links-setup/ids.mjs.
 *
 * Reached through the page's own controls, its router (window.switchView) or
 * its own bridged openers (window.openRoundSheet) -- never by writing markup.
 * Each check names something unique to the surface. */
import { SHARE, PLAN, COURSE } from '../fixtures/ten/links-setup/ids.mjs'
import { notMono, readsAsWritten, noRetiredGlyph } from '../ten-mono.mjs'

const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const sheetOpen = () => { const s = document.getElementById('sheet'); return !!s && s.classList.contains('open') }
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const has = (sel, re, what) => async (page) => page.evaluate(({ sel, re, what }) => {
  const el = document.querySelector(sel)
  if (!el) return `${what}: ${sel} is missing`
  const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ')
  return new RegExp(re, 'i').test(t) ? true : `${what}: ${sel} reads ${JSON.stringify(t.slice(0, 140))}`
}, { sel, re, what })
/* tap until the page answers: a list that re-renders under the first tap
   hands it to a detached node */
async function tapUntil(page, sel, done, tries = 4) {
  for (let i = 0; i < tries; i++) {
    await page.locator(sel).first().click({ timeout: 5000 }).catch(() => {})
    if (await page.waitForFunction(done, null, { timeout: 2000 }).then(() => true, () => false)) return true
    await page.waitForTimeout(300)
  }
  return false
}

/* ------------------------------------------------------ SCHEDULE & PLAN */
const toSchedule = async (page) => {
  await page.evaluate(() => { window._schedFrom = null; window.switchView('schedule') })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-schedule')
  await page.waitForTimeout(1200)
}
const SCHEDULE = [
  { family: 'schedule', id: 'populated', variant: 'member', title: 'Schedule · my plans, a plan I am tagged in, the crew’s plans',
    drive: toSchedule, expect: { view: 'view-schedule', minText: 80 },
    /* TEN / W6 · AW2-06: the weekday heads and the back link are agate, never mono; the dates stay a column */
    check: all(has('#view-schedule', 'Mesquite Wash|Saguaro Flats|Papago', 'a planned course'),
      notMono(['#calGrid .calhd', '#view-schedule .backlink'], ['#calGrid .calhd', '#view-schedule .backlink']),
      noRetiredGlyph()) },
  { family: 'schedule', id: 'empty', variant: 'member', world: { flags: { scheduleEmpty: true } }, title: 'Schedule · nothing planned',
    drive: toSchedule, expect: { view: 'view-schedule' } },
  { family: 'schedule', id: 'plan-sheet', variant: 'member', fullPage: false, title: 'A plan · Blake’s Saturday at Mesquite Wash (the round object)',
    drive: async (page) => {
      await toSchedule(page)
      await page.evaluate((id) => window.openRoundSheet(id), PLAN.taggedMe)
      await until(page, () => { const s = document.getElementById('sheet'); return s.classList.contains('open') && !/Loading/.test(document.getElementById('shSub').textContent) }, null, 10000)
      await page.waitForTimeout(600)
    },
    expect: { view: 'view-schedule', sheet: true },
    check: has('#sheet', 'Mesquite Wash', 'the plan’s course') },
  { family: 'schedule', id: 'plan-landing', variant: 'signed_out', url: `/?plan=${SHARE.plan}`, title: 'The /?plan= landing a recipient opens',
    settle: async (page) => { await page.waitForSelector('#shareView', { timeout: 15000 }); await until(page, () => !/Opening the card/.test((document.getElementById('svCard') || {}).textContent || ''), null, 15000); await page.waitForTimeout(400) },
    expect: { overlay: true, selectors: { '#svCard': 'visible' } },
    check: async (page) => page.evaluate(() => /This link is dead/.test(document.getElementById('svCard').innerText) ? 'the plan link reads dead' : true) },
]

/* -------------------------------------------------------------- WIZARD */
/* the Pro of a league still in setup lands in the wizard on boot */
const wizAt = async (page, step) => page.waitForFunction((step) => {
  const on = document.querySelector('.wizstep.on'); return !!on && +on.dataset.step === step
}, step, { timeout: 8000 })
const WIZARD = [
  { family: 'wizard', id: 'step-1-league', variant: 'pro_setup', title: 'Wizard · step 1 of 3, the league',
    drive: async (page) => { await wizAt(page, 0); await page.waitForTimeout(500) },
    expect: { view: 'view-wizard', selectors: { '#wizStepName': 'text:Step 1 of 3', '#wizNext': 'visible' } },
    /* TEN / W6 · delta G6: the Pro row is a card, and "THE PRO" sat flush on
       its right border (3324ae89 took the tag's own inset for Golfers' slats) */
    check: all(async (page) => page.evaluate(() => {
      const row = document.getElementById('commishChip'), tag = row && row.querySelector('.ptag'), mk = row && row.querySelector('.pmk')
      if (!row || !tag || !mk) return 'the Pro row is missing'
      const r = row.getBoundingClientRect(), t = tag.getBoundingClientRect(), m = mk.getBoundingClientRect()
      const right = Math.round(r.right - t.right), left = Math.round(m.left - r.left)
      return right >= 8 && left >= 8 ? true : `the Pro row's content touches its border: tag ${right}px from the right, marker ${left}px from the left`
    }),
    /* TEN / W6 · AW2-08: the Pro's marker is drawn (the saguaro floor), never ◆ */
    async (page) => page.evaluate(() => document.querySelector('#commishChip .pmk svg') ? true : 'the Pro row draws no marker'),
    noRetiredGlyph()) },
  { family: 'wizard', id: 'step-2-rules', variant: 'pro_setup', title: 'Wizard · step 2 of 3, the rules',
    drive: async (page) => { await wizAt(page, 0); await click(page, '#wizNext'); await wizAt(page, 1); await page.waitForTimeout(500) },
    expect: { view: 'view-wizard', selectors: { '#wizStepName': 'text:Step 2 of 3' } } },
  /* the help, expanded through its own control (F14: an honest 44px target) */
  { family: 'wizard', id: 'step-2-help-open', variant: 'pro_setup', title: 'Wizard · step 2 with the first .ibtn help expanded',
    drive: async (page) => {
      await wizAt(page, 0); await click(page, '#wizNext'); await wizAt(page, 1)
      await click(page, '.wizstep.on .ibtn')
      await until(page, () => [...document.querySelectorAll('.wizstep.on .ihelp')].some((h) => h.offsetParent !== null && h.getBoundingClientRect().height > 0))
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-wizard' },
    /* the HIT region, not the glyph's box: F14 draws an 18px glyph with a
       44x44 ::after, so probe the points 21px out from the centre */
    check: async (page) => page.evaluate(() => {
      const b = document.querySelector('.wizstep.on .ibtn'); const r = b.getBoundingClientRect()
      const open = [...document.querySelectorAll('.wizstep.on .ihelp')].filter((h) => h.offsetParent !== null)
      if (!open.length) return 'no help is expanded'
      if (b.getAttribute('aria-expanded') !== 'true') return 'the help button does not say it is expanded'
      const cx = r.x + r.width / 2, cy = r.y + r.height / 2
      const miss = [[-21, 0], [21, 0], [0, -21], [0, 21]].filter(([dx, dy]) => { const e = document.elementFromPoint(cx + dx, cy + dy); return !(e && e.closest('.ibtn') === b) })
      return miss.length ? `the help's hit region misses ${miss.length} of 4 points 21px from its centre (glyph ${Math.round(r.width)}x${Math.round(r.height)})` : true
    }) },
  /* W5 · the dials are three groups now (the scoring, the money, the
     calendar), each opened by its own head; one "Customize" opened all nine
     at once. Every dial is opened here, through the heads a Pro presses (a
     group the page already opened stays open). */
  { family: 'wizard', id: 'step-2-dials', variant: 'pro_setup', title: 'Wizard · step 2 with every dial group open',
    drive: async (page) => {
      await wizAt(page, 0); await click(page, '#wizNext'); await wizAt(page, 1)
      for (const g of ['wizGrpScoring', 'wizGrpMoney', 'wizGrpCalendar']) {
        if (await page.evaluate((g) => document.querySelector(`#${g} .wizgrp-b`).hidden, g)) await click(page, `#${g} .wizgrp-h`)
      }
      await until(page, () => [...document.querySelectorAll('#wizDials .wizgrp-b')].every((b) => !b.hidden))
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-wizard', selectors: { '#wizDials': 'visible', '#capVal': 'visible', '#stakeVal': 'visible', '#lenVal': 'visible' } },
    /* TEN / W6 · delta G6: a dial's value is one figure; at 375 and 402 the
       narrowed column broke it ("Best / 4", "2 / / mo") */
    check: all(async (page) => page.evaluate(() => {
      const broken = [...document.querySelectorAll('#wizDials .setrow .val')].filter((v) => v.offsetParent !== null)
        .filter((v) => { const cs = getComputedStyle(v), lh = parseFloat(cs.lineHeight) || parseFloat(cs.fontSize) * 1.25; return v.getBoundingClientRect().height > lh * 1.5 })
        .map((v) => JSON.stringify(v.textContent.trim()))
      return broken.length ? `a dial value breaks across lines: ${broken.join(', ')}` : true
    }),
    /* TEN / W6 · AW2-15: the pace question is a sentence, in sentence case (§1.3) */
    readsAsWritten([['#wizPaceK', 'How often will most of you play?']])) },
  { family: 'wizard', id: 'step-3-review', variant: 'pro_setup', title: 'Wizard · step 3 of 3, review and lock',
    drive: async (page) => {
      await wizAt(page, 0); await click(page, '#wizNext'); await wizAt(page, 1)
      await click(page, '#wizFastPath'); await wizAt(page, 2); await page.waitForTimeout(600)
    },
    expect: { view: 'view-wizard', selectors: { '#wizStepName': 'text:Step 3 of 3' } } },
]

/* --------------------------------------------- COURSES & THE COURSE CARD */
/* the course books live on You (#youCourses); a row's tap makes it the lead
   and draws its card */
const toCourses = async (page) => {
  await page.locator('.tab[data-v="stats"]:visible, .navitem[data-v="stats"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-stats')
  /* W2 (f46086b4) put the full book behind You's "Your courses" door: a golfer
     opens it, so the state taps its summary (the card states' element
     screenshot of #youCourses timed out inside the closed <details>) */
  if (await page.evaluate(() => { const d = document.getElementById('youCoursesDoor'); return !!d && !d.open })) {
    await page.locator('#youCoursesDoor > summary').click({ timeout: 8000 })
  }
  await until(page, () => document.querySelectorAll('#youCourses [data-cslead]').length > 0, null, 12000)
  await page.waitForTimeout(500)
}
const courseCard = (id, courseId, title, want) => ({
  family: 'courses', id, variant: 'member', title, shot: '#youCourses',
  drive: async (page) => {
    await toCourses(page)
    const sel = `#youCourses [data-cslead="${courseId}"]`
    await tapUntil(page, sel, () => true, 1)
    await until(page, (cid) => String(window.CS_COURSE_LEAD) === String(cid), courseId, 6000).catch(() => {})
    await page.waitForTimeout(700)
  },
  expect: { view: 'view-stats', selectors: { '#youCourses': 'visible' } },
  check: all(async (page) => page.evaluate((cid) => String(window.CS_COURSE_LEAD) === String(cid) ? true : `the lead course is ${window.CS_COURSE_LEAD}, expected ${cid}`, courseId),
    has('#youCourses', want, 'the course card')),
})
const COURSES = [
  { family: 'courses', id: 'books', variant: 'member', title: 'Courses · the course books on You',
    drive: toCourses, expect: { view: 'view-stats', selectors: { '#youCourses': 'visible' } },
    /* TEN / W6 · craft, round 2: at 1280 the lead's left column was 204px and
       the tee <select> clipped its value ("Blue — 70.1 / 121 · 6,4"). The
       select's whole value (plus its arrow) fits at every width. */
    check: async (page) => page.evaluate(() => {
      const s = document.querySelector('#youCourses select[data-cstee]'); if (!s) return true
      const cs = getComputedStyle(s), c = document.createElement('canvas').getContext('2d')
      c.font = `${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`
      const need = c.measureText(s.options[s.selectedIndex].textContent).width + parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight) + 24
      const has = s.getBoundingClientRect().width
      return need <= has + 1 ? true : `the tee select clips its value: it needs ${Math.round(need)}px and has ${Math.round(has)}`
    }) },
  courseCard('card-18', COURSE.wash, 'Course card · an 18-hole card (Mesquite Wash, Black)', 'Mesquite Wash'),
  courseCard('card-9-no-yardage', COURSE.nine, 'Course card · the nine with no yardage (Dry Creek Nine)', 'Dry Creek'),
  courseCard('card-long-tee', COURSE.long, 'Course card · the longest course and tee name', 'Whispering Fixture Pines'),
]

/* ------------------------------------------------ SETTINGS & THE SHEETS */
const openHub = async (page) => {
  await page.locator('.tab[data-v="stats"]:visible, .navitem[data-v="stats"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-stats')
  await page.waitForTimeout(400)
  await tapUntil(page, '#youProfile', () => document.getElementById('sheet').classList.contains('open') && /Card & settings/.test(document.getElementById('shTitle').textContent))
  await page.waitForTimeout(500)
}
const SETTINGS = [
  { family: 'settings', id: 'card', variant: 'member', fullPage: false, title: 'Card & settings · Your card',
    drive: openHub, expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phName': 'visible', '#phSave': 'visible' } },
    /* TEN / W6 · AW2-06: a row's label is agateS, never mono; a league's code stays mono */
    check: all(notMono(['#phPaneCard .byrow > span'], ['#phPaneCard .byrow > span']), noRetiredGlyph()) },
  { family: 'settings', id: 'settings', variant: 'member', fullPage: false, title: 'Card & settings · Settings (notifications, theme, sign out)',
    drive: async (page) => { await openHub(page); await click(page, '#phSeg [data-ph="settings"]'); await until(page, () => document.getElementById('phPaneSettings') && document.getElementById('phPaneSettings').offsetParent !== null); await page.waitForTimeout(400) },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phTheme': 'visible', '#phOut': 'visible' } },
    check: notMono(['#phPaneSettings .byrow > span'], ['#phPaneSettings .byrow > span']) },
  /* a destructive confirmation, opened and NOT confirmed */
  { family: 'settings', id: 'delete-confirm', variant: 'member', fullPage: false, title: 'Card & settings · Delete my account, the confirmation (not confirmed)',
    drive: async (page) => {
      await openHub(page); await click(page, '#phSeg [data-ph="settings"]')
      await until(page, () => document.getElementById('phDelete') && document.getElementById('phDelete').offsetParent !== null)
      await click(page, '#phDelete')
      await until(page, () => { const c = document.getElementById('phDelConfirm'); return !!c && c.offsetParent !== null })
      await page.locator('#phDelYes').scrollIntoViewIfNeeded().catch(() => {})
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phDelYes': 'visible', '#phDelNo': 'visible' } },
    /* TEN / W6 · critique A2 (P1, WCAG 2.4.3 / 4.1.3): focus goes into the
       confirmation, which is a named group read as it opens; Not now returns
       focus to the opener (the check re-opens it for the capture) */
    check: async (page) => {
      const open = await page.evaluate(() => {
        const g = document.getElementById('phDelConfirm'), a = document.activeElement
        return { focus: a && a.id, role: g.getAttribute('role'), named: g.getAttribute('aria-labelledby'), described: document.getElementById('phDelYes').getAttribute('aria-describedby') }
      })
      if (open.focus !== 'phDelWhat' || open.role !== 'group' || open.named !== 'phDelete' || open.described !== 'phDelWhat') return 'the confirmation does not take focus or say what it does: ' + JSON.stringify(open)
      await click(page, '#phDelNo')
      const back = await page.evaluate(() => document.activeElement && document.activeElement.id)
      await click(page, '#phDelete')
      await until(page, () => { const c = document.getElementById('phDelConfirm'); return !!c && c.offsetParent !== null })
      await page.locator('#phDelYes').scrollIntoViewIfNeeded().catch(() => {})
      return back === 'phDelete' ? true : 'Not now did not return focus to the opener: ' + back
    } },
  /* NOT CAPTURED: the composer's own confirmation ("Post as even par?") is
     reachable only in hole-by-hole mode, and #postMode is display:none --
     the grid is dormant by decision (D34). Not a defect; no path to it. */
]

/* ------------------------------------------------ GET / SUPPORT / LEGAL */
const staticPage = (id, url, title, want) => ({
  family: 'static', id, variant: 'signed_out', url, title,
  settle: async (page) => { await page.waitForLoadState('load'); await page.evaluate(() => document.fonts && document.fonts.ready).catch(() => {}); await page.waitForTimeout(500) },
  expect: { overlay: true },
  check: async (page) => page.evaluate((want) => {
    const t = document.body.innerText.replace(/\s+/g, ' ')
    if (!new RegExp(want, 'i').test(t)) return `the page does not read /${want}/: ${JSON.stringify(t.slice(0, 120))}`
    if (document.getElementById('onboard')) return 'the app shell rendered instead of the page'
    /* TEN / W6 · AW2-17: the browser's chrome takes the page's own --bg0, as the app's does */
    const tc = document.querySelector('meta[name="theme-color"]'), light = document.documentElement.dataset.theme === 'light'
    if (!tc) return 'the page carries no theme-color'
    return tc.content.toUpperCase() === (light ? '#F4F1E9' : '#0F1A15') ? true : `theme-color is ${tc.content} on the ${light ? 'light' : 'dark'} printing`
  }, want),
})
const STATIC = [
  staticPage('get', '/get.html', 'get.html · the install page', 'Cup Season'),
  staticPage('support', '/support.html', 'support.html', 'Cup Season'),
  staticPage('legal', '/legal.html', 'legal.html · terms and privacy', 'Privacy'),
]

/* ---------------------------------------------------------------- DESK */
/* the web's own desk shape at 1280/1600: sidebar + wide body */
const deskCheck = async (page) => page.evaluate(() => {
  const side = [...document.querySelectorAll('.navitem')].filter((n) => n.offsetParent !== null)
  return side.length >= 3 ? true : 'the desk sidebar is not showing'
})
/* TEN / W6 · AW2 (P3): the rail scrolls in its own height and says so at rest
   — its foot fades while there is more below (data-more), and not at its end.
   At 1000px tall the member's rail just fits, so the check reads it at 800
   (a laptop screen) and puts the viewport back before the capture. */
const deskRailEdge = async (page) => {
  const vp = page.viewportSize()
  await page.setViewportSize({ width: vp.width, height: 800 }); await page.waitForTimeout(300)
  const r = await page.evaluate(async () => {
    const s = document.querySelector('aside.side'), frame = () => new Promise((res) => requestAnimationFrame(() => requestAnimationFrame(res)))
    const over = s.scrollHeight > s.clientHeight + 2, cs = getComputedStyle(s)
    const atRest = s.hasAttribute('data-more'), masked = (cs.webkitMaskImage || cs.maskImage || 'none') !== 'none'
    s.scrollTop = s.scrollHeight; await frame()
    const atEnd = s.hasAttribute('data-more')
    s.scrollTop = 0; await frame()
    return { over, atRest, masked, atEnd, back: s.hasAttribute('data-more') }
  })
  await page.setViewportSize(vp); await page.waitForTimeout(300)
  if (!r.over) return `the rail does not overflow at ${vp.width}×800, so its edge cannot be read`
  return r.atRest && r.masked && !r.atEnd && r.back ? true : `the rail's edge at ${vp.width}×800: ${JSON.stringify(r)}`
}
const DESK = [
  { family: 'desk', id: 'home', variant: 'member', desk: true, title: 'The desk · Home', expect: { view: 'view-home' },
    check: async (page) => { const a = await deskCheck(page); return a !== true ? a : deskRailEdge(page) } },
  { family: 'desk', id: 'season', variant: 'member', desk: true, title: 'The desk · the season',
    drive: async (page) => { await click(page, '.navitem[data-v="hub"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-hub'); await page.waitForTimeout(900) },
    expect: { view: 'view-hub' }, check: deskCheck },
  { family: 'desk', id: 'compete', variant: 'member', desk: true, title: 'The desk · Compete',
    drive: async (page) => { await click(page, '.navitem[data-v="compete"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-compete'); await page.waitForTimeout(900) },
    expect: { view: 'view-compete' }, check: deskCheck },
  { family: 'desk', id: 'golfers', variant: 'member', desk: true, title: 'The desk · Golfers',
    drive: async (page) => { await click(page, '.navitem[data-v="golfers"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-golfers'); await page.waitForTimeout(900) },
    expect: { view: 'view-golfers' }, check: deskCheck },
  { family: 'desk', id: 'you', variant: 'member', desk: true, title: 'The desk · You',
    drive: async (page) => { await click(page, '.navitem[data-v="stats"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-stats'); await page.waitForTimeout(900) },
    expect: { view: 'view-stats' }, check: deskCheck },
]

/* ------------------------------------------------------------ THE DRAW */
/* TEN / W6 · DX2 TP-16 · the draw room of a real league in the draw, as its
   Pro: the synthetic world's North Grove is in its "draft" phase (data only,
   as DX2's draft/formation state set it), then the page's own router. The
   room's dusk ground takes the gutter on all three sides (UI_SYSTEM §3.4):
   its last line of text stands at least a gutter above the ground's foot. */
const DRAW = [
  { family: 'draft', id: 'formation', variant: 'pro', title: 'The draw room of a real league in the draw, as its Pro',
    prepare: async (W) => { const L1 = W.ids.lid(1); for (const l of W.tables.leagues || []) if (l.id === L1) l.phase = 'draft' },
    drive: async (page) => { await page.evaluate(() => window.switchView('draft')); await until(page, () => { const c = document.querySelector('#view-draft #clock'); return !!c && c.offsetParent !== null }); await page.waitForTimeout(800) },
    expect: { view: 'view-draft', selectors: { '#view-draft #clock': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const room = document.getElementById('view-draft'), foot = room.getBoundingClientRect().bottom
      let low = -Infinity
      const w = document.createTreeWalker(room, NodeFilter.SHOW_TEXT)
      for (let t = w.nextNode(); t; t = w.nextNode()) {
        if (!t.textContent.trim() || !t.parentElement || getComputedStyle(t.parentElement).visibility === 'hidden') continue
        const rg = document.createRange(); rg.selectNodeContents(t)
        for (const rc of rg.getClientRects()) if (rc.width > 0 && rc.height > 0) low = Math.max(low, rc.bottom)
      }
      if (low === -Infinity) return 'the draw room draws no text'
      const gutter = parseFloat(getComputedStyle(document.documentElement).getPropertyValue('--gutter')) || 20
      const inset = Math.round((foot - low) * 10) / 10
      return inset >= gutter - 0.5 ? true : `the draw room's last line sits ${inset}px above its ground's foot (the gutter is ${gutter})`
    }) },
]

export default [...SCHEDULE, ...WIZARD, ...COURSES, ...SETTINGS, ...STATIC, ...DESK, ...DRAW]
