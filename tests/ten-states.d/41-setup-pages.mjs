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
import { notMono, readsAsWritten, noRetiredGlyph, armedDelete, standsDown, deskMenuIs, isSystemSegment, ariaWellFormed, tertiaryDoor, destMarked } from '../ten-mono.mjs'

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

/* TEN / W6 · DX2 TP-22 · a row never gets a container (UI_SYSTEM §3.1): no
   fill, no border on its sides or foot, no corner. The rule between rows is
   its only line. Every drawn element under `sel` must be a row. */
const isRow = (sel, what) => async (page) => page.evaluate(({ sel, what }) => {
  const rows = [...document.querySelectorAll(sel)].filter((el) => { const r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0 })
  if (!rows.length) return `${what}: no ${sel} is drawn`
  const alpha = (c) => { c = c || ''; const sl = /\/\s*([0-9.]+)\s*\)\s*$/.exec(c); if (sl) return parseFloat(sl[1]); const m = /rgba?\(([^)]+)\)/.exec(c); if (!m) return /^color\(/.test(c) ? 1 : 0; const v = m[1].split(','); return v[3] !== undefined ? parseFloat(v[3]) : 1 }
  for (const el of rows) {
    const cs = getComputedStyle(el), bad = []
    if (alpha(cs.backgroundColor) > 0) bad.push(`a ${cs.backgroundColor} fill`)
    if (['Left', 'Right', 'Bottom'].some((k) => (parseFloat(cs['border' + k + 'Width']) || 0) > 0)) bad.push('a border on its sides or foot')
    if ((parseFloat(cs.borderTopLeftRadius) || 0) > 0) bad.push(`a ${cs.borderTopLeftRadius} corner`)
    if (bad.length) return `${what} is a card, not a row (§3.1): ${bad.join(', ')}`
  }
  return true
}, { sel, what })

/* ------------------------------------------------------ SCHEDULE & PLAN */
const toSchedule = async (page) => {
  await page.evaluate(() => { window._schedFrom = null; window.switchView('schedule') })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-schedule')
  await page.waitForTimeout(1200)
}
/* TEN / W8 · W7-039 [A2-schedule-2] · ONE primary in a plan's sheet (§7.1, §16A.5): a golfer who owes an answer (asked, or maybe) has 'I'm in' as the filled action and
   'Tee it up' as the tertiary link beneath the set (a 2px rule, 44 tall); answered (in), or the host, 'Tee it up' is the filled primary and no 'I'm in' is filled act */
const planSheetPrimary = (owes) => async (page) => page.evaluate((owes) => {
  const set = document.querySelector('.rsvpset'), tee = document.getElementById('rtTeeUp')
  if (!set || !tee) return 'the sheet has no RSVP set or no Tee it up'
  const probe = document.createElement('i'); probe.style.color = 'var(--act)'; document.body.appendChild(probe); const act = getComputedStyle(probe).color; probe.remove()
  const fill = getComputedStyle(set.querySelector('[data-rsvp="in"]')).backgroundColor, teeBtn = tee.classList.contains('btn')
  if (set.classList.contains('owes') !== owes) return owes ? 'a golfer who owes an answer does not get the answer as the primary' : 'an answered golfer still has the answer as the primary'
  if (owes) {
    if (fill !== act) return `I'm in is not the primary (fill ${fill}, act ${act})`
    const cs = getComputedStyle(tee)
    if (teeBtn) return 'Tee it up is still a full-width filled button beneath the unanswered invitation'
    return /underline/.test(cs.textDecorationLine) && parseFloat(cs.textDecorationThickness) === 2 && tee.getBoundingClientRect().height >= 43.5 ? true : 'Tee it up is not the tertiary link (a 2px rule, 44 tall)'
  }
  if (!teeBtn) return 'Tee it up is not the primary once the golfer is in'
  return fill === act ? "I'm in is filled act as well as Tee it up: two primaries" : true
}, owes)
const SCHEDULE = [
  { family: 'schedule', id: 'populated', variant: 'member', title: 'Schedule · my plans, a plan I am tagged in, the crew’s plans',
    drive: toSchedule, expect: { view: 'view-schedule', minText: 80 },
    /* TEN / W6 · AW2-06: the weekday heads and the back link are agate, never mono; the dates stay a column */
    check: all(has('#view-schedule', 'Mesquite Wash|Saguaro Flats|Papago', 'a planned course'),
      notMono(['#calGrid .calhd', '#view-schedule .backlink'], ['#calGrid .calhd', '#view-schedule .backlink']),
      noRetiredGlyph()) },
  { family: 'schedule', id: 'empty', variant: 'member', world: { flags: { scheduleEmpty: true } }, title: 'Schedule · nothing planned',
    /* TEN / W8 · W7-009: the empty schedule and its own door carry planning, so the sidebar's "Plan one" stands down */
    drive: toSchedule, expect: { view: 'view-schedule' }, check: standsDown(['#sideMe [data-mego="plan_one"]']) },
  /* TEN / W8 · W7-040 [A2-schedule-3] · a failed schedule read is never an empty schedule (§13.3; the C-10 rule: a failed read is not an empty one). With nothing
     to show the page says the schedule did not load and offers the retry — not 'Nothing on the schedule yet' and 'Put a round up' over a read it never got;
     the page's one primary (#calDeclare) stays */
  { family: 'schedule', id: 'failed', variant: 'member', world: { errors: { rpc: { my_schedule: { __error: 'fixture: the schedule read failed', status: 503, code: 'XX000' } } } },
    title: 'Schedule · the read failed (the words and the retry, never an empty schedule)',
    drive: async (page) => { await toSchedule(page); await until(page, () => !!document.getElementById('schRetry'), null, 20000).catch(() => {}); await page.waitForTimeout(400) },
    expectConsole: [/status of 503/],
    expect: { view: 'view-schedule', selectors: { '#schRetry': 'visible', '#calDeclare': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const t = (document.getElementById('schNext') || {}).innerText || ''
      if (/Nothing on the schedule yet|Put a round up|Nothing of yours on the schedule/i.test(t)) return `a failed read reads as an empty schedule: ${JSON.stringify(t.slice(0, 80))}`
      if (!/The schedule didn.t load/i.test(t)) return `the lead does not say the read failed: ${JSON.stringify(t.slice(0, 80))}`
      const primaries = [...document.querySelectorAll('#view-schedule .btn')].filter((b) => b.getBoundingClientRect().width > 0)
      return primaries.length === 1 && primaries[0].id === 'calDeclare' ? true : `the page has ${primaries.length} filled buttons, not #calDeclare alone`
    }) },
  /* ...and with rows on screen, a refresh that fails keeps them and says so once, above 'Coming up' */
  { family: 'schedule', id: 'refresh-failed', variant: 'member', fullPage: false, title: 'Schedule · a refresh failed (the plans stay, one line says so above Coming up)',
    drive: async (page, ctx) => {
      await toSchedule(page)
      await page.evaluate(() => { window.__w8 = { rows: document.querySelectorAll('#calWatch .schrow').length, lead: (document.getElementById('schNext') || {}).innerText || '' } })
      ctx.world.errors.rpc.my_schedule = { __error: 'fixture: the schedule read failed', status: 503, code: 'XX000' }
      await page.evaluate(() => Promise.all([window.loadSchedule(), window.loadWatchList()]))
      await until(page, () => !!document.getElementById('schFail'), null, 15000).catch(() => {})
      await page.evaluate(() => (document.getElementById('schFail') || document.getElementById('calWatchHead')).scrollIntoView({ block: 'center' }))
      await page.waitForTimeout(500)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-schedule', selectors: { '#schFail': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const w = window.__w8, rows = document.querySelectorAll('#calWatch .schrow').length, line = document.getElementById('schFail')
      if (!w.rows) return 'the state had no plans to keep'
      if (rows !== w.rows) return `the list changed from ${w.rows} to ${rows} plans when the refresh failed`
      if (((document.getElementById('schNext') || {}).innerText || '') !== w.lead) return 'the lead changed when the refresh failed'
      if (line.nextElementSibling !== document.getElementById('calWatchHead')) return 'the line is not directly above Coming up'
      return /The schedule didn.t refresh/.test(line.textContent) && line.getAttribute('role') === 'status' && document.getElementById('schRetry') ? true : `the line reads ${JSON.stringify(line.textContent)}`
    }) },
  { family: 'schedule', id: 'plan-sheet', variant: 'member', fullPage: false, title: 'A plan · Blake’s Saturday at Mesquite Wash (the round object)',
    drive: async (page) => {
      await toSchedule(page)
      await page.evaluate((id) => window.openRoundSheet(id), PLAN.taggedMe)
      await until(page, () => { const s = document.getElementById('sheet'); return s.classList.contains('open') && !/Loading/.test(document.getElementById('shSub').textContent) }, null, 10000)
      await page.waitForTimeout(600)
    },
    expect: { view: 'view-schedule', sheet: true },
    check: all(has('#sheet', 'Mesquite Wash', 'the plan’s course'), planSheetPrimary(true),
      /* TEN / W8 · W7-035 [B2-schedule-5]: the viewer's own seat reads 'You' in Who's in, as Coming up prints the same person (§9.1); every other seat keeps its name */
      async (page) => page.evaluate(() => {
        const seats = [...document.querySelectorAll('.rs-who .check')].map((r) => r.querySelector('.tt b').innerText.replace(/\s+/g, ' ').trim())
        const yous = seats.filter((t) => /^You\b/.test(t))
        if (yous.length !== 1) return `Who's in has ${yous.length} seats reading You: ${JSON.stringify(seats)}`
        return seats.some((t) => /Avery/.test(t)) ? `the viewer is also named: ${JSON.stringify(seats)}` : seats.some((t) => /Blake/.test(t)) ? true : `the host is not named: ${JSON.stringify(seats)}`
      })) },
  /* ...answered ('I'm in' tapped through the app's own set_round_rsvp), 'Tee it up' is the primary again and 'I'm in' is the chosen chip, not a second primary */
  { family: 'schedule', id: 'plan-sheet-in', variant: 'member', fullPage: false, title: 'A plan · Blake’s Saturday, after I’m in (Tee it up is the primary)',
    drive: async (page) => {
      await toSchedule(page)
      await page.evaluate((id) => window.openRoundSheet(id), PLAN.taggedMe)
      await until(page, () => { const s = document.getElementById('sheet'); return s.classList.contains('open') && !!document.querySelector('.rsvpset.owes') }, null, 10000)
      await click(page, '.rsvpset [data-rsvp="in"]')
      await until(page, () => { const set = document.querySelector('.rsvpset'); return !!set && !set.classList.contains('owes') && !!set.querySelector('.rbtn.on.in') }, null, 10000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-schedule', sheet: true, selectors: { '#rtTeeUp': 'visible' } },
    check: all(planSheetPrimary(false), async (page) => page.evaluate(() => /^You\b/.test(document.querySelector('.rs-who .check .tt b').innerText) || [...document.querySelectorAll('.rs-who .check')].some((r) => /^You\b/.test(r.innerText) && /In/i.test(r.innerText)) ? true : 'the viewer\'s seat does not read You · In')) },
  /* TEN / W8 · W7-049 [B2-schedule-3] · the host's own plan: Tee it up is the primary, the two harmless acts are 44 boxes, and 'Cancel round' is one named, quiet, ARMED
     tertiary link beneath them: the first tap asks ('Sure? Cancel for everyone') and cancels nothing */
  { family: 'schedule', id: 'plan-sheet-host', variant: 'member', fullPage: false, title: 'A plan · Avery’s own Wednesday, Cancel round tapped once (armed, not confirmed)',
    drive: async (page) => {
      await toSchedule(page)
      await page.evaluate((id) => window.openRoundSheet(id), PLAN.mine)
      await until(page, () => { const s = document.getElementById('sheet'); return s.classList.contains('open') && !!document.getElementById('rrScratch') }, null, 10000)
      await page.locator('#rrScratch').scrollIntoViewIfNeeded()
      const rest = await tertiaryDoor('#rrScratch')(page)   /* at rest: the armed link is neg by design, so the shape is read before the tap */
      await page.evaluate((r) => { window.__w8 = { rest: r } }, rest)
      await click(page, '#rrScratch'); await page.waitForTimeout(400)
    },
    expect: { view: 'view-schedule', sheet: true, selectors: { '#rrScratch': 'text:^Sure\\? Cancel for everyone$' } },
    check: all(planSheetPrimary(false), async (page) => page.evaluate(() => window.__w8.rest), async (page) => page.evaluate(() => {
      const b = document.getElementById('rrScratch'), boxes = [...document.querySelectorAll('.managebar2 .mbtn2')]
      if (!b.classList.contains('is-armed')) return 'the first tap did not arm Cancel round'
      if (!document.getElementById('sheet').classList.contains('open') || !document.getElementById('rrScratch')) return 'the first tap cancelled the round'
      if (boxes.length !== 2 || boxes.some((x) => x.getBoundingClientRect().height < 43.5)) return `the manage bar has ${boxes.length} boxes, some under 44px`
      return b.getBoundingClientRect().top >= boxes[0].getBoundingClientRect().bottom - 1 ? true : 'Cancel round is not apart from (beneath) the two harmless acts'
    })) },
  /* TEN / W8 · W7-079 [X03] · confirmed from the plan sheet, the toast says what the list's cancel says ('Round cancelled', not 'Round scratched'), and the sheet closes */
  { family: 'schedule', id: 'plan-sheet-cancelled', variant: 'member', fullPage: false, title: 'A plan · Avery’s own Wednesday, Cancel round confirmed from the sheet (the toast)',
    drive: async (page) => {
      await toSchedule(page)
      await page.evaluate((id) => window.openRoundSheet(id), PLAN.mine)
      await until(page, () => { const s = document.getElementById('sheet'); return s.classList.contains('open') && !!document.getElementById('rrScratch') }, null, 10000)
      await page.locator('#rrScratch').scrollIntoViewIfNeeded()
      await click(page, '#rrScratch'); await page.waitForTimeout(300)
      await click(page, '#rrScratch')
      await until(page, () => document.getElementById('toast').classList.contains('show'), null, 6000)
    },
    expect: { view: 'view-schedule', selectors: { '#toast.show': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const t = document.getElementById('toast').textContent.trim()
      if (t !== 'Round cancelled') return `the toast reads ${JSON.stringify(t)}, not the list's 'Round cancelled'`
      return document.getElementById('sheet').classList.contains('open') ? 'the sheet stayed open after the round was cancelled' : true
    }) },
  /* ...and in the schedule's own list: your plan's 'Cancel round' is the tertiary link apart from Invite, and its first tap only asks */
  { family: 'schedule', id: 'cancel-armed', variant: 'member', title: 'Schedule · Cancel round on my own plan tapped once (armed, not confirmed)',
    drive: async (page) => {
      await toSchedule(page)
      await page.locator('[data-scratch]').first().scrollIntoViewIfNeeded()
      await click(page, '[data-scratch]'); await page.waitForTimeout(400)
    },
    expect: { view: 'view-schedule', selectors: { '[data-scratch]': 'text:^Sure\\? Cancel for everyone$' } },
    check: all(async (page) => page.evaluate(() => { const b = document.querySelector('[data-scratch]'), row = b.closest('.schrow'); return b.classList.contains('is-armed') && row ? true : 'the first tap did not arm the cancel' }),
      async (page) => page.evaluate(() => {
        const b = document.querySelector('[data-scratch]'), inv = b.parentElement.querySelector('[data-retag]')
        if (getComputedStyle(b).textDecorationLine.indexOf('underline') < 0 || parseFloat(getComputedStyle(b).textDecorationThickness) !== 2) return 'the row cancel is not the tertiary link'
        return b.getBoundingClientRect().height >= 43.5 && inv && !inv.classList.contains('lrcasual') ? true : 'the cancel is not 44 tall, or is not a different tier from Invite'
      })) },
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
/* TEN / W8 · W7-170 [B2-wizard-1] · the portrait's Season row is the season's own week ticks: one 4x8 tick per week (not month blocks with the Final as a fourth block), the last
   four in ember when the Cup Final is on and the rest mut, so the Final sits inside the season it ends */
const seasonBand = async (page) => page.evaluate(() => {
  const row = [...document.querySelectorAll('.wizp-row')].find((r) => /^Season/i.test((r.querySelector('.k') || {}).textContent || ''))
  if (!row) return 'the portrait has no Season row'
  const rects = [...row.querySelectorAll('svg rect')], weeks = Number(state.durWeeks), cup = /Cup Final/i.test(row.innerText)
  if (rects.length !== weeks) return `the Season row draws ${rects.length} blocks for a ${weeks}-week season`
  if (rects.some((r) => r.getAttribute('stroke') || r.getAttribute('width') !== '4' || r.getAttribute('height') !== '8')) return 'the Season row is not week ticks (4 x 8, no outline)'
  const ember = rects.map((r, i) => r.getAttribute('fill') === 'var(--brand)' ? i : -1).filter((i) => i >= 0)
  const want = cup ? [weeks - 4, weeks - 3, weeks - 2, weeks - 1] : []
  return JSON.stringify(ember) === JSON.stringify(want) ? true : `the ember weeks are ${JSON.stringify(ember)}, expected the last four ${JSON.stringify(want)}`
})
/* TEN / W8 · W7-165 [A2-wizard-2] · below 1100 the review is the agreement alone (the phone's WizardAgreementView): the league's name in the display-small role and the one reassurance line under the review's head,
   then the rules; the portrait card that restated the squads, endgame, buy-in and season beside them is gone. From 1100 the sticky aside names the league, so the name and the line stand down. */
const reviewAlone = async (page) => page.evaluate(() => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' }
  if (document.getElementById('wizReviewPortrait')) return 'the review still draws its own portrait card'
  const id = document.getElementById('wizRevId'), nm = document.getElementById('wizRevName'), note = document.getElementById('wizRevNote'), rules = document.getElementById('bylawsReview')
  const h2 = document.querySelector('.wizstep[data-step="2"] h2.wizhead')
  if (!id || !nm || !note || !rules || !h2) return 'the review lacks its name, its line, its rules or its head'
  const rows = [...document.querySelectorAll('#view-wizard .wizp-row')].filter(shown)
  if (innerWidth >= 1100) {
    if (shown(id)) return 'the aside names the league beside the list, and the review names it again above'
    return rows.length ? true : 'the desk\'s aside draws no portrait'
  }
  if (rows.length) return `the portrait's ${rows.length} rows are drawn beside the rules list`
  if (!shown(nm) || !shown(note)) return 'the review\'s name or reassurance line is not drawn'
  const want = (document.getElementById('setName').value || '').trim() || 'Your league'
  if (nm.textContent !== want) return `the name reads ${JSON.stringify(nm.textContent)}, not ${JSON.stringify(want)}`
  if (note.textContent !== 'Forming — nothing locks until you start it') return `the line reads ${JSON.stringify(note.textContent)}`
  const cs = getComputedStyle(nm)
  if (parseFloat(cs.fontSize) !== 24 || cs.textTransform !== 'uppercase') return `the name is ${cs.fontSize} ${cs.textTransform}, not the display-small role (24px caps)`
  if (getComputedStyle(note).textTransform !== 'none') return 'the reassurance line is set in caps, not the sentence-case phrase'
  const after = (a, b) => !!(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING)
  return after(h2, nm) && after(nm, note) && after(note, rules) ? true : 'the review does not read head, name, line, rules'
})
const WIZARD = [
  { family: 'wizard', id: 'step-1-league', variant: 'pro_setup', title: 'Wizard · step 1 of 3, the league',
    drive: async (page) => { await wizAt(page, 0); await page.waitForTimeout(500) },
    expect: { view: 'view-wizard', selectors: { '#wizStepName': 'text:Step 1 of 3', '#wizNext': 'visible' } },
    /* TEN / W6 · DX2 TP-22: the Pro row is a row, not a card whose content
       touched its sides (delta G6's inset patched the card; the card is gone) */
    check: all(destMarked('compete'), isRow('#commishChip', 'the Pro row'),   /* TEN / W8 · W7-108: the wizard is a room of COMPETE, so COMPETE stays marked */
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
    expect: { view: 'view-wizard', selectors: { '#wizStepName': 'text:Step 3 of 3' } }, check: all(seasonBand, reviewAlone) },
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
/* TEN / W8 · W7-052 [A2-courses-1] · the course record says who of yours has played it: Home's door (overlapping faces, 'Blake and Devon have played here', its gloss and
   a chevron), under 'You have played here N times', one course_page read per lead; absent, never a dash, when nobody else in the circle has (Dry Creek: only Avery's nine) */
const courseCircle = (want) => async (page) => page.evaluate((want) => {
  const door = document.querySelector('#youCourses .cs-course [data-hfcourse]')
  if (want === false) return door ? 'a course nobody else has played draws the circle door' : true
  if (!door) return 'the course record draws no door for who of yours has played it'
  const t = door.innerText.replace(/\s+/g, ' ').trim(), faces = door.querySelectorAll('.hfr-faces .face, .hfr-faces > *').length
  if (!/ (has|have) played here/.test(t) || !/See their rounds and your circle.s best/.test(t)) return `the door reads ${JSON.stringify(t)}`
  if (!faces) return 'the door has no faces'
  if (/Avery/.test(t)) return 'the viewer is named in their own circle door'
  const hist = document.querySelector('#youCourses .cs-course .cs-body-s'), r = door.getBoundingClientRect()
  return r.height >= 43.5 ? true : `the door is ${Math.round(r.height)}px tall`
}, want)
/* TEN / W8 · W7-133 [B2-courses-1] · the open course book is the LAST child of You's body: at the desk it runs the body's full width, below both columns (it ran down the left column beside a right one that
   ended at 'Your bag' ~2,500px above), and from 1280 its lead takes the course page's own two-column shape; on the phone it keeps its place in the phone's sequence, above the doors */
const courseBookWide = async (page) => page.evaluate(() => {
  const body = document.querySelector('#view-stats .youbody'), book = body && body.querySelector(':scope > .you-courses')
  if (!book) return 'the course book is not a child of the body'
  if (body.lastElementChild !== book) return 'something follows the course book in the body'
  const b = book.getBoundingClientRect(), y = body.getBoundingClientRect()
  if (innerWidth >= 960) {
    if (Math.abs(b.left - y.left) > 1 || Math.abs(b.right - y.right) > 1) return `the open book is ${Math.round(b.width)}px of a ${Math.round(y.width)}px body`
    const foot = Math.max(body.querySelector(':scope > .youmain').getBoundingClientRect().bottom, body.querySelector(':scope > .youaside').getBoundingClientRect().bottom)
    if (b.top < foot - 1) return `the book starts at ${Math.round(b.top)}px, above the columns' foot at ${Math.round(foot)}px`
    const lead = book.querySelector('.cs-course')
    if (innerWidth >= 1280 && lead && getComputedStyle(lead).gridTemplateColumns.split(' ').length !== 2) return `the lead stacks at ${Math.round(b.width)}px wide: ${getComputedStyle(lead).gridTemplateColumns}`
  } else {
    const doors = body.querySelector('.you-doors')
    if (doors && b.bottom > doors.getBoundingClientRect().top + 1) return 'on the phone the course book sits below the doors'
  }
  return true
})
const courseCard = (id, courseId, title, want, circle = true) => ({
  family: 'courses', id, variant: 'member', title, shot: '#youCourses',
  drive: async (page) => {
    await toCourses(page)
    const sel = `#youCourses [data-cslead="${courseId}"]`
    await tapUntil(page, sel, () => true, 1)
    await until(page, (cid) => String(window.CS_COURSE_LEAD) === String(cid), courseId, 6000).catch(() => {})
    await until(page, () => !!document.querySelector('#youCourses .cs-course [data-hfcourse]'), null, 4000).catch(() => {})   /* the circle read lands after the card */
    await page.waitForTimeout(700)
  },
  expect: { view: 'view-stats', selectors: { '#youCourses': 'visible' } },
  check: all(async (page) => page.evaluate((cid) => String(window.CS_COURSE_LEAD) === String(cid) ? true : `the lead course is ${window.CS_COURSE_LEAD}, expected ${cid}`, courseId),
    has('#youCourses', want, 'the course card'), courseCircle(circle)),
})
const COURSES = [
  { family: 'courses', id: 'books', variant: 'member', title: 'Courses · the course books on You',
    drive: toCourses, expect: { view: 'view-stats', selectors: { '#youCourses': 'visible' } },
    /* TEN / W6 · craft, round 2: at 1280 the lead's left column was 204px and
       the tee <select> clipped its value ("Blue — 70.1 / 121 · 6,4"). The
       select's whole value (plus its arrow) fits at every width. */
    check: all(courseBookWide, async (page) => page.evaluate(() => {
      const s = document.querySelector('#youCourses select[data-cstee]'); if (!s) return true
      const cs = getComputedStyle(s), c = document.createElement('canvas').getContext('2d')
      c.font = `${cs.fontWeight} ${cs.fontSize} ${cs.fontFamily}`
      const need = c.measureText(s.options[s.selectedIndex].textContent).width + parseFloat(cs.paddingLeft) + parseFloat(cs.paddingRight) + 24
      const has = s.getBoundingClientRect().width
      return need <= has + 1 ? true : `the tee select clips its value: it needs ${Math.round(need)}px and has ${Math.round(has)}`
    })) },
  courseCard('card-18', COURSE.wash, 'Course card · an 18-hole card (Mesquite Wash, Black)', 'Mesquite Wash'),
  courseCard('card-9-no-yardage', COURSE.nine, 'Course card · the nine with no yardage (Dry Creek Nine)', 'Dry Creek', false),
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
/* TEN / W8 · W7-042 [A2-settings-3] · what an armed card says when it is left: ONE sentence, in the status line that Save describes itself with, on the
   pane that holds the edits (a golfer on Settings is brought back to it), in view, with focus on Save */
const CARD_UNSAVED = 'You have unsaved changes. Save them, or do that again to leave without saving.'
const unsavedSaid = async (page) => page.evaluate((want) => {
  const st = document.getElementById('phStatus'), save = document.getElementById('phSave'), seg = document.querySelector('#phSeg [data-ph="card"]')
  const r = st.getBoundingClientRect()
  if (!(r.width > 0 && r.height > 0)) return 'the sentence is in a pane that is not drawn'
  if (!(r.bottom > 0 && r.top < innerHeight)) return 'the sentence is below the fold of the golfer who edited the name'
  if (seg.getAttribute('aria-pressed') !== 'true') return 'the Card segment is not the chosen one'
  const a = document.activeElement
  if (!a || a.id !== 'phSave') return `focus is on ${a && (a.id || a.tagName)}, not Save`
  if (st.getAttribute('role') !== 'status') return 'the message is not a status'
  if (save.getAttribute('aria-describedby') !== 'phStatus') return 'Save does not describe itself with the sentence'
  return st.textContent === want ? true : `the sentence reads ${JSON.stringify(st.textContent)}`
}, CARD_UNSAVED)
/* the sheet is still the hub (title, no guide's way back) */
const stillTheHub = async (page) => page.evaluate(() => document.getElementById('shTitle').textContent === 'Card & settings' && !document.getElementById('guideBack') ? true : `the sheet left the card: ${JSON.stringify(document.getElementById('shTitle').textContent)}`)
/* TEN / W8 · W7-082 [A2-settings-5] · the Notifications block names its channels: 'On your devices' (This device, Round posts, Chat, with what This device governs), 'By email' (Season email) and 'In Cup Season' (the three
   conversation switches, with their note), each an agate head at level 4 under 'Notifications'; no two ruled blocks abut (the doubled hairline), every switch stays enabled whatever This device says, and a group whose
   RPC cannot answer hides with its head. `heads` is the list of groups the state expects to be drawn. */
const NOTIFY_GROUPS = {
  'On your devices': ['phPushTog', 'phRoundsTog', 'phChatTog'],
  'By email': ['phMailTog'],
  'In Cup Season': ['phTalk_own_round', 'phTalk_replies', 'phTalk_followed'],
}
const notifyGroups = (heads) => async (page) => page.evaluate(({ heads, groups }) => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none' }
  const pane = document.getElementById('phPaneSettings'), top = [...pane.querySelectorAll('.eyebrow[role="heading"]')].find((h) => h.textContent.trim() === 'Notifications')
  if (!top || top.getAttribute('aria-level') !== '3') return 'the Notifications head is missing or not level 3'
  const seen = [...pane.querySelectorAll('.phgrp-h')].filter(shown)
  if (JSON.stringify(seen.map((h) => h.textContent.trim())) !== JSON.stringify(heads)) return `the channel heads read ${JSON.stringify(seen.map((h) => h.textContent.trim()))}, expected ${JSON.stringify(heads)}`
  for (const h of seen) {
    if (h.getAttribute('role') !== 'heading' || h.getAttribute('aria-level') !== '4') return `${JSON.stringify(h.textContent.trim())} is not a level-4 heading`
    let rows = h.nextElementSibling; while (rows && !rows.classList.contains('phsws')) rows = rows.nextElementSibling
    const ids = rows ? [...rows.querySelectorAll('.phsw')].filter(shown).map((b) => b.id) : []
    const want = groups[h.textContent.trim()]
    if (JSON.stringify(ids) !== JSON.stringify(want)) return `${JSON.stringify(h.textContent.trim())} holds ${JSON.stringify(ids)}, expected ${JSON.stringify(want)}`
  }
  const all = [...pane.querySelectorAll('.phsws')].filter(shown)   /* Scorecard scanning's block included: nothing abuts it either */
  for (const g of all) if (g.nextElementSibling && g.nextElementSibling.classList.contains('phsws') && shown(g.nextElementSibling)) return 'two ruled switch blocks abut (a doubled hairline)'
  const off = [...pane.querySelectorAll('.phsw')].filter((b) => shown(b) && b.disabled).map((b) => b.id)
  if (off.length) return `switches disabled: ${off.join(', ')}`
  const said = (el) => { let n = el; while ((n = n.nextElementSibling)) if (n.classList.contains('fine')) return n.textContent.trim(); return '' }
  const devices = pane.querySelector('#phNotify')
  if (said(devices) !== 'This device switches alerts on for this browser. Round posts and Chat choose which alerts you get, on every device.') return `the devices sentence reads ${JSON.stringify(said(devices))}`
  if (heads.includes('In Cup Season')) {
    const note = pane.querySelector('#phTalkGroup > .fine')
    if (!note || note.textContent.trim() !== 'Muted conversations stay quiet. You won\u2019t be notified of your own comments.') return 'the conversation note is missing or misread'
  }
  for (const [name, id] of [['By email', 'phMailGroup'], ['In Cup Season', 'phTalkGroup']]) {
    if (!heads.includes(name) && !document.getElementById(id).hidden) return `${name} is not drawn, but its group is not hidden`
  }
  const last = [...pane.querySelectorAll(':scope > .fine')].find((p) => /^Milestones, results and month closes always come through\.$/.test(p.textContent.trim()))
  if (!last) return 'the always-come-through line is gone'
  const lastGroup = [...pane.querySelectorAll('#phNotify, #phMailGroup .phsws, #phTalk')].filter(shown).pop()   /* the channel groups only: Scorecard scanning's switch follows the line */
  return lastGroup.compareDocumentPosition(last) & Node.DOCUMENT_POSITION_FOLLOWING ? true : 'the always-come-through line is not after the last group'
}, { heads, groups: NOTIFY_GROUPS })
const SETTINGS = [
  { family: 'settings', id: 'card', variant: 'member', fullPage: false, title: 'Card & settings · Your card',
    drive: openHub, expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phName': 'visible', '#phSave': 'visible' } },
    /* TEN / W6 · AW2-06: a row's label is agateS, never mono; a league's code stays mono */
    check: all(notMono(['#phPaneCard .byrow > span'], ['#phPaneCard .byrow > span']), noRetiredGlyph(),
      /* TEN / W8 · W7-032 [A2-settings-7]: Your card / Settings is the system segment (§7.2), not a boxed pill */
      isSystemSegment('#phSeg', 'Your card')) },
  { family: 'settings', id: 'settings', variant: 'member', fullPage: false, title: 'Card & settings · Settings (notifications, theme, sign out)',
    drive: async (page) => { await openHub(page); await click(page, '#phSeg [data-ph="settings"]'); await until(page, () => document.getElementById('phPaneSettings') && document.getElementById('phPaneSettings').offsetParent !== null); await page.waitForTimeout(400) },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phTheme': 'visible', '#phOut': 'visible' } },
    check: all(notMono(['#phPaneSettings .byrow > span'], ['#phPaneSettings .byrow > span']), isSystemSegment('#phSeg', 'Settings'), notifyGroups(['On your devices', 'By email', 'In Cup Season']), ariaWellFormed('#phPaneSettings')) },
  /* W7-082 · a server that cannot answer the recap or the conversation switches (D68, D391 not deployed): their groups hide with their heads, and the devices group stands alone */
  { family: 'settings', id: 'notify-skew', variant: 'member', fullPage: false, title: 'Card & settings · Settings when the server has no season email or conversation switches',
    world: { errors: { rpc: { set_email_recap: { __error: 'fixture: no such function', status: 404, code: 'PGRST202' }, social_notify_prefs: { __error: 'fixture: no such function', status: 404, code: 'PGRST202' } } } },
    expectConsole: [/status of 404/],
    drive: async (page) => { await openHub(page); await click(page, '#phSeg [data-ph="settings"]'); await until(page, () => document.getElementById('phPaneSettings') && document.getElementById('phPaneSettings').offsetParent !== null); await page.waitForTimeout(600) },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phPushTog': 'visible' } },
    check: all(notifyGroups(['On your devices']), ariaWellFormed('#phPaneSettings')) },
  /* TEN / W8 · W7-043 [A2-settings-4] · the Handicap index block, scrolled to. Once the engine owns the number (index_source 'app') the card draws no
     field and no 'Update index' (the server refuses the edit by design and the golfer learned it from a toast): it says whose the number is, in the
     phone's words (CardAndSettingsScreen, Y-06), and keeps the door. A golfer whose number has not been built keeps the starter field. */
  { family: 'settings', id: 'card-index', variant: 'member', fullPage: false, title: 'Card & settings · the Handicap index, built by the engine (no field, no Update index)',
    drive: async (page) => { await openHub(page); await page.evaluate(() => document.getElementById('phIdxLab').scrollIntoView({ block: 'center' })); await page.waitForTimeout(500) },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phIdxOwned': 'text:^Your number builds itself now . 14\\.2$', '#phScoreHelp': 'visible' } },
    check: all(ariaWellFormed('#phPaneCard'), async (page) => page.evaluate(() => {
      if (document.getElementById('phIdx') || document.getElementById('phIdxGo')) return 'the engine-owned card still offers a field or Update index'
      const help = document.getElementById('phIdxHelp').textContent.replace(/\s+/g, ' ').trim()
      if (help !== 'It builds from your posted scores (best of your recent rounds, WHS-style) and moves as you post. How scoring works') return `the note reads ${JSON.stringify(help)}`
      return /[\u2192\u203a]/.test(document.getElementById('phIdxHelp').textContent) ? 'the door carries a typed arrow' : true
    })) },
  { family: 'settings', id: 'card-starter', variant: 'one_round', fullPage: false, title: 'Card & settings · the Handicap index, still building (the starter field stays)',
    drive: async (page) => { await openHub(page); await page.evaluate(() => document.getElementById('phIdxLab').scrollIntoView({ block: 'center' })); await page.waitForTimeout(500) },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phIdx': 'visible', '#phIdxGo': 'text:^Update index$' } },
    check: async (page) => page.evaluate(() => /Set a starter here/.test(document.getElementById('phIdxHelp').textContent) ? true : 'the starter sentence is gone') },
  /* TEN / W8 · W7-042 [A2-settings-3] · an armed card is not dropped by a dismissal. Findable-by saves on the tap, so it does not arm
     Save changes; a pending name edit does, and the first dismissal (the ×) keeps the sheet open, puts focus on Save and says why */
  { family: 'settings', id: 'card-unsaved', variant: 'member', fullPage: false, title: 'Card & settings · an edit is pending and the sheet is dismissed once (kept open, and it says why)',
    drive: async (page) => {
      await openHub(page)
      await click(page, '#phDisc [data-disc="friends"]'); await page.waitForTimeout(400)
      await page.evaluate(() => { window.__w8 = { armedByFindable: document.getElementById('phSave').classList.contains('armed') } })
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#shClose'); await page.waitForTimeout(300)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phStatus': 'text:^You have unsaved changes' } },
    check: all(async (page) => page.evaluate(() => window.__w8.armedByFindable ? 'a Findable-by tap armed Save changes for a change it had already saved' : true), unsavedSaid) },
  /* ...and a second dismissal within four seconds leaves without saving */
  { family: 'settings', id: 'card-unsaved-leave', variant: 'member', fullPage: false, title: 'Card & settings · the second dismissal leaves without saving',
    drive: async (page) => {
      await openHub(page)
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#shClose'); await page.waitForTimeout(300)
      await click(page, '#shClose'); await page.waitForTimeout(500)
    },
    expect: { view: 'view-stats' },
    check: async (page) => page.evaluate(() => document.getElementById('sheet').classList.contains('open') ? 'the second dismissal did not close the sheet' : true) },
  /* TEN / W8 · W7-042 (D's delta at e78d7f22) · (1) the sentence lands where the golfer can SEE it: a dismissal on the SETTINGS pane after a card edit wrote
     to #phStatus inside #phPaneCard, which is display:none there, so the sheet stayed open with no word. The golfer is brought back to the card, where the
     edits and Save are, and told. */
  { family: 'settings', id: 'card-unsaved-settings', variant: 'member', fullPage: false, title: 'Card & settings · a card edit is pending, the golfer is on Settings and dismisses the sheet (brought back to the card, and told)',
    drive: async (page) => {
      await openHub(page)
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#phSeg [data-ph="settings"]'); await page.waitForTimeout(300)
      await click(page, '#shClose'); await page.waitForTimeout(400)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phStatus': 'text:^You have unsaved changes' } },
    check: all(unsavedSaid, stillTheHub) },
  /* (3) once per PENDING EDIT (root's ruling, both clients): an edit made after the question is a new pending edit. The line that asked is cleared by the next input, and the
     next way out asks about it again (the sheet stays, the sentence is back); no stopwatch */
  { family: 'settings', id: 'card-unsaved-rearm', variant: 'member', fullPage: false, title: 'Card & settings · an edit after the question clears it, and the next dismissal asks again',
    drive: async (page) => {
      await openHub(page)
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#shClose'); await page.waitForTimeout(300)
      await page.evaluate(() => { window.__w8 = { asked: document.getElementById('phStatus').textContent } })
      await page.locator('#phName').fill('Avery Fixtured'); await page.waitForTimeout(200)
      await page.evaluate(() => { window.__w8.cleared = document.getElementById('phStatus').textContent })
      await page.waitForTimeout(4500)   /* well past the old four-second window: nothing times out */
      await click(page, '#shClose'); await page.waitForTimeout(400)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phStatus': 'text:^You have unsaved changes' } },
    check: all(unsavedSaid, stillTheHub, async (page) => page.evaluate((want) => {
      const w = window.__w8
      if (w.asked !== want) return `the first dismissal said ${JSON.stringify(w.asked)}`
      return w.cleared === '' ? true : `a new edit did not clear the question: ${JSON.stringify(w.cleared)}`
    }, CARD_UNSAVED)) },
  /* (2) every way out of an armed card asks once: a guide row (it REPLACES the sheet, and its way back rebuilds the hub from the saved profile, so the edits
     are gone), the scoring note under the index, Tell us, Sign out. The first move keeps the sheet and says why; the same move again goes through. */
  { family: 'settings', id: 'card-unsaved-guide', variant: 'member', fullPage: false, title: 'Card & settings · a card edit is pending and a guide row is tapped from Settings (kept, brought back to the card, and told)',
    drive: async (page) => {
      await openHub(page)
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#phSeg [data-ph="settings"]')
      await until(page, () => { const g = document.getElementById('youGuide'); return !!g && g.offsetParent !== null })
      await click(page, '#youGuide [data-guide="scoring"]'); await page.waitForTimeout(400)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phStatus': 'text:^You have unsaved changes' } },
    check: all(unsavedSaid, stillTheHub) },
  { family: 'settings', id: 'card-unsaved-guide-leave', variant: 'member', fullPage: false, title: 'Card & settings · the same guide row tapped again opens the guide (its way back is there)',
    drive: async (page) => {
      await openHub(page)
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#phSeg [data-ph="settings"]')
      await until(page, () => { const g = document.getElementById('youGuide'); return !!g && g.offsetParent !== null })
      await click(page, '#youGuide [data-guide="scoring"]'); await page.waitForTimeout(300)
      await click(page, '#phSeg [data-ph="settings"]'); await page.waitForTimeout(200)
      await click(page, '#youGuide [data-guide="scoring"]')
      await until(page, () => !!document.getElementById('guideBack'), null, 6000); await page.waitForTimeout(400)
    },
    expect: { view: 'view-stats' },
    check: async (page) => page.evaluate(() => document.getElementById('guideBack') && document.getElementById('shTitle').textContent !== 'Card & settings' ? true : 'the second tap did not open the guide') },
  /* the other doors, each asked once with a fresh edit between them (typing re-arms the ask): the scoring note (card pane), Tell us and Sign out (settings pane).
     The sheet stays the hub, and neither the feedback sheet nor the sign-out ran. */
  { family: 'settings', id: 'card-unsaved-doors', variant: 'member', fullPage: false, title: 'Card & settings · the scoring note, Tell us and Sign out each ask first while a card edit is pending',
    drive: async (page) => {
      await openHub(page)
      await page.evaluate(() => { window.__w8 = { fb: 0, out: 0, guide: 0, said: [] }; window.openFeedback = () => { window.__w8.fb++ }; window.csSignOut = async () => { window.__w8.out++ }; window.openScoringHelp = () => { window.__w8.guide++ } })
      const said = () => page.evaluate(() => ({ text: document.getElementById('phStatus').textContent, title: document.getElementById('shTitle').textContent, card: getComputedStyle(document.getElementById('phPaneCard')).display !== 'none' }))
      await page.locator('#phName').fill('Avery Fixtures')
      await click(page, '#phScoreHelp'); await page.waitForTimeout(200)
      const a = await said()
      await page.locator('#phName').fill('Avery Fixtured'); await click(page, '#phSeg [data-ph="settings"]'); await page.waitForTimeout(200)
      await click(page, '#phFeedback'); await page.waitForTimeout(200)
      const b = await said()
      await page.locator('#phName').fill('Avery Fixturer'); await click(page, '#phSeg [data-ph="settings"]'); await page.waitForTimeout(200)
      await click(page, '#phOut'); await page.waitForTimeout(300)
      const c = await said()
      await page.evaluate((r) => { window.__w8.said = r }, [a, b, c])
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#phStatus': 'text:^You have unsaved changes' } },
    check: all(unsavedSaid, async (page) => page.evaluate((want) => {
      const w = window.__w8, names = ['the scoring note', 'Tell us', 'Sign out']
      for (let i = 0; i < 3; i++) { const r = w.said[i]; if (r.text !== want || r.title !== 'Card & settings' || !r.card) return `${names[i]} did not ask first (${JSON.stringify(r)})` }
      return w.guide === 0 && w.fb === 0 && w.out === 0 ? true : `a door ran while the card was armed: scoring ${w.guide}, feedback ${w.fb}, sign out ${w.out}`
    }, CARD_UNSAVED)) },
  /* TEN / W8 · W7-033 [A2-settings-8] · the Settings pane's 'How it works' rows, scrolled to: ruled rows (a hairline above, no box, no
     radius, no typed arrow), as the You door rows are, not bordered cards between ruled rows (§3.1, §5.1, §5.2) */
  { family: 'settings', id: 'guide', variant: 'member', fullPage: false, title: 'Card & settings · Settings, scrolled to How it works (ruled rows)',
    drive: async (page) => {
      await openHub(page); await click(page, '#phSeg [data-ph="settings"]')
      await until(page, () => document.getElementById('youGuide') && document.getElementById('youGuide').offsetParent !== null)
      await page.evaluate(() => document.getElementById('youGuide').scrollIntoView({ block: 'center' }))
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-stats', sheet: '^Card & settings$', selectors: { '#youGuide': 'visible' } },
    check: all(async (page) => {
      /* TEN / W8 · W7-033 (E5's aside): a ruled row does not lift on hover (the global .check:hover moved it 1px) */
      await page.locator('#youGuide .check').first().hover(); await page.waitForTimeout(300)
      const lift = await page.evaluate(() => getComputedStyle(document.querySelector('#youGuide .check')).transform)
      const away = await page.locator('#shTitle').boundingBox(); await page.mouse.move(away.x + 4, away.y + 4)
      return lift === 'none' ? true : `a ruled guide row lifts on hover (${lift})`
    }, async (page) => page.evaluate(() => {
      const rows = [...document.querySelectorAll('#youGuide .check')]
      if (rows.length < 5) return `the guide has ${rows.length} rows`
      const bad = rows.filter((r) => { const cs = getComputedStyle(r); return cs.backgroundColor !== 'rgba(0, 0, 0, 0)' || parseFloat(cs.borderTopLeftRadius) > 0 || cs.borderLeftWidth !== '0px' || cs.borderTopWidth !== '1px' })
      if (bad.length) return `${bad.length} guide row(s) are boxed: ${JSON.stringify(bad[0].innerText.slice(0, 30))}`
      return rows.some((r) => /[\u2192\u203a\u2197]/.test(r.textContent)) ? 'a guide row carries a typed arrow' : true
    })) },
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
      if (open.focus !== 'phDelWhat' || open.role !== 'group' || open.named !== 'phDelHead' || open.described !== 'phDelWhat') return 'the confirmation does not take focus or say what it does: ' + JSON.stringify(open)
      /* TEN / W8 · W7-041 [A2-settings-2, B2-settings-1, A2-settings-9]: a head of its own (named by it, not by the opener), set off by a
         rule, and its two answers equal in width (the destructive act is not the loudest control, §16A.5) */
      const shape = await page.evaluate(() => {
        const g = document.getElementById('phDelConfirm'), h = document.getElementById('phDelHead'), y = document.getElementById('phDelYes').getBoundingClientRect(), n = document.getElementById('phDelNo').getBoundingClientRect()
        return { head: h.textContent.trim(), role: h.getAttribute('role'), rule: getComputedStyle(g).borderTopWidth, yes: Math.round(y.width), no: Math.round(n.width) }
      })
      if (shape.head !== 'Delete your account?' || shape.role !== 'heading') return 'the confirmation has no head of its own: ' + JSON.stringify(shape)
      if (shape.rule !== '1px') return 'the confirmation is not set off from the sign-out row by a rule: ' + JSON.stringify(shape)
      if (Math.abs(shape.yes - shape.no) > 1) return `the two answers are not equals: Delete ${shape.yes}px, Not now ${shape.no}px`
      /* TEN / W8 · W7-041 (E5's aside): §7.1 pressed. The destructive answer takes the neg fill at a16 while it is held; .mini.del had none since it left .btn.destructive.
         The mouse is released away from the button, so nothing is confirmed */
      const box = await page.locator('#phDelYes').boundingBox()
      await page.mouse.move(box.x + box.width / 2, box.y + box.height / 2); await page.mouse.down(); await page.waitForTimeout(200)
      const pressed = await page.evaluate(() => {
        const want = document.createElement('i'); want.style.background = 'color-mix(in srgb, var(--neg) 16%, transparent)'; document.body.appendChild(want)
        const w = getComputedStyle(want).backgroundColor; want.remove()
        const got = getComputedStyle(document.getElementById('phDelYes')).backgroundColor
        return got === w ? 'ok' : `${got} (the pressed fill is neg at a16: ${w})`
      })
      const away = await page.locator('#shTitle').boundingBox()
      await page.mouse.move(away.x + 4, away.y + 4); await page.mouse.up()   /* released over the sheet's own title: a release on the scrim would click it and dismiss the sheet */
      if (pressed !== 'ok') return `the destructive answer's pressed fill is ${pressed}`
      await click(page, '#phDelNo')
      const back = await page.evaluate(() => document.activeElement && document.activeElement.id)
      await click(page, '#phDelete')
      await until(page, () => { const c = document.getElementById('phDelConfirm'); return !!c && c.offsetParent !== null })
      await page.locator('#phDelYes').scrollIntoViewIfNeeded().catch(() => {})
      if (back !== 'phDelete') return 'Not now did not return focus to the opener: ' + back
      /* TEN / W6 · DX2 OB2-03: the armed delete is §7.1's tier — bg2 fill, neg label */
      return armedDelete('#phDelYes')(page)
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
/* TEN / W8 · W7-027 [B2-desk-11] · a desk aside (the season's) and Home's wire scroll in their own height under the rail's fade: the box is
   capped at the window's, it overflows, it says so at rest (data-more + a mask), says nothing at its end, and its tail is reachable */
const deskScroller = (sel) => async (page) => {
  const r = await page.evaluate(async (sel) => {
    const a = document.querySelector(sel), frame = () => new Promise((res) => requestAnimationFrame(() => requestAnimationFrame(res)))
    if (!a) return { missing: true }
    const cs = getComputedStyle(a), h = a.getBoundingClientRect().height
    const capped = h <= innerHeight - 80 + 1, over = a.scrollHeight > a.clientHeight + 2
    const atRest = a.hasAttribute('data-more'), masked = (cs.webkitMaskImage || cs.maskImage || 'none') !== 'none'
    a.scrollTop = a.scrollHeight; await frame()
    const atEnd = a.hasAttribute('data-more')
    const kids = [...a.children].filter((c) => c.getBoundingClientRect().height > 0), last = kids[kids.length - 1]
    const tail = !!last && last.getBoundingClientRect().bottom <= a.getBoundingClientRect().bottom + 1
    a.scrollTop = 0; await frame()
    /* a scroll box clips a focus ring (2px, 2px off) drawn at its own edge: the first focusable's ring must fit inside the box */
    const f = a.querySelector('button, a[href], [tabindex]:not([tabindex="-1"])'), fr = f && f.getBoundingClientRect(), ar = a.getBoundingClientRect()
    const ring = !f || (fr.left - 4 >= ar.left - 0.5 && fr.top - 4 >= ar.top - 0.5 && fr.right + 4 <= ar.right + 0.5)
    return { h: Math.round(h), vh: innerHeight, capped, over, atRest, masked, atEnd, tail, ring, back: a.hasAttribute('data-more') }
  }, sel)
  if (r.missing) return `${sel} is not drawn`
  if (!r.capped) return `${sel} is ${r.h}px tall in a ${r.vh}px window: not a scroll box, so its tail is out of reach`
  if (!r.over) return `${sel} fits its box, so its edge cannot be read`
  return r.atRest && r.masked && !r.atEnd && r.tail && r.ring && r.back ? true : `${sel}'s edge: ${JSON.stringify(r)}`
}
/* TEN / W8 · W7-022 [B2-desk-8] · the reading measure is the track's and the aside follows the column after the desk gutter: from 1100 up the
   gap between a desk body's reading column and its second column is the gutter (40), not a void */
const deskGutter = (colSel, sideSel) => async (page) => page.evaluate(([colSel, sideSel]) => {
  if (innerWidth < 1100) return true
  const c = document.querySelector(colSel), a = document.querySelector(sideSel)
  if (!c || !a) return `${colSel} or ${sideSel} is not drawn`
  const gap = Math.round(a.getBoundingClientRect().left - c.getBoundingClientRect().right)
  return gap >= 36 && gap <= 44 ? true : `${sideSel} sits ${gap}px from ${colSel}, not the 40px gutter (a void beside a capped column)`
}, [colSel, sideSel])
const DESK = [
  { family: 'desk', id: 'home', variant: 'member', desk: true, title: 'The desk · Home', expect: { view: 'view-home' },
    check: async (page) => { const a = await deskCheck(page); if (a !== true) return a; const b = await deskScroller('.deskwire')(page); if (b !== true) return b; const g = await deskGutter('#homeHub .deskmain', '#homeHub .deskwire')(page); return g !== true ? g : deskRailEdge(page) } },
  { family: 'desk', id: 'season', variant: 'member', desk: true, title: 'The desk · the season',
    drive: async (page) => { await click(page, '.navitem[data-v="hub"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-hub'); await page.waitForTimeout(900) },
    /* TEN / W8 · W7-025: the season page at its top marks The season, and only it */
    expect: { view: 'view-hub' }, check: async (page) => { const a = await deskCheck(page); if (a !== true) return a; const b = await deskMenuIs('The season')(page); if (b !== true) return b; const g = await deskGutter('#seasonBody .deskmain', '#seasonAside')(page); return g !== true ? g : deskScroller('#seasonAside')(page) } },
  { family: 'desk', id: 'compete', variant: 'member', desk: true, title: 'The desk · Compete',
    drive: async (page) => { await click(page, '.navitem[data-v="compete"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-compete'); await page.waitForTimeout(900) },
    expect: { view: 'view-compete' }, check: deskCheck },
  { family: 'desk', id: 'golfers', variant: 'member', desk: true, title: 'The desk · Golfers',
    drive: async (page) => { await click(page, '.navitem[data-v="golfers"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-golfers'); await page.waitForTimeout(900) },
    expect: { view: 'view-golfers' }, check: async (page) => { const a = await deskCheck(page); return a !== true ? a : deskGutter('#glfHub .deskmain', '#glfAside')(page) } },
  { family: 'desk', id: 'you', variant: 'member', desk: true, title: 'The desk · You',
    drive: async (page) => { await click(page, '.navitem[data-v="stats"]'); await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-stats'); await page.waitForTimeout(900) },
    /* TEN / W8 · W7-009: You's Form row and Recent rounds open on the last round, so the sidebar's LAST row stands down */
    expect: { view: 'view-stats' }, check: async (page) => { const a = await deskCheck(page); return a !== true ? a : standsDown(['#sideMe [data-mego="my_last_round"]'])(page) } },
]

/* ------------------------------------------------------------ THE DRAW */
/* TEN / W6 · DX2 TP-16 · the draw room of a real league in the draw, as its
   Pro: the synthetic world's North Grove is in its "draft" phase (data only,
   as DX2's draft/formation state set it), then the page's own router. The
   room's dusk ground takes the gutter on all three sides (UI_SYSTEM §3.4):
   its last line of text stands at least a gutter above the ground's foot. */
/* TEN / W6 · DX2 TP-22 · the people picker (Golfers' "Find golfers"): with
   nothing typed it lists your buddies, each a `.prow` */
const PICKER = [
  { family: 'golfers', id: 'find-sheet', variant: 'member', fullPage: false, title: 'Find golfers · the people picker, listing your buddies',
    drive: async (page) => {
      await until(page, () => typeof window.openFindGolfers === 'function')
      await page.evaluate(() => window.openFindGolfers())
      await until(page, () => { const s = document.getElementById('sheet'); return !!s && s.classList.contains('open') && !!document.querySelector('#ppList .prow') }, null, 10000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-home', sheet: '^Find golfers$', selectors: { '#ppFind': 'visible', '#ppList .prow': 'visible' } },
    check: isRow('#ppList .prow', "the picker's buddy row") },
]

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
      if (inset < gutter - 0.5) return `the draw room's last line sits ${inset}px above its ground's foot (the gutter is ${gutter})`
      /* TEN / W6 · the squads stand inside the room. A card that outgrows its
         column runs across the room's inset (402) or off the page (375, where
         the page then scrolls sideways): the gate's overflowX. */
      const grid = document.getElementById('squads'), edge = grid.getBoundingClientRect().right
      for (const c of grid.children) {
        const over = Math.round(c.getBoundingClientRect().right - edge)
        if (over > 0) return `the squad card "${(c.querySelector('b, h4') || c).textContent.trim()}" runs ${over}px past the room's inset`
      }
      const sw = document.documentElement.scrollWidth
      return sw <= innerWidth ? true : `the draw room scrolls sideways: ${sw}px of page in a ${innerWidth}px window`
    }) },
]

export default [...SCHEDULE, ...WIZARD, ...COURSES, ...SETTINGS, ...STATIC, ...DESK, ...DRAW, ...PICKER]
