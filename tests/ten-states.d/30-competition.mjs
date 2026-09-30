/* Cup Season · ten-capture states: COMPETITION (WX lane, helper WX-C2,
 * 2026-09-28).
 *
 *   season/*    the season page (view-hub): its head, the table, the story,
 *               the money (a member and the Pro), the rules
 *   compete/*   the Compete destination, with nothing running and populated
 *   book/*      the Scoreboard and the Book (D381): each synthetic envelope
 *               ADOPTED into the world (rpc/30 adoptBook), opened through the
 *               page's own door, plus the Cup Final race, the failed read and
 *               a cell's receipt
 *   events/*    the event room: a live Ryder, a finished one, an id that does
 *               not resolve, and a read that fails
 *
 * Every state is reached through the page's own controls (the tab bar or the
 * sidebar, the Scoreboard band, the season's jump row, the Book door, the
 * Book's own selects and cells, Compete's peer rows) or its own router
 * (setRoomSeg / switchView('pot') where the desk has no control,
 * window.openEvent for an id nobody can tap). Every check names the surface
 * that must be showing; a fall-through to the Door, Home or a blank pane fails.
 *
 * The answers behind these states: tests/fixtures/ten/rpc/30-competition.mjs. */
import { readFileSync } from 'node:fs'
import { readBook, adoptBook, cupFinalOn, ryderWorld, ids } from '../fixtures/ten/rpc/30-competition.mjs'
import { notMono, noSerifFigure, noRetiredGlyph, readsAsWritten, noRetiredShape, onceInView, armedDelete, capsFromRole, phraseAsSaid, stateContrast, headGap, deskMenuIs, goldOnly, noBoxes, ariaWellFormed, tertiaryDoor, standsDown, namesWrapWhole } from '../ten-mono.mjs'

/* local twins of ten-states.mjs `helpers` (importing that module from here
   would be a cycle through its top-level await) */
const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const activeView = (page) => page.evaluate(() => (document.querySelector('.view.active') || {}).id || null)

/* ------------------------------------------------------------ navigation */
/* the destination's real control: the tab below desk width, the sidebar item at it */
async function tapNav(page, v) {
  await page.locator(`.tab[data-v="${v}"]:visible, .navitem[data-v="${v}"]:visible`).first().click({ timeout: 8000 })
  await until(page, (v) => (document.querySelector('.view.active') || {}).id === 'view-' + v, v)
}
/* a list that re-renders under the tap (a second read landing) takes the
   click on a detached node: tap again until the destination answers */
async function tapUntil(page, sel, done, arg, tries = 6) {
  for (let i = 0; i < tries; i++) {
    await page.locator(sel).first().click({ timeout: 4000 }).catch(() => {})
    const ok = await page.waitForFunction(done, arg, { timeout: 1500 }).then(() => true, () => false)
    if (ok) return true
    await page.waitForTimeout(300)
  }
  return page.waitForFunction(done, arg, { timeout: 4000 }).then(() => true)
}
/* Compete, painted: the list has drawn its rows (or its empty root) */
async function toCompete(page) {
  await tapNav(page, 'compete')
  await until(page, () => { const b = document.getElementById('cmpList'); return !!b && !!b.querySelector('[data-cband], .peerrow, .emptyroot') }, null, 10000)
  await page.waitForTimeout(400)
}
/* the season page from Compete's Scoreboard band -- the same arrival Home's
   season item takes (csOpenSeason) */
async function toSeasonViaBand(page) {
  await toCompete(page)
  await tapUntil(page, '#cmpList [data-cband]', () => (document.querySelector('.view.active') || {}).id === 'view-hub')
  await until(page, () => !!(document.getElementById('seasonTitle') || {}).textContent && document.querySelectorAll('#standings tr').length > 0, null, 10000)
  await page.waitForTimeout(500)
}
/* a scroll the page started (setRoomSeg's smooth scrollIntoView) has landed */
async function scrollSettled(page) {
  let last = -1
  for (let i = 0; i < 30; i++) {
    const y = await page.evaluate(() => Math.round(window.scrollY))
    if (y === last) return y
    last = y
    await page.waitForTimeout(150)
  }
  return last
}
const isDesk = (page) => page.evaluate(() => matchMedia('(min-width: 960px)').matches)
/* the season's rooms: the jump row below desk width (MW-04), the sidebar
   list or the router at it -- the same setRoomSeg either way */
async function toRoom(page, room) {
  await toSeasonViaBand(page)
  if (!(await isDesk(page))) {
    await until(page, (r) => !!document.querySelector(`#seasonJump [data-jump="${r}"]`), room)
    await click(page, `#seasonJump [data-jump="${room}"]`)
  } else if (room === 'league') {
    await click(page, '#deskMenu [data-seg="league"]')
  } else if (room === 'pot') {
    await page.evaluate(() => window.switchView('pot'))      /* the router's own "open the season on the pot" */
  } else {
    await page.evaluate((r) => window.setRoomSeg(r), room)   /* the desk has no control for the table; it heads the page */
  }
  await page.waitForTimeout(250)
  await scrollSettled(page)
}
/* an element's top edge is inside the viewport (a fullPage:false capture
   shows the section it claims) */
const inViewport = (sel, what) => async (page) => page.evaluate(({ sel, what }) => {
  const el = document.querySelector(sel); if (!el) return `${what}: ${sel} is missing`
  const r = el.getBoundingClientRect()
  return r.height > 0 && r.top >= -4 && r.top < innerHeight - 60 ? true : `${what} is not in view (top ${Math.round(r.top)} of ${innerHeight})`
}, { sel, what })
const text = (sel) => (page) => page.evaluate((sel) => ((document.querySelector(sel) || {}).innerText || '').replace(/\s+/g, ' ').trim(), sel)
/* innerText carries text-transform, so a name set in caps reads in caps: match case-blind */
const has = (sel, re, what) => async (page) => { const t = await text(sel)(page); return new RegExp(re, 'i').test(t) ? true : `${what}: ${JSON.stringify(t.slice(0, 160))} !~ /${re}/i` }

/* the light printing's flipped tokens, read from the source (packages/tokens/tokens.json) */
const LIGHT_PRINTING = (() => {
  const doc = JSON.parse(readFileSync(new URL('../../packages/tokens/tokens.json', import.meta.url), 'utf8')), out = {}
  for (const g of Object.values(doc.groups)) for (const [n, t] of Object.entries(g.tokens)) if (t.light !== undefined && String(t.light) !== String(t.dark)) out[n] = String(t.light)
  return out
})()
/* ------------------------------------------------------------ the world */
const NG = { league: 'f3000000-0000-4000-8000-000000000001', season: 'f4000000-0000-4000-8000-000000000011' }
const SW = { league: 'f3000000-0000-4000-8000-000000000002' }   /* South Wash Weekday (fixture), the viewer's second league */
/* the Pro's own instructions (D129): a pot seven of eight have paid into was
   announced somewhere; the core world never said how */
const payHowSet = (W) => {
  const ls = W.tables.league_settings.find((s) => s.league_id === NG.league)
  ls.buy_in_note = 'Cash at the first tee, or a transfer to the Pro'
  ls.buy_in_due_on = '2026-10-04'
}
/* The core world's board carries one invented moment, "FIXTURE WRENS TAKE THE
   LEAD IN WEEK 8" (tests/fixtures/ten/world.mjs, post …902). No producer
   writes that sentence (the real moments are clash streaks, D176/#23), and
   since rpc/30 rebuilt the weekly snapshots from the rounds it is false: the
   Javelinas have led since week 2 and lead 171–137. The season's story prints
   every moment, so these captures drop it; the fix belongs in world.mjs. */
const MOMENT_902 = 'f7000000-0000-4000-8000-000000000902'
const dropInventedMoment = (W) => {
  const p = W.tables.posts.find((x) => x.id === MOMENT_902)
  if (p && p.kind === 'moment' && /TAKE THE LEAD IN WEEK 8/.test(p.body)) { W.tables.posts = W.tables.posts.filter((x) => x !== p); W.notes.push('dropped the invented week-8 moment') }
}
const seasonFacts = (page) => page.evaluate(() => ({ title: (document.getElementById('seasonTitle') || {}).textContent || '', league: window.CS && window.CS.league && window.CS.league.id }))
const onNorthGrove = async (page) => { const f = await seasonFacts(page); return f.league === 'f3000000-0000-4000-8000-000000000001' && f.title === 'North Grove (fixture)' ? true : `the season page is ${JSON.stringify(f)}` }

/* ------------------------------------------------------------ season */
/* TEN / W6 · AW2-06 + OB-05 · the season page's words that were set in mono */
/* AW2-04: at the desk the climb draws only its cut, and "What's on it" yields
   to the pot beside it, so the rungs, the seat line and the line card are
   words the phone's shape must draw and the desk's must not */
/* TEN / W6 · X12 · league 1's season starts `off` days from the capture's today, with its roster closed by the Pro */
const rosterDay = (off) => async (W) => {
  dropInventedMoment(W)
  const L1 = W.ids.lid(1)
  for (const se of W.tables.seasons || []) if (se.league_id === L1) se.starts_on = W.iso(off)
  for (const st of W.tables.league_settings || []) if (st.league_id === L1) st.roster_closed_at = W.at(-2)
}
/* the league room's roster card, by the page's own controls */
async function toLeagueRoster(page) {
  await page.evaluate(() => window.switchView('hub'))
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-hub')
  if (!(await isDesk(page))) {
    await until(page, () => !!document.querySelector('#seasonJump [data-jump="league"]'))
    await click(page, '#seasonJump [data-jump="league"]')
  } else await click(page, '#deskMenu [data-seg="league"]')
  await page.waitForTimeout(250)
  await page.locator('#rosterRow').scrollIntoViewIfNeeded()
  await page.waitForTimeout(300)
}
const SEASON_WORDS = ['#standings th', '#indTable th', '#clashTbl th', { sel: '#climbNote', below: 960 }, { sel: '#climb .climb-cut', below: 960 }, { sel: '#climb .climb-rung .voice', below: 960 },
  '#scenarioLine', { sel: '#lineSplit', below: 960 }, { sel: '#homeSeason .ontheline .ok', below: 960 }, '#seasonArc .arcrow .aw', '#nextK', '#albumGrid .almonth', '#feedList .datesep',
  '.trip .p span', '.trip .p b', '#potMath', '.potgrid .purse .k', '#hubMembersSub', '#hubDraftSub', '#room-league .check .tt small', '#seasonMore',
  { sel: '#seasonJump button', below: 960 }, { sel: '.tabbar .tab', below: 960 }]
/* TEN / W8 · W7-072 [A2-season-9] (D's delta at e78d7f22) · the season dateline is a span of two dates and the Pro, agate. It carries no week count
   (the eyebrow above it says 'Week 8 of 13'), it clears the ember band above it (s3, 12px), and below 480px its two spans are stacked with no
   separator between them, so a wrapped dateline can never begin with a middot */
const datelineOk = async (page) => page.evaluate(() => {
  const line = document.querySelector('.seasondate'), span = document.getElementById('hhSpan'), pro = document.getElementById('hhPro'), band = document.getElementById('seasonScoreboard')
  if (!line || !span || !pro || !(span.getBoundingClientRect().width > 0)) return 'the season dateline is not drawn'
  const t = span.innerText.replace(/\s+/g, ' ').trim()
  if (!/^[A-Z]{3} [A-Z]{3} \d{1,2} \u2013 [A-Z]{3} [A-Z]{3} \d{1,2}$/.test(t)) return `the dateline's span reads ${JSON.stringify(t)} (two dates, no week count)`
  const bandBox = band.getBoundingClientRect()
  if (bandBox.height > 0) { const gap = line.getBoundingClientRect().top - bandBox.bottom; if (gap < 11.5) return `the dateline sits ${Math.round(gap)}px under the band (s3 is 12)` }
  const a = span.getBoundingClientRect(), b = pro.getBoundingClientRect(), sep = getComputedStyle(pro, '::before').content
  if (innerWidth < 480) return b.top >= a.bottom - 1 && sep === 'none' ? true : `at ${innerWidth}px the dateline is not stacked without a separator (span bottom ${Math.round(a.bottom)}, Pro top ${Math.round(b.top)}, separator ${sep})`
  return sep === 'none' ? 'the separator between the span and the Pro is gone above 480px' : true
})
/* TEN / W8 · W7-071 [A2-season-7] · the clinch line is SENTENCES in sentence case, in the body role (sans 15px), with the unit named: 'Fixture Javelinas clinch the top seed with 351 more points.', never a tracked
   mono-era caps run ('FIXTURE JAVELINAS · 351 MORE CLINCHES THE TOP SEED · +10'); joined by a space and not ' · ' */
/* Q50 (A) · owner ruling 2026-09-29 (D24 unchanged): the clinch number is a receipt door. The number is a tertiary link in
   its sentence; a tap opens a sheet whose arithmetic is season_scenarios' own: the other squad's ceiling less the
   leader's points, plus one, is the number on the line. The sheet is closed again so the capture is the page. */
const clinchDoor = async (page) => {
  const r = await page.evaluate(() => {
    const d = document.getElementById('scenClinchDoor')
    if (!d || d.tagName !== 'BUTTON') return 'the clinch number is not a door'
    const m = d.textContent.trim().match(/^(\d+) more points?$/)
    if (!m) return 'the door is not the number with its unit: ' + JSON.stringify(d.textContent)
    const probe = document.createElement('i'); probe.style.color = 'var(--mut)'; document.body.appendChild(probe); const mut = getComputedStyle(probe).color; probe.remove()
    const cs = getComputedStyle(d)
    if (!/underline/.test(cs.textDecorationLine) || parseFloat(cs.textDecorationThickness) !== 2 || cs.textDecorationColor !== mut) return 'the door is not the tertiary link (a 2px mut rule under the words)'
    d.click()
    return Number(m[1])
  })
  if (typeof r === 'string') return r
  await page.waitForFunction(() => document.getElementById('sheet').classList.contains('open'), null, { timeout: 5000 }).catch(() => {})
  const got = await page.evaluate((n) => {
    if (!document.getElementById('sheet').classList.contains('open')) return 'the door opened no sheet'
    const rows = [...document.querySelectorAll('#shBody .mathrow')].map((el) => ({ cls: el.className, t: el.querySelector('span').textContent, b: el.querySelector('b').textContent.replace('\u2212', '-') }))
    const num = (re) => { const x = rows.find((row) => re.test(row.t)); return x ? Number(x.b.replace(/[^\d-]/g, '')) : null }
    const reach = num(/can still reach/), less = num(/^Less /), one = num(/^One more/), tot = rows.find((row) => /tot/.test(row.cls))
    if (reach == null || less == null || one == null || !tot) return 'the receipt does not show the arithmetic: ' + JSON.stringify(rows.map((row) => row.t))
    const total = Number(tot.b)
    if (reach + less + one !== total) return `the receipt does not add up: ${reach} ${less} +${one} ≠ ${total}`
    return total === n ? true : `the receipt's total ${total} is not the line's ${n}`
  }, r)
  await page.keyboard.press('Escape').catch(() => {})
  await page.evaluate(() => { if (typeof window.closeSheet === 'function') window.closeSheet() })
  await page.waitForTimeout(400)
  return got
}
/* Q39 (a) · root's ruling 2026-09-29: the Every golfer table's "Avg vs playing HCP" column says it in words (vsShort) on the real
   path, as the diorama's has since Q-23 — one producer, never a signed figure */
const raceInWords = async (page) => page.evaluate(() => {
  const cells = [...document.querySelectorAll('#indTable td.dw')].filter((el) => el.getBoundingClientRect().width > 0).map((el) => el.textContent.trim())
  if (!cells.length) return 'the Every golfer table draws no average'
  const off = cells.filter((t) => t !== '—' && !/^(beat by \d+\.\d|played to it|\d+\.\d over)$/.test(t))
  if (off.length) return 'an average is not in words: ' + JSON.stringify(off.slice(0, 3))
  /* the words are wider than a signed figure: the table still fits its column */
  const t = document.getElementById('indTable'), box = t.parentElement.getBoundingClientRect(), r = t.getBoundingClientRect()
  return r.right <= box.right + 1 && r.right <= innerWidth ? true : `the table runs ${Math.round(r.right - Math.min(box.right, innerWidth))}px past its column`
})
const clinchSentence = async (page) => page.evaluate(() => {
  const b = document.getElementById('scenarioLine')
  if (!b || !(b.getBoundingClientRect().width > 0)) return 'the season page draws no clinch line'
  const t = b.textContent.replace(/\s+/g, ' ').trim(), cs = getComputedStyle(b)
  const probe = document.createElement('p'); probe.className = 'cs-body-s'; document.body.appendChild(probe); const body = getComputedStyle(probe); const want = { family: body.fontFamily, size: body.fontSize }; probe.remove()
  if (cs.textTransform !== 'none' || cs.fontFamily !== want.family || cs.fontSize !== want.size) return `the clinch line is ${cs.textTransform} ${cs.fontSize} ${cs.fontFamily.split(',')[0]}, not the body role (${want.size} ${want.family.split(',')[0]})`
  if (/ \u00b7 /.test(t)) return `the clinch line still joins its parts with a middot: ${JSON.stringify(t)}`
  if (/\b[A-Z]{3,}\b/.test(t)) return `capitals are typed into the clinch line: ${JSON.stringify(t)}`
  return /^Fixture Javelinas clinch the top seed with \d+ more points\.( |$)/.test(t) ? true : `the clinch line reads ${JSON.stringify(t)}`
})
/* TEN / W8 · W7-112 [A2-desk-20] · the standings' movement mark has a head that names it: from 960 a column headed 'Since <day>' holds the mark (held bar, up or down count) and the Gap cell holds only the gap;
   below 960 the merged cell keeps both, as before, and the extra column is not drawn */
const sinceColumn = async (page) => page.evaluate(() => {
  const t = document.getElementById('standings'), shown = (el) => el && el.getBoundingClientRect().width > 0 && getComputedStyle(el).display !== 'none'
  if (!t || !shown(t)) return 'the standings table is not on the page'
  const head = [...t.querySelectorAll('tr:first-child th')].find((h) => /^Since /i.test(h.textContent.trim()))
  if (!head) return 'the head row has no Since column'
  const rows = [...t.querySelectorAll('tr.tap')], marks = (r, sel) => [...r.querySelectorAll(sel)].filter(shown)
  if (innerWidth >= 960) {
    if (!shown(head)) return "the 'Since' head is not drawn at the desk"
    for (const r of rows) {
      if (marks(r, 'td.chg:not(.since) .mv, td.chg:not(.since) .held').length) return 'a movement mark still sits under Gap at the desk'
    }
    if (!rows.some((r) => marks(r, 'td.since .mv, td.since .held').length)) return 'no movement mark sits under the Since head'
    if (!/^Since (Sun|Mon|Tue|Wed|Thu|Fri|Sat)$/.test(head.textContent.trim())) return `the head reads ${JSON.stringify(head.textContent.trim())}, not sentence case`
  } else {
    if (shown(head)) return "the 'Since' head is drawn below the desk"
    if (!rows.some((r) => marks(r, 'td.chg:not(.since) .mv, td.chg:not(.since) .held').length)) return 'the merged Gap cell lost its mark below the desk'
  }
  return true
})
/* TEN / W8 · W7-066 [B2-desk-17] · the figures under a table's title cell stand under a head: a right-aligned 'Pts' cell in the head row, on the same edge as the figures (the clash's 9 and 7, the Cup Final race's totals) */
const ptsHead = (tableSel) => async (page) => page.evaluate((tableSel) => {
  const t = document.querySelector(tableSel)
  if (!t || !(t.getBoundingClientRect().width > 0)) return `${tableSel} is not on the page`
  const head = t.querySelector('tr:first-child th.num')
  if (!head || !/^pts$/i.test(head.textContent.trim())) return `${tableSel}'s head row has no Pts cell: ${JSON.stringify([...t.querySelectorAll('tr:first-child th')].map((h) => h.textContent.trim().slice(0, 24)))}`
  const figs = [...t.querySelectorAll('td.num.pts')]
  if (!figs.length) return `${tableSel} draws no figures`
  for (const f of figs) if (Math.abs(f.getBoundingClientRect().right - head.getBoundingClientRect().right) > 1) return 'a figure is not under its Pts head'
  return true
}, tableSel)
/* TEN / W8 · W7-067 [B2-season-20] · the open clash: its head carries ONE restrained ember dot that says it is live (none once the week is settled), and both rows start at the head's own left edge:
   the empty rank column (a 'W' only after settling, which the settled head already says) is gone */
/* TEN / W8 · W7-123 [A2-competition-13] · the Scoreboard band is Compete's only door to the season, and its accessible name is its facts: it says its action too, as the phone's band does
   ('Opens the season'), through a hidden line the button is described by; the visible band gains no verb or arrow */
const bandHint = async (page) => page.evaluate(() => {
  const b = document.querySelector('#cmpList [data-cband]'); if (!b) return 'no Scoreboard band on Compete'
  const id = b.getAttribute('aria-describedby'), hint = id && document.getElementById(id)
  if (!hint) return 'the band is not described by anything: a screen reader hears its facts and no action'
  if (hint.textContent.trim() !== 'Opens the season') return `the band's hint reads ${JSON.stringify(hint.textContent.trim())}`
  if (hint.getBoundingClientRect().width > 2) return 'the hint is drawn on the band (it is for a screen reader)'
  return /[\u2192\u203a]/.test(b.textContent) ? 'the visible band types an arrow' : true
})
const clashOpen = async (page) => page.evaluate(() => {
  const t = document.getElementById('clashTbl'), wrap = document.getElementById('clashWrap')
  if (!t || !wrap || !(wrap.getBoundingClientRect().width > 0)) return 'the clash is not on the page'
  const th = t.querySelector('th'), dots = t.querySelectorAll('.clashdot'), settled = !!(window.weekClash && window.weekClash.settled_at)
  if (settled) return dots.length ? 'a settled clash still carries the live dot' : true
  if (dots.length !== 1) return `the open clash carries ${dots.length} dots, expected one`
  const dot = dots[0], probe = document.createElement('i'); probe.style.background = 'var(--brand)'; document.body.appendChild(probe); const brand = getComputedStyle(probe).backgroundColor; probe.remove()
  if (getComputedStyle(dot).backgroundColor !== brand) return `the dot is ${getComputedStyle(dot).backgroundColor}, not ember (${brand})`
  if (dot.getAttribute('role') !== 'img' || dot.getAttribute('aria-label') !== 'Live') return 'the dot is not named Live'
  if (t.querySelector('td.rk')) return 'the clash still draws its empty rank column'
  const left = th.getBoundingClientRect().left + parseFloat(getComputedStyle(th).paddingLeft)
  for (const tn of t.querySelectorAll('.tn')) if (Math.abs(tn.getBoundingClientRect().left - left) > 1.5) return `a side starts ${Math.round(tn.getBoundingClientRect().left - left)}px from the head's left edge`
  return true
})
const SEASON = [
  { family: 'season', id: 'narrative', variant: 'member', title: 'The season page, its head: North Grove in week 8 and the story line', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toSeasonViaBand(page); await page.evaluate(() => window.scrollTo(0, 0)); await scrollSettled(page) },
    expect: { view: 'view-hub', selectors: { '#seasonScoreboard': 'visible', '#seasonDateline': 'text:Week 8 of 13', '#seasonLead': 'visible' } },
    check: all(onNorthGrove, inViewport('#seasonScoreboard', 'the season head'),
      /* TEN / W8 · W7-020 [A2-season-2]: at the phone the season page keeps COMPETE current in the tab band (it is a Compete page, as the event
         room is) and has one way back, named for where it was opened from; the desk has neither (its sidebar marks The season) */
      async (page) => page.evaluate(() => {
        const back = document.getElementById('seasonBack'), shown = (el) => !!el && el.getBoundingClientRect().width > 0 && el.getBoundingClientRect().height > 0
        if (innerWidth >= 960) return shown(back) ? 'the desk draws the phone\'s back link' : true
        const on = [...document.querySelectorAll('.tab.active')].map((t) => t.dataset.v)
        if (on.join() !== 'compete') return `the tab band marks ${JSON.stringify(on)}, expected ["compete"]`
        if (document.querySelector('.tab.active').getAttribute('aria-current') !== 'page') return 'the current tab does not say aria-current'
        if (!shown(back) || back.textContent.trim() !== 'Compete' || back.dataset.go !== 'compete') return `the back link is ${JSON.stringify(back && back.textContent.trim())} → ${back && back.dataset.go}`
        return back.getBoundingClientRect().height >= 44 ? true : `the back link is ${Math.round(back.getBoundingClientRect().height)}px tall`
      }),
      /* TEN / W8 · W7-028 [B2-season-24]: the story link carries no typed arrow (AW2-08) and its second channel is the rule beneath it (§16.4) */
      async (page) => page.evaluate(() => {
        const a = document.getElementById('seasonMore'), r = a.getBoundingClientRect()
        if (!(r.width > 0)) return 'the story link is not drawn'
        const cs = getComputedStyle(a), i = document.createElement('i'); i.style.color = 'var(--act)'; a.appendChild(i); const act = getComputedStyle(i).color; i.remove()
        if (/[\u2192\u2197\u2190]/.test(a.textContent)) return `the story link carries a typed arrow: ${JSON.stringify(a.textContent)}`
        return cs.borderBottomWidth === '2px' && cs.borderBottomColor === act ? true : `the story link has no 2px act rule under it (${cs.borderBottomWidth} ${cs.borderBottomColor})`
      }),
      has('#seasonLead', 'Fixture (Javelinas|Wrens)', 'the story line'), datelineOk,
      /* TEN / W6 · OB2-02: the dateline's Pro and the climb's cut label are typed as said, their caps the roles' (the cut is drawn below the desk) */
      capsFromRole(['#hhPro', '#climb .climb-cut .lb'], ['#hhPro', { sel: '#climb .climb-cut .lb', below: 960 }]),
      async (page) => page.evaluate(() => window.seasonStory && window.seasonStory.season && window.seasonStory.season.id === 'f4000000-0000-4000-8000-000000000011' ? true : 'season_story did not answer for North Grove')) },
  { family: 'season', id: 'leaderboard', variant: 'member', title: 'The season page, the table: two squads, the clash, every golfer', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: (page) => toRoom(page, 'standings'),
    expect: { view: 'view-hub', selectors: { '#standings': 'visible', '#indTable': 'visible' } },
    check: all(onNorthGrove, inViewport('#standings', 'the standings table'),
      has('#standings', 'Fixture Javelinas[\\s\\S]*171[\\s\\S]*Fixture Wrens[\\s\\S]*137', 'the squad table (v_squad_standings: 171 / 137)'),
      /* TEN / W8 · W7-028: the Book door is marked by a 2px mut rule under its label, not by the row's hairline */
      tertiaryDoor('#seasonBookDoor'), clashOpen, ptsHead('#clashTbl'), sinceColumn,
      /* TEN / W8 · W7-060 [A2-season-5]: a tied Points King names who is level (never the word 'Level' in the name's slot), wraps rather than clipping, and the sub says 'level on N' */
      async (page) => page.evaluate(() => {
        const k = document.getElementById('awKing'), sub = document.getElementById('awKingS')
        if (!k || !(k.getBoundingClientRect().width > 0)) return true
        const t = k.textContent.trim()
        if (/^level$/i.test(t)) return 'the tied Points King tile says Level in the name\'s slot'
        if (!/ and /.test(t)) return `the Points King tile does not name two golfers: ${JSON.stringify(t)}`
        if (k.scrollWidth > k.clientWidth + 1) return `the Points King tile clips ${JSON.stringify(t)}`
        return /^Points King · level on \d+$/.test(sub.textContent.trim()) ? true : `the tile's sub reads ${JSON.stringify(sub.textContent)}`
      }),
      async (page) => page.evaluate(() => document.querySelectorAll('#indTable tr').length >= 8 ? true : 'the every-golfer table has fewer than eight rows'),
      /* TEN / W6 · AW2-06 + OB-05: every label on the season page is agate and
         every phrase agate or body — mono keeps the figures (§1.4). The page
         draws all of these at once, whichever section is in view. */
      notMono(SEASON_WORDS, SEASON_WORDS),
      /* TEN / W6 · AW2-07: the story's figures are runs and "What's on it" is the figure role — never the serif */
      noSerifFigure(['#standingsStory', '#lineAmt'], ['#standingsStory .cfrun', { sel: '#lineAmt', below: 960 }]),
      /* TEN / W6 · AW2-08: no retired glyph on the season page, and its span is an en dash */
      noRetiredGlyph(),
      readsAsWritten([['#hhSpan', ' \u2013 ', true]]),
      /* TEN / W6 · AW2-13: no pill (the jump chips), no spine, no glass */
      noRetiredShape(),
      /* TEN / W6 · AW2-14: the climb's own spark is ink — gold is earned (D359), being you is not. It
         rides the viewer's rung, which the desk no longer draws (AW2-04), so the phone's shape reads it */
      async (page) => page.evaluate(() => { const p = document.querySelector('.climb-spark polyline'); if (!p) return innerWidth >= 960 ? true : 'no climb spark to read'; return /--gold/.test(p.getAttribute('stroke') || '') ? 'the climb spark is gold' : true }),
      /* TEN / W6 · AW2-04 (L-34, D360): the table is the one standings object. At the desk the climb
         card keeps only its cut line and "What's on it" yields to the pot beside it; at every width
         the story says the gap once (the fixture's Wrens trail by 34, the viewer's squad) */
      async (page) => page.evaluate(() => {
        const shown = (el) => { if (!el) return false; const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
        const story = ((document.getElementById('standingsStory') || {}).innerText || '').replace(/\s+/g, ' ').trim()
        if (story !== 'Fixture Javelinas lead by 34.') return `the story reads ${JSON.stringify(story)}`
        if (innerWidth < 960) return [...document.querySelectorAll('#climb .climb-rung')].some(shown) ? true : 'the phone lost its ladder'
        if ([...document.querySelectorAll('#climb .climb-rung, #climb .climb-ellip')].some(shown)) return 'the desk climb still draws the rungs the table draws'
        /* W7-021: a two-squad season's cut is the seed line, which the table's cut row and its GAP column already print
           (the fixture is two squads), so the whole climb column yields at the desk */
        if (![...document.querySelectorAll('#homeSeason .homegrid > [data-desk-yields]')].length) return 'the desk climb column does not yield for a two-squad season'
        if (['#climbEyebrow', '#climb', '#climb .climb-cut'].some((s) => shown(document.querySelector(s)))) return 'the desk still draws the climb card (its line is the table\'s cut row and GAP)'
        const note = document.getElementById('climbNote')
        if (shown(note) && note.innerText.trim()) return `the desk climb still says the seat line: ${JSON.stringify(note.innerText.trim())}`
        if ([...document.querySelectorAll('#homeSeason .ontheline')].some(shown)) return '"What\'s on it" still prints the pot beside the pot'
        return true
      }),
      onceInView([["the leader's points (171)", '(?<![\\d.,])171(?![\\d.,])', true], ["the second squad's points (137)", '(?<![\\d.,])137(?![\\d.,])', true],
        ['the pot ($600)', '\\$600(?![\\d.,])']], 960),
      /* TEN / W6 · DX2 OB2-02: the seat line and the clinch line take their caps from their roles; the
         strings are typed as said (the seat line is drawn below the desk only, AW2-04) */
      /* W7-071 (C): the clinch line is a body sentence now, so it leaves the role-caps check for clinchSentence */
      capsFromRole(['#climbNote'], [{ sel: '#climbNote', below: 960 }]), clinchSentence, clinchDoor, raceInWords,
      /* TEN / W6 · W7-024 [B2-season-5] (D's delta): the clash head and its sides' lines were built with toUpperCase(); the
         words are typed as said and the caps are the roles' (.tbl th, #clashTbl .tc) */
      capsFromRole(['#clashTbl th', '#clashTbl .tc'], ['#clashTbl th', '#clashTbl .tc']),
      /* root's ruling (§1.3): the head's rider after "The clash" is a phrase, sentence case */
      phraseAsSaid(['#clashTbl th .is-phrase'], ['#clashTbl th .is-phrase']),
      /* TEN / W8 · W7-014 [B2-season-6]: the climb's and the standings' heads take the section gap under the block above them */
      headGap(['#climbEyebrow', '#standingsEyebrow']),
      /* TEN / W8 · W7-029 [A2-season-3] (1 of 4): gold on the season page is the leader's rail field and the pot's figure, and nothing else */
      goldOnly('#view-hub', ['tr.lead td.rk', '#potAmt']),
      /* (2 of 4): the climb is no card and its rungs are slats */
      noBoxes(['#view-hub .homegrid > div > .card', '#view-hub .climb-rung', '#view-hub .nextcard', '#view-hub .trip .p']),
      /* TEN / W8 · W7-023 [B2-desk-9]: the individual board carries Last five inside the row at the desk (D280), and not below it */
      async (page) => page.evaluate(() => {
        const th = document.querySelector('#indTable th.deskonly'), rows = [...document.querySelectorAll('#indTable tr[data-ri]')]
        const shown = (el) => !!el && el.getBoundingClientRect().width > 0
        if (!th || !rows.length) return 'the individual table has no Last five head or no rows'
        if (innerWidth < 960) return shown(th) ? 'Last five is drawn below the desk' : true
        if (!shown(th) || th.textContent.trim() !== 'Last five') return 'the desk individual table draws no Last five column'
        const bad = rows.filter((r) => r.querySelectorAll('td.deskonly .form5 i').length !== 5).length
        return bad ? `${bad} of ${rows.length} rows lack the five dots` : true
      })) },
  /* TEN / W6 · DX2 OB2-02 · the season six days before its first tee, and a
     league in its draw: the two heroes' lines (#khCount, #draftPoolSub).
     DX2's own states (season/kickoff, season/draft-phase): the synthetic
     world's DATA moves (a start date, a phase), then the page's router. */
  { family: 'season', id: 'kickoff', variant: 'member', title: 'The season page six days before the first tee (#kickoffHero)', fullPage: false,
    prepare: async (W) => { const L1 = W.ids.lid(1); for (const s of W.tables.seasons || []) if (s.league_id === L1) { s.starts_on = W.iso(6); s.ends_on = W.iso(6 + 13 * 7 - 1) } },
    drive: async (page) => { await page.evaluate(() => window.switchView('hub')); await until(page, () => { const k = document.getElementById('kickoffHero'); return !!k && k.offsetParent !== null }); await page.waitForTimeout(600) },
    expect: { view: 'view-hub', selectors: { '#kickoffHero': 'visible', '#khCount': 'text:Kicks off in \\d+ days?' } },
    check: capsFromRole(['#khCount'], ['#khCount']) },
  { family: 'season', id: 'draft-phase', variant: 'pro', title: 'The season page of a league in its draw (#homeDraft)', fullPage: false,
    prepare: async (W) => { const L1 = W.ids.lid(1); for (const l of W.tables.leagues || []) if (l.id === L1) l.phase = 'draft' },
    drive: async (page) => { await page.evaluate(() => window.switchView('hub')); await until(page, () => { const d = document.getElementById('homeDraft'); return !!d && d.offsetParent !== null }); await page.waitForTimeout(600) },
    expect: { view: 'view-hub', selectors: { '#homeDraft': 'visible', '#draftPoolSub': 'visible' } },
    check: capsFromRole(['#draftPoolSub'], ['#draftPoolSub']) },
  { family: 'season', id: 'story', variant: 'member', title: 'The season page, the story: the arc of weeks and the archive', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      if (await isDesk(page)) await click(page, '#deskMenu [data-seg="archive"]')
      else { await until(page, () => { const a = document.getElementById('seasonMore'); return !!a && a.offsetParent !== null }); await click(page, '#seasonMore') }
      await page.waitForTimeout(250); await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#seasonArc': 'visible', '#seasonStoryHead': 'visible' } },
    check: all(onNorthGrove, inViewport('#seasonArc', "the season's story"),
      /* the one lead change the rebuilt snapshots hold (week 2); the core
         world has no other season-long board history to tell */
      has('#seasonArc', 'Week 2[\\s\\S]*Fixture Javelinas took the lead from Fixture Wrens\\.', 'the arc’s lead change'),
      /* TEN / W8 · W7-025 [B2-season-8]: the row that opened the story is the current one */
      deskMenuIs("The season's story"),
      async (page) => page.evaluate(() => /TAKE THE LEAD IN WEEK 8/i.test(document.getElementById('seasonArc').innerText) ? 'the invented week-8 moment is still on the story' : true)) },
  { family: 'season', id: 'pot', variant: 'member', title: 'The season page, the money: $600 pot, $525 in, how to pay, a member reads the ledger', fullPage: false,
    prepare: async (W) => { dropInventedMoment(W); payHowSet(W) },
    drive: (page) => toRoom(page, 'pot'),
    expect: { view: 'view-hub', selectors: { '#room-pot': 'visible', '#potAmt': 'text:\\$600', '#potK': 'text:^The pot · eight in$', '#potMath': 'text:^\\$75 each · \\$525 collected · 1 still owes$', '#paidCount': 'text:^seven of eight$', '#payHow': 'text:Cash at the first tee' } },
    check: all(onNorthGrove, inViewport('#room-pot', 'the money'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#payers .payer')]
        if (rows.length !== 8) return `${rows.length} payer rows, expected 8`
        if (rows.some((r) => r.tagName === 'BUTTON')) return 'a member sees tappable payer rows'
        if (document.querySelector('#payHow [data-payedit]')) return 'a member sees the Pro’s edit link'
        return rows.filter((r) => r.classList.contains('paid')).length === 7 ? true : 'seven of eight should read paid'
      }),
      /* TEN / W6 · AW2-07: the pot is the board `figure`, never the serif */
      noSerifFigure(['#potAmt', '.trip .p b'], ['#potAmt']),
      /* TEN / W8 · W7-014 [B2-season-6]: 'Season stakes' and 'How to pay' take the section gap */
      headGap(['#room-pot .potgrid > div > .eyebrow:first-child']),
      goldOnly('#view-hub', ['tr.lead td.rk', '#potAmt']),
      /* TEN / W8 · W7-029 [A2-season-3] (4 of 4): the pot is a rule-and-figure (a 2px gold rule under #potAmt) and the split is three
         ink figures on ONE 2px ink rule (the figures touch), with no box round either (PotPane.swift's shape, §15.4) */
      noBoxes(['#view-hub .purse', '#view-hub .trip .p']),
      async (page) => page.evaluate(() => {
        const tok = (n) => { const i = document.createElement('i'); i.style.color = `var(${n})`; document.body.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
        const amt = getComputedStyle(document.getElementById('potAmt'))
        if (amt.borderBottomWidth !== '2px' || amt.borderBottomColor !== tok('--gold')) return `the pot figure's rule is ${amt.borderBottomWidth} ${amt.borderBottomColor}, not 2px gold`
        const bs = [...document.querySelectorAll('#room-pot .trip .p b')].filter((b) => b.getBoundingClientRect().width > 0)
        if (bs.length !== 3) return `the split has ${bs.length} figures`
        if (bs.some((b) => getComputedStyle(b).borderBottomWidth !== '2px' || getComputedStyle(b).borderBottomColor !== tok('--ink'))) return 'the split figures are not on a 2px ink rule'
        const gaps = [1, 2].map((i) => Math.round(bs[i].getBoundingClientRect().left - bs[i - 1].getBoundingClientRect().right))
        return gaps.every((g) => Math.abs(g) <= 1) ? true : `the split's rule is broken: gaps ${JSON.stringify(gaps)}`
      })) },
  { family: 'season', id: 'pot-pro', variant: 'pro', title: 'The season page, the money, as the Pro: tap a name as money moves', fullPage: false,
    prepare: async (W) => { dropInventedMoment(W); payHowSet(W) },
    drive: (page) => toRoom(page, 'pot'),
    expect: { view: 'view-hub', selectors: { '#room-pot': 'visible', '#potAmt': 'text:\\$600', '#payHow [data-payedit]': 'visible' } },
    check: all(onNorthGrove, inViewport('#room-pot', 'the money'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#payers .payer')]
        if (rows.length !== 8) return `${rows.length} payer rows, expected 8`
        return rows.every((r) => r.tagName === 'BUTTON') ? true : 'the Pro’s payer rows are not controls'
      }),
      /* TEN / W8 · W7-012 [B2-season-13]: the Pro's box carries the word (Paid / Not yet) and the empty box is mut,
         never rule (§16.1); a member's rows already read the word */
      async (page) => page.evaluate(() => {
        const st = [...document.querySelectorAll('#payers .payer .st')].map((e) => e.textContent.trim())
        return st.length === 8 && st.filter((x) => x === 'Paid').length === 7 && st.filter((x) => x === 'Not yet').length === 1 ? true : `the Pro's rows say ${JSON.stringify(st)}`
      }),
      stateContrast([{ sel: '#payers .payer:not(.paid) .tick', prop: 'borderTopColor', min: 3, what: 'the unpaid box' }]),
      headGap(['#room-pot .potgrid > div > .eyebrow:first-child'])) },
  /* TEN / W8 · W7-090 [A2-desk-7] · 'g t' jumps to the table: on the season page focus lands on the standings' first row, not on body (the first .tbl in the document is the
     Cup Final race table inside a display:none wrap, and the clash table precedes the standings when it shows) */
  { family: 'season', id: 'keys-table', variant: 'member', desk: true, fullPage: false, title: 'The season page (desk): g then t lands on the standings\' first row',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await page.evaluate(() => { window.scrollTo(0, 0); if (document.activeElement && document.activeElement !== document.body) document.activeElement.blur() }); await page.waitForTimeout(300)
      await page.keyboard.press('g'); await page.keyboard.press('t'); await page.waitForTimeout(700); await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#standings': 'visible' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => {
      const a = document.activeElement, first = document.querySelector('#standings tr.tap')
      return a && a === first ? true : `focus is on ${a && (a.id || a.tagName + '.' + a.className)}, not the standings' first row`
    })) },
  /* TEN / W8 · W7-062 [B2-season-11] · the Pro's 'Cancel this season' is the page's FOOT, beside Leave the season: not a red link in the season's head between it and the
     week clock. A tertiary link in content (2px mut rule, 44 tall), not neg: the consent sheet it opens is where the act is armed in neg */
  { family: 'season', id: 'pro-foot', variant: 'pro', fullPage: false, title: 'The season page, as the Pro: the foot (Leave the season, and Cancel this season as a quiet link)',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => { const a = document.getElementById('hhDelete'); return !!a && a.offsetParent !== null })
      await page.evaluate(() => document.getElementById('hhDanger').scrollIntoView({ block: 'center' })); await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#hhDelete': 'visible' } },
    check: all(onNorthGrove, tertiaryDoor('#hhDelete'), async (page) => page.evaluate(() => {
      const dz = document.getElementById('hhDanger'), head = document.getElementById('hubHeader'), clock = document.getElementById('monthClock'), leave = document.getElementById('leaveSeason')
      if (head.contains(dz)) return "the cancel link is still in the season's head"
      if (clock && dz.getBoundingClientRect().top < clock.getBoundingClientRect().bottom) return 'the cancel link is above the week clock'
      if (leave && dz.getBoundingClientRect().top < leave.getBoundingClientRect().top) return 'the cancel link is not at the foot, beside Leave the season'
      const p = document.createElement('i'); p.style.color = 'var(--neg)'; document.body.appendChild(p); const neg = getComputedStyle(p).color; p.remove()
      return getComputedStyle(document.getElementById('hhDelete')).color === neg ? 'the cancel link is drawn in neg before the consent sheet arms it' : true
    })) },
  /* TEN / W6 · DX2 OB2-03 · the Pro's "Cancel this season", opened and NOT
     confirmed: North Grove is under way, so it is the consent flow's sheet,
     and its armed control is §7.1's destructive tier */
  { family: 'season', id: 'cancel-confirm', variant: 'pro', fullPage: false, title: 'The season page, as the Pro: Cancel this season, the confirmation (not confirmed)',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => { const a = document.getElementById('hhDelete'); return !!a && a.offsetParent !== null })
      await click(page, '#hhDelete')
      await until(page, () => { const s = document.getElementById('sheet'); return !!s && s.classList.contains('open') && !!document.getElementById('cxGo') })
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-hub', sheet: '^Cancel ', selectors: { '#cxGo': 'visible', '#cxNo2': 'visible' } },
    check: armedDelete('#cxGo') },
  /* TEN / W8 · W7-025 [B2-season-8] (E3, D's second reader) · the chosen row wins: 'The season's story' chosen right after 'The rules' (the rules head is in the top
     half) is the marked row. The jump to the top took the rules head out of the window's top half and the observer's queued entry ticked THE SEASON over it. */
  { family: 'season', id: 'story-from-rules', variant: 'member', desk: true, title: "The season page (desk): The rules chosen, then The season's story — the story is the marked row", fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await click(page, '#deskMenu [data-seg="league"]'); await page.waitForTimeout(400); await scrollSettled(page)
      await click(page, '#deskMenu [data-seg="archive"]'); await page.waitForTimeout(500); await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#seasonStoryHead': 'visible' } },
    check: all(onNorthGrove, deskMenuIs("The season's story")) },
  { family: 'season', id: 'rules', variant: 'member', title: 'The season page, the rules in sentences', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: (page) => toRoom(page, 'league'),
    expect: { view: 'view-hub', selectors: { '#rulesHead': 'visible', '#bylawsHub': 'visible', '#hubSeasonRevoke': 'text:^Turn off$' } },
    check: all(onNorthGrove, inViewport('#room-league', 'the rules'),
      async (page) => page.evaluate(() => document.getElementById('bylawsHub').innerText.trim().length > 80 ? true : 'the rules are empty'),
      /* TEN / W8 · W7-029 [A2-season-3] (3 of 4): the League rows are slats, not cards */
      noBoxes(['#view-hub .check']),
      /* TEN / W8 · W7-065 [A2-season-8]: the roster, share and squads rows are headed 'Who’s in', the phone's head for them; 'League' is not a container label (TERMINOLOGY §2.3) */
      async (page) => page.evaluate(() => {
        const heads = [...document.querySelectorAll('#room-league > .eyebrow')].filter((e) => e.getBoundingClientRect().height > 0).map((e) => e.textContent.trim())
        if (heads.includes('League')) return 'a section is still headed League'
        return heads.includes('Who\u2019s in') ? true : `the room's heads read ${JSON.stringify(heads)}, expected Who\u2019s in`
      }),
      /* TEN / W8 · W7-093 [A2-rules-2]: the minimum's sentence says WHICH months carry none (it read 'Post 2 rounds a month.' with no word on the partial first and last month) */
      has('#bylawsHub', 'A partial first or last month has no minimum\\.', 'the rules say which months carry no minimum'),
      /* TEN / W8 · W7-025 [B2-season-8]: the desk's season list marks the row of the section in view, and the row that
         scrolls to the story is named for it. Chosen, the rules are current; scrolled to the top, the season is; and
         scrolled back, the rules again (the scroll-spy, not only the click) */
      async (page) => {
        if (!(await isDesk(page))) return true
        const names = await page.evaluate(() => [...document.querySelectorAll('#deskMenu .navitem')].map((r) => r.textContent.trim().replace(/\u2019/g, "'")))
        if (names.join('|') !== "The season|The schedule|The rules|The season's story") return `the desk season list reads ${JSON.stringify(names)}`
        const r0 = await deskMenuIs('The rules')(page); if (r0 !== true) return r0
        const y = await page.evaluate(() => window.scrollY)
        await page.evaluate(() => window.scrollTo(0, 0)); await page.waitForTimeout(400)
        const r1 = await deskMenuIs('The season')(page)
        await page.evaluate((y) => window.scrollTo(0, y), y); await page.waitForTimeout(400)
        return r1 !== true ? 'scrolled to the top, ' + r1 : deskMenuIs('The rules')(page)
      }) },
  /* TEN / W8 · W7-026 [X01] · UI_SYSTEM §13.3, keep what is on screen: the standings read fails on a REFRESH (the
     season page was read once), and the table that was on screen stays, wearing "As of … · couldn't refresh", instead
     of every squad drawn at 0 */
  { family: 'season', id: 'standings-stale', variant: 'member', title: 'The season page, the table, after a refresh of the standings failed (the last table stays, under its dateline)', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page, ctx) => {
      await toRoom(page, 'standings')
      ctx.world.errors.table.v_squad_standings = { __error: 'fixture: the standings read failed', status: 503 }
      await page.evaluate(() => window.loadStandingsAndFeed())
      await until(page, () => !!document.getElementById('standingsStale'), null, 10000)
      await page.waitForTimeout(400)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub', selectors: { '#standingsStale': 'text:^As of .* couldn.t refresh$' } },
    check: all(onNorthGrove, inViewport('#standings', 'the standings table'),
      has('#standings', 'Fixture Javelinas[\\s\\S]*171[\\s\\S]*Fixture Wrens[\\s\\S]*137', 'the last table stays (171 / 137), not every squad at 0'),
      async (page) => page.evaluate(() => {
        const t = document.getElementById('standingsStale')
        return t.getBoundingClientRect().top > document.getElementById('standings').getBoundingClientRect().bottom - 2 ? true : 'the dateline is not under the table'
      })) },
  /* TEN / W8 · W7-026 [X01] (follow-up) · the FIRST read of the standings fails (nothing was ever on screen to keep): the table says the read
     failed and offers the retry, not 'No rounds yet' or every squad at 0. The live region sits inside the cell, and the cell keeps its role. */
  { family: 'season', id: 'standings-failed', variant: 'member', title: 'The season page, the table, when the first read of the standings failed (the words and the retry)', fullPage: false,
    world: { errors: { table: { v_squad_standings: { __error: 'fixture: the standings read failed', status: 503 } } } },
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toRoom(page, 'standings')
      await until(page, () => !!document.getElementById('standingsRetry'), null, 10000)
      await page.evaluate(() => document.getElementById('standingsRetry').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub', selectors: { '#standingsRetry': 'visible', '#standings': 'text:Couldn.t load' } },
    check: all(onNorthGrove, ariaWellFormed('#standings'),
      async (page) => page.evaluate(() => {
        const box = document.querySelector('#standings [role="status"]'), td = document.querySelector('#standings td[colspan]')
        if (!box || !td || !td.contains(box)) return 'the live region is not inside the cell'
        if (!box.contains(document.getElementById('standingsRetry'))) return 'the retry is outside the live region'
        return /No rounds yet/i.test(document.getElementById('standings').innerText) ? 'a failed standings read says there are no rounds' : true
      })) },
  /* TEN / W8 · W7-026 [X01] (E5, D's second reader) · (1) the stats below the standings obey the same law: when the refresh of v_rounds_ranked and
     v_individual_standings fails, the last figures stay (Every golfer, the month tile, Up next) under an 'As of … · couldn't refresh' line — they used to be
     overwritten with [] and zeros, and the page said 'The race fills in once your league season is live' and '2 more toward September's minimum' */
  { family: 'season', id: 'stats-stale', variant: 'member', title: 'The season page, Every golfer, after a refresh of the stats failed (the last figures stay, under their dateline)', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page, ctx) => {
      await toRoom(page, 'standings')
      await page.evaluate(() => { const t = (id) => (document.getElementById(id) || {}).innerText || ''; window.__w8 = { ind: t('indTable'), count: t('statCount'), next: t('nextTxt'), rows: document.querySelectorAll('#indTable tr').length } })
      ctx.world.errors.table.v_individual_standings = { __error: 'fixture: the individual standings failed', status: 503 }
      ctx.world.errors.table.v_rounds_ranked = { __error: 'fixture: the ranked rounds failed', status: 503 }
      await page.evaluate(() => window.loadStandingsAndFeed())
      await until(page, () => !!document.getElementById('indStale'), null, 6000).catch(() => {})   /* the parent never draws it: the pins say what it drew instead */
      await page.evaluate(() => (document.getElementById('indStale') || document.getElementById('indTable')).scrollIntoView({ block: 'end' }))
      await scrollSettled(page)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub', selectors: { '#indStale': 'text:^As of .* couldn.t refresh$' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => {
      const w = window.__w8, t = (id) => (document.getElementById(id) || {}).innerText || ''
      if (w.rows < 8) return `the every-golfer table had ${w.rows} rows before the failure (the state is not the one it claims)`
      if (t('indTable') !== w.ind) return 'the every-golfer table changed when the refresh failed'
      if (/race fills in/i.test(t('indTable'))) return 'a failed refresh reads as an early season'
      if (t('statCount') !== w.count) return `the month tile changed from ${JSON.stringify(w.count)} to ${JSON.stringify(t('statCount'))}`
      if (t('nextTxt') !== w.next) return `Up next changed from ${JSON.stringify(w.next)} to ${JSON.stringify(t('nextTxt'))}`
      const stale = document.getElementById('indStale'), tbl = document.getElementById('indTable').closest('.tblwrap')
      return stale.getBoundingClientRect().top >= tbl.getBoundingClientRect().bottom - 2 ? true : 'the dateline is not under the table'
    })) },
  /* ...and (1b) a FIRST read that fails has nothing to keep: Every golfer says the read failed and offers the retry, never the early-season sentence */
  { family: 'season', id: 'stats-failed', variant: 'member', title: 'The season page, Every golfer, when the first read of the stats failed (the words and the retry)', fullPage: false,
    world: { errors: { table: { v_individual_standings: { __error: 'fixture: the individual standings failed', status: 503 }, v_rounds_ranked: { __error: 'fixture: the ranked rounds failed', status: 503 } } } },
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toRoom(page, 'standings')
      await until(page, () => !!document.getElementById('indRetry'), null, 8000).catch(() => {})   /* the parent never draws it: the pins say what it drew instead */
      await page.waitForTimeout(400)
      await page.evaluate(() => document.getElementById('indTable').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub', selectors: { '#indRetry': 'visible' } },
    check: all(onNorthGrove, ariaWellFormed('#indTable'), async (page) => page.evaluate(() => {
      const t = (id) => (document.getElementById(id) || {}).innerText || ''
      if (/race fills in/i.test(t('indTable'))) return 'a failed read says the race fills in once the season is live'
      if (/No rounds count yet/i.test(t('msAvgSub') + t('msBestSub'))) return 'a failed read says no rounds count'
      return /Couldn.t load this/.test(t('indTable')) ? true : 'the table does not say the read failed'
    })) },
  /* (2) what a failed read keeps is THIS league's: a golfer in two leagues whose season_story read fails on the second must not see the first league's story on
     its page (loadSeasonStory kept window.seasonStory on error, and resetToBlank, run on every switch, never cleared it) */
  { family: 'season', id: 'story-league-switch', variant: 'member', title: "The season page of the second league, after the story read failed on the switch (not the first league's story)", fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page, ctx) => {
      await toSeasonViaBand(page)
      await until(page, () => !!(window.seasonStory && window.seasonStory.season), null, 10000)
      ctx.world.errors.rpc.season_story = { __error: 'fixture: the story read failed', status: 503, code: 'XX000' }
      await page.evaluate((id) => window.enterLeagueById(id, false), SW.league)
      await until(page, () => /South Wash/.test((document.getElementById('seasonTitle') || {}).textContent || '') && !!document.getElementById('seasonStoryRetry'), null, 15000).catch(() => {})
      await page.waitForTimeout(400)
      await page.evaluate(() => document.getElementById('seasonArc').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub' },
    check: async (page) => page.evaluate(() => {
      const arc = (document.getElementById('seasonArc') || {}).innerText || ''
      if (!/South Wash/.test((document.getElementById('seasonTitle') || {}).textContent || '')) return 'the season page is not the second league\'s'
      if (/Fixture (Javelinas|Wrens)/i.test(arc)) return `the second league's page shows the first league's story: ${JSON.stringify(arc.slice(0, 80))}`
      return /Couldn.t load this/i.test(arc) && document.getElementById('seasonStoryRetry') ?   /* innerText carries the head's caps */
        true : 'the second league\'s story pane does not say the read failed'
    }) },
  /* Q34 (1) · owner ruling 2026-09-29: on the slat a long name wraps whole — no "abbreviate first, ellipsis last" (§9.1 yields
     to the program brief). South Wash Weekday is solo and seats the fixture's longest name, Indigo Longname-Fixturington. */
  { family: 'season', id: 'slat-long-name', variant: 'member', title: 'The season page of South Wash Weekday (solo): the slat with the longest name', fullPage: false,
    drive: async (page) => {
      await toSeasonViaBand(page)
      await page.evaluate((id) => window.enterLeagueById(id, false), SW.league)
      await until(page, () => /South Wash/.test((document.getElementById('seasonTitle') || {}).textContent || '') && /Longname/i.test((document.getElementById('view-hub') || {}).textContent || ''), null, 15000).catch(() => {})
      await page.waitForTimeout(500)
      await page.evaluate(() => { const n = [...document.querySelectorAll('#view-hub .tbl .tn')].find((el) => /Longname/i.test(el.textContent)); if (n) n.scrollIntoView({ block: 'center' }) })
      await scrollSettled(page)
    },
    expect: { view: 'view-hub' },
    check: namesWrapWhole('#view-hub .tbl .tn', 'Longname') },
  /* TEN / W8 · W7-026 [X01] · a story read that did not answer says so and offers the retry, not "The story starts when
     the first week closes" (the phone's storyRead == .failed) */
  { family: 'season', id: 'story-failed', variant: 'member', title: 'The season page, the story, when the story read failed', fullPage: false,
    world: { errors: { rpc: { season_story: { __error: 'fixture: the story read failed', status: 503, code: 'XX000' } } } },
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => !!document.getElementById('seasonStoryRetry'), null, 10000)
      await page.evaluate(() => document.getElementById('seasonStoryRetry').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expectConsole: [/status of 503/],
    expect: { view: 'view-hub', selectors: { '#seasonStoryRetry': 'visible', '#seasonArc': 'text:Couldn.t load this' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => /starts when the first week closes/i.test(document.getElementById('seasonArc').innerText) ? 'a failed story read says the story has not started' : true)) },
  /* TEN / W8 · W7-020 [A2-season-2] · the season page opened from HOME (Home's season door, csOpenSeason): the way back reads Home, and the
     tab band still marks COMPETE, as the event room's does */
  { family: 'season', id: 'from-home', variant: 'member', title: 'The season page opened from Home (the way back says Home)', fullPage: false, phoneOnly: true,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await page.evaluate((id) => window.csOpenSeason(id), NG.league)
      await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-hub' && !!(document.getElementById('seasonTitle') || {}).textContent, null, 12000)
      await page.evaluate(() => window.scrollTo(0, 0)); await page.waitForTimeout(500)
    },
    expect: { view: 'view-hub', selectors: { '#seasonBack': 'text:^Home$' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => {
      const b = document.getElementById('seasonBack'), on = [...document.querySelectorAll('.tab.active')].map((t) => t.dataset.v)
      return b.dataset.go === 'home' && on.join() === 'compete' ? true : `back → ${b.dataset.go}, tab band ${JSON.stringify(on)}`
    })) },
  /* TEN / W8 · W7-015 [B2-season-2] · the season album for a league whose rounds carry no photograph (every new league):
     the written empty state runs the whole row of the three-column grid, and has its door (LINT-21) */
  { family: 'season', id: 'album-empty', variant: 'member', world: { photo: 'none' }, title: 'The season page, the album, for a league with no photographs', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await page.evaluate(() => window.setRoomSeg('album'))
      await until(page, () => /Photos land here/.test((document.getElementById('albumGrid') || {}).innerText || ''), null, 10000)
      await page.evaluate(() => document.getElementById('albumGrid').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#albumGrid': 'text:Photos land here', '#albumGrid [data-empty-go]': 'visible' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => {
      const g = document.getElementById('albumGrid'), line = g.querySelector('.tempty')
      if (!line) return 'the empty album has no empty-state block'
      const w = line.getBoundingClientRect().width, gw = g.getBoundingClientRect().width
      return w >= gw * 0.98 ? true : `the empty line is ${Math.round(w)}px in a ${Math.round(gw)}px grid (one third of the row)`
    })) },
  /* TEN / W8 · the season page's board section (UI_SYSTEM §3.1 and §15.4, the same test as W7-029): the board's feed, and the composer under it */
  { family: 'season', id: 'board', variant: 'member', title: 'The season page, the board: the feed and the composer', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'board'); await page.waitForTimeout(400) },
    expect: { view: 'view-hub', selectors: { '#boardCard': 'visible', '#chatIn': 'visible' } },
    check: all(onNorthGrove, inViewport('#boardCard', 'the board'),
      /* the wrapper is the page's ground, and a post, a settled game and a moment are slats: no fill, no radius, no four-sided edge */
      noBoxes(['#boardCard', '#feedList .msgrow', '#feedList .sysrow', '#feedList .momrow', '#feedList .fcard']),
      async (page) => page.evaluate(() => {
        const list = document.getElementById('feedList'), box = list.getBoundingClientRect(), bad = []
        const rows = [...list.querySelectorAll('.msgrow, .sysrow, .momrow, .fcard')]
        if (!rows.length) return 'the board draws no post to judge'
        const top = (el) => getComputedStyle(el).borderTopWidth
        if (rows.some((r) => !r.previousElementSibling?.classList.contains('datesep') && top(r) !== '1px')) bad.push('a slat has no hairline above it')
        if (rows.some((r) => r.previousElementSibling?.classList.contains('datesep') && top(r) !== '0px')) bad.push('a slat under a date line draws a second rule')
        const pin = list.querySelector('.annrow.pin')
        if (pin && getComputedStyle(pin).backgroundColor === 'rgba(0, 0, 0, 0)') bad.push('the pinned note has no ground: the feed shows through it')
        /* the feed scrolls in its own height: while there is more below, it wears the scrollers' fade (the card's edge is gone) */
        const more = list.scrollTop + list.clientHeight < list.scrollHeight - 2
        if (more !== list.hasAttribute('data-more')) bad.push(`the feed ${more ? 'has more below and no fade' : 'has nothing below and a fade'}`)
        else if (more && !/linear-gradient/.test(getComputedStyle(list).maskImage || getComputedStyle(list).webkitMaskImage || '')) bad.push('the feed has more below and its fade is not drawn')
        for (const el of [...list.querySelectorAll('button, a[href], [tabindex]')].slice(0, 6)) {
          const r = el.getBoundingClientRect()
          if (r.width && (r.left - 4 < box.left - 0.5 || r.right + 4 > box.right + 0.5)) { bad.push(`a focus ring on ${JSON.stringify((el.getAttribute('aria-label') || el.textContent || el.className).trim().slice(0, 16))} would be clipped by the feed's own edge`); break }
        }
        return bad.length ? bad.join('; ') : true
      })) },
  /* TEN / W8 · K102 [X07] (D's delta at e78d7f22) · the season album reads again when a photograph is added: it read once per league per session, so the golfer who
     attached the first photograph to a round was still told 'Photos land here' — on the season page, and on coming back to it — until a reload. The photographs are
     attached through the app's own writer (csAttachRoundPhoto: an upload, set_round_photo, a signed URL), once with the season page open and once while on Home. */
  { family: 'season', id: 'album-refresh', variant: 'member', world: { photo: 'none' }, title: 'The season page, the album, after photographs were added to two rounds in the same session', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page, ctx) => {
      await toSeasonViaBand(page)
      await page.evaluate(() => window.setRoomSeg('album'))
      await until(page, () => /Photos land here/.test((document.getElementById('albumGrid') || {}).innerText || ''), null, 10000)
      const mine = ctx.world.tables.rounds.filter((r) => r.profile_id === ctx.world.me).slice(0, 2).map((r) => r.id)
      const attach = (rid) => page.evaluate(async (rid) => {
        const png = Uint8Array.from(atob('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg=='), (c) => c.charCodeAt(0))
        const out = await window.csAttachRoundPhoto(rid, new File([png], 'p.png', { type: 'image/png' }), null)
        return !!(out && out.ok)
      }, rid)
      const cells = (n) => until(page, (n) => document.querySelectorAll('#albumGrid .alcell').length >= n, n, 4000).catch(() => {})
      await attach(mine[0]); await cells(1)                                    /* (a) with the season page on screen: read again now */
      await page.evaluate(() => window.switchView('home')); await page.waitForTimeout(300)
      await attach(mine[1])                                                    /* (b) somewhere else: read again when the season page is opened */
      await page.evaluate(() => window.switchView('hub')); await cells(2)
      await page.evaluate(() => document.getElementById('albumGrid').scrollIntoView({ block: 'center' }))
      await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#albumGrid': 'visible' } },
    check: all(onNorthGrove, async (page) => page.evaluate(() => {
      const g = document.getElementById('albumGrid'), n = g.querySelectorAll('.alcell').length
      if (/Photos land here/.test(g.innerText)) return 'the album still says no photographs after two were added in this session'
      return n === 2 ? true : `the album shows ${n} photograph(s), expected the two just added`
    })) },
  /* TEN / W8 · W7-011 [B2-season-12] · the week clock, cropped: the weeks played are ink, the live week brand
     and tall, the weeks ahead mut — never rule (§16.1), so each reads as a state on the page's ground */
  { family: 'season', id: 'month-clock', variant: 'member', title: 'The season page, the week clock (its own crop)', shot: '#monthClock',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toSeasonViaBand(page); await until(page, () => document.querySelectorAll('#monthClock .t.played').length > 0); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#monthClock .t.played': 'visible', '#monthClock .t.now': 'visible' } },
    check: all(onNorthGrove, stateContrast([
      { sel: '#monthClock .t:not(.played):not(.now)', prop: 'backgroundColor', min: 4.5, what: 'the weeks ahead' },
      { sel: '#monthClock .t.played', prop: 'backgroundColor', min: 12, what: 'the weeks played' },
      { sel: '#monthClock .t.now', prop: 'backgroundColor', min: 3, what: 'the live week' }])) },
  /* TEN / W6 · X12 (W7-Q35, root's ruling) · the roster card as its Pro, the roster closed. The day before first tee Reopen shows
     (reopening opens the door); on first tee it is gone (the join gate refuses every joiner but the Pro from starts_on,
     join_window.sql:69) and the sub line stands alone. The Pro only: a member never has the control. */
  { family: 'season', id: 'roster-eve', variant: 'pro', title: 'The season page, the roster card as the Pro, closed the day before first tee (Reopen)', fullPage: false,
    prepare: rosterDay(1), drive: toLeagueRoster,
    expect: { view: 'view-hub', selectors: { '#rosterRow': 'visible', '#rosterOpen': 'visible' } },
    check: has('#rosterSub', '^You closed the roster\\. Add anyone yourself until the halfway turn', 'the closed roster’s sub line') },
  { family: 'season', id: 'roster-first-tee', variant: 'pro', title: 'The season page, the roster card as the Pro, closed on first tee (no Reopen)', fullPage: false,
    prepare: rosterDay(0), drive: toLeagueRoster,
    expect: { view: 'view-hub', selectors: { '#rosterRow': 'visible', '#rosterOpen': 'hidden' } },
    check: has('#rosterSub', '^You closed the roster\\. Add anyone yourself until the halfway turn', 'the closed roster’s sub line') },
  /* TEN / W8 · W7-008 [A2-season-1] · the season link's off switch is a word,
     and armed: the first tap says what the next one does and turns nothing off */
  { family: 'season', id: 'link-off', variant: 'member', title: 'The season page, the rules: the season link row at rest ("Link" and "Turn off")', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'league'); await page.locator('#hubSeasonRevoke').scrollIntoViewIfNeeded(); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#hubSeasonRevoke': 'text:^Turn off$' } },
    check: all(onNorthGrove, inViewport('#hubSeasonRevoke', 'the season link row')) },
  { family: 'season', id: 'link-armed', variant: 'member', title: 'The season page, the rules: "Turn off" tapped once (armed, not confirmed)', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'league'); await click(page, '#hubSeasonRevoke'); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#hubSeasonRevoke': 'text:^Sure\\? Turn it off$' } },
    check: all(onNorthGrove, inViewport('#hubSeasonRevoke', 'the season link row'),
      async (page) => page.evaluate(() => {
        const b = document.getElementById('hubSeasonRevoke')
        if (!b.classList.contains('is-armed') || b.dataset.armed !== '1') return 'the first tap did not arm the control'
        return (window.__tenNet || []).some((n) => /revoke_share|create_share/.test(n.url)) ? 'the first tap already turned the link off' : true
      })) },
]

/* ------------------------------------------------------------ compete */
const COMPETE = [
  { family: 'compete', id: 'empty', variant: 'brand_new', title: 'Compete · nothing running (a brand-new golfer)',
    drive: toCompete,
    expect: { view: 'view-compete', selectors: { '#cmpList .emptyroot h3': 'text:^Nothing running\\.$', '#cmpList [data-erdoor="startSomething"]': 'visible', '#cmpList [data-erdoor="joinWithCode"]': 'visible' } },
    check: async (page) => page.evaluate(() => document.querySelector('#cmpList [data-cband], #cmpList .peerrow') ? 'a season or a moment rendered for a golfer with none' : true) },
  { family: 'compete', id: 'populated', variant: 'member', title: 'Compete · the Scoreboard (North Grove), a second season, the moments, the finished shelf',
    prepare: async (W) => { ryderWorld(W) },
    drive: async (page) => { await toCompete(page); await until(page, () => /North Grove Ryder/.test((document.getElementById('cmpFinished') || {}).innerText || '')) },
    expect: { view: 'view-compete', selectors: { '#cmpList [data-cband] .cband-name': 'text:^North Grove \\(fixture\\)$', '#cmpBookDoor': 'text:Open the Book|Rounds' } },
    /* W5 · the band names the side whose standing it states (137 and 2nd are
       Fixture Wrens', the golfer's squad), and the moments ride the second
       column (#cmpMoments) — beside the seasons on the desk, after them on
       the phone */
    check: all(has('#cmpList [data-cband]', '137[\\s\\S]*Fixture Wrens · 2nd[\\s\\S]*34 back of Fixture Javelinas\\.', 'the band (137 points, Fixture Wrens 2nd, 34 back of, W7-130: the table\'s own noun)'),
      /* TEN / W8 · W7-130 [A2-competition-3]: the sidebar's season row stands down on Compete: the band prints the standing (rank, points, gap) itself */
      standsDown(['#sideMe [data-mego="season_row"]']), bandHint,
      /* TEN / W8 · W7-028: the Book door is marked by a 2px mut rule under its label, not by the row's hairline */
      tertiaryDoor('#cmpBookDoor'),
      has('#cmpList', 'South Wash Weekday \\(fixture\\)', 'the second season'),
      has('#cmpMoments', 'The North Grove Ryder \\(fixture\\)', 'the live Ryder in the moments'),
      has('#cmpFinished', 'The North Grove Ryder \\(fixture\\)', 'the finished Ryder on the shelf')) },
]

/* ------------------------------------------------------------ the Book */
/* the Book dialog, loaded: the read answered and the body replaced the
   loading line (or the error replaced it) */
const bookOpen = (page) => until(page, () => { const d = document.getElementById('seasonBookDialog'); const m = d && d.querySelector('.sb-main'); return !!d && d.open && !!m && !/Loading the whole season/.test(m.textContent) }, null, 10000)
async function bookFromCompete(page) {
  await toCompete(page)
  await until(page, () => !!document.getElementById('cmpBookDoor'))
  await tapUntil(page, '#cmpBookDoor', () => { const d = document.getElementById('seasonBookDialog'); return !!d && d.open })
  await bookOpen(page)
  await page.waitForTimeout(300)
}
async function bookFromSeason(page) {
  await until(page, () => { const d = document.getElementById('seasonBookDoor'); return !!d && !d.hidden && d.offsetParent !== null }, null, 10000)
  await tapUntil(page, '#seasonBookDoor', () => { const d = document.getElementById('seasonBookDialog'); return !!d && d.open })
  await bookOpen(page)
  await page.waitForTimeout(300)
}
/* the Book the page validated is the envelope the world adopted */
const bookIs = (want) => async (page) => page.evaluate((want) => {
  const d = document.getElementById('seasonBookDialog'); if (!d || !d.open) return 'the Book is not open'
  const t = d.innerText.replace(/\s+/g, ' ')
  if (want.title && (d.querySelector('#sb-title') || {}).textContent !== want.title) return `the Book is titled ${JSON.stringify((d.querySelector('#sb-title') || {}).textContent)}`
  if (want.head && !t.includes(want.head)) return `the Book's head does not read ${JSON.stringify(want.head)}`
  if (d.querySelector('.sb-main [role="alert"]') && !want.alert) return 'the Book shows an error: ' + d.querySelector('.sb-main [role="alert"]').textContent
  return true
}, want)
/* the Scoreboard the door sat under says the same standing the Book does */
const bandSays = (re, what) => async (page) => page.evaluate(({ re, what }) => {
  const b = document.querySelector('#cmpList [data-cband]'); if (!b) return 'no Scoreboard band on Compete'
  const t = b.innerText.replace(/\s+/g, ' ')
  return new RegExp(re).test(t) ? true : `the Scoreboard (${what}) reads ${JSON.stringify(t.slice(0, 200))}`
}, { re, what })
const adopt = (name, opts) => async (W) => { adoptBook(W, readBook(name), opts) }
const BOOK_LS = (name) => ({ cs_last_league: readBook(name).league_id })

/* TEN / W8 · W7-135 [A2-competition-18] · the Book grid is ONE Tab stop with a roving tabindex (it was up to 256 buttons and no arrow keys): exactly one button holds tabindex 0, the region is not a stop of its own,
   Left/Right move along a row (its name is the first stop), Up/Down along a week, Home/End to a row's ends (a future week's disabled button is skipped), and 'Skip to adjustments' moves to that heading */
const bookGridKeys = async (page) => {
  const info = await page.evaluate(() => {
    const m = document.querySelector('#seasonBookDialog .sb-matrix'), btns = [...m.querySelectorAll('tbody button')]
    return { total: btns.length, zero: btns.filter((b) => b.tabIndex === 0).length, region: m.getAttribute('tabindex') }
  })
  if (info.zero !== 1) return `${info.zero} of ${info.total} grid buttons are Tab stops, expected one`
  if (info.region === '0') return 'the grid region is still a Tab stop of its own'
  const at = (r, c) => page.evaluate(([r, c]) => { const b = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr')][r].querySelectorAll('button')[c]; b.focus(); return true }, [r, c])
  const where = () => page.evaluate(() => { const a = document.activeElement, rows = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr')], ri = rows.findIndex((tr) => tr.contains(a)); return { ri, ci: ri < 0 ? -1 : [...rows[ri].querySelectorAll('button')].indexOf(a), week: a && a.dataset ? a.dataset.bookWeek : null } })
  await at(0, 1); await page.keyboard.press('ArrowRight')
  let w = await where(); if (w.ri !== 0 || w.ci !== 2) return `ArrowRight from week 1 lands on row ${w.ri} button ${w.ci}, expected row 0 button 2`
  await page.keyboard.press('ArrowDown'); w = await where(); if (w.ri !== 1 || w.ci !== 2) return `ArrowDown lands on row ${w.ri} button ${w.ci}, expected row 1 button 2`
  await page.keyboard.press('ArrowUp'); w = await where(); if (w.ri !== 0 || w.ci !== 2) return 'ArrowUp does not go back up'
  await page.keyboard.press('ArrowLeft'); await page.keyboard.press('ArrowLeft'); w = await where(); if (w.ri !== 0 || w.ci !== 0) return `two ArrowLefts land on button ${w.ci}, expected the row's name`
  await page.keyboard.press('End'); w = await where();
  const last = await page.evaluate(() => { const r = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr')][0]; return [...r.querySelectorAll('button')].filter((b) => !b.disabled).length - 1 })
  if (w.ri !== 0 || w.ci !== last) return `End lands on button ${w.ci}, expected the last enabled cell (${last})`
  await page.keyboard.press('Home'); w = await where(); if (w.ci !== 0) return `Home lands on button ${w.ci}, expected the row's name`
  const skipped = await page.evaluate(() => {
    const link = document.querySelector('#seasonBookDialog [data-sb-skip]'); if (!link) return 'no Skip to adjustments link'
    link.focus(); link.click(); const h = document.getElementById('sb-adjust')
    return document.activeElement === h ? true : `Skip to adjustments leaves the focus on ${document.activeElement && (document.activeElement.id || document.activeElement.tagName)}`
  })
  await page.evaluate(() => { const a = document.activeElement; if (a && a.blur) a.blur() })
  return skipped
}
/* TEN / W8 · W7-070 [A2-competition-1] · the Book's start edge: while earlier weeks sit behind the pinned name column (it opens on the live week) the mirror of the end fade says so
   (data-more-start, drawn from the name column's right edge), and from 1440 the dialog is wide enough for a 15-week season to show whole */
const bookStartEdge = async (page) => page.evaluate(() => {
  const dlg = document.getElementById('seasonBookDialog'), wrap = dlg && dlg.querySelector('.sb-matrix-wrap'), m = wrap && wrap.querySelector('.sb-matrix')
  if (!wrap || !m) return true
  const scrolled = m.scrollLeft > 2
  if (scrolled !== wrap.hasAttribute('data-more-start')) return `data-more-start is ${wrap.hasAttribute('data-more-start')} with scrollLeft ${Math.round(m.scrollLeft)}`
  if (scrolled && parseFloat(getComputedStyle(wrap, '::before').opacity) < 1) return 'earlier weeks sit behind the name column and the start edge draws nothing'
  if (innerWidth >= 1440 && dlg.getBoundingClientRect().width < 1500) return `the Book is ${Math.round(dlg.getBoundingClientRect().width)}px wide at ${innerWidth}px`
  return true
})
/* the Cup Final's race of the golfers, from the season page (W5: the Book's controls are segments, one component, UI_SYSTEM §7.2, each chosen by its button) */
async function raceDrive(page) {
  await toSeasonViaBand(page)
  await until(page, () => { const w = document.getElementById('cupRaceWrap'); return !!w && w.style.display !== 'none' && document.querySelectorAll('#cupRace tr').length >= 2 }, null, 10000)
  await bookFromSeason(page)
  await click(page, '#seasonBookDialog #sb-group [data-v="golfer"]')
  await until(page, () => !!document.querySelector('#seasonBookDialog #sb-mode'))
  await click(page, '#seasonBookDialog #sb-mode [data-v="Race"]')
  await until(page, () => !!document.querySelector('#seasonBookDialog svg.sb-race'))
  await page.waitForTimeout(300)
}
/* TEN / W8 · W7-131 [A2-competition-5] · the Race display reads heading, CHART, sentence (the four-line paragraph stood between the controls and the chart), and Follow (up to 17 names) is one
   closed disclosure, so the chart's first half is in the first screen at every width */
/* TEN / W8 · W7-124 [A2-competition-17] · the Race's end label starts at week N's own point (as 'Week 1' does), so it lies right of the 'Now' rule and never sits under it: 'Week 15' centred under
   'Now · W13' read as if week 13 were week 15 */
const raceEndLabel = async (page) => page.evaluate(() => {
  const svg = document.querySelector('#seasonBookDialog svg.sb-race'), now = svg && svg.querySelector('.sb-current-line')
  const end = svg && [...svg.querySelectorAll('.sb-race-axis')].find((t) => /^Week \d+$/.test(t.textContent) && t.textContent !== 'Week 1')
  if (!svg || !now || !end) return 'the race has no end label or no Now rule'
  const l = end.getBoundingClientRect(), n = now.getBoundingClientRect()
  return l.left >= n.right - 0.5 ? true : `the end label (${Math.round(l.left)}-${Math.round(l.right)}) runs under the Now rule at ${Math.round(n.left)}`
})
const raceOrder = async (page) => page.evaluate(() => {
  const main = document.querySelector('#seasonBookDialog .sb-main'), h2 = main.querySelector('h2'), svg = main.querySelector('svg.sb-race')
  const said = [...main.querySelectorAll('p')].find((p) => /^Each golfer’s points as they count today/.test(p.textContent))
  if (!h2 || !svg || !said) return 'the Race lacks its heading, chart or sentence'
  const after = (a, b) => !!(a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING)
  if (!after(h2, svg) || !after(svg, said)) return 'the Race does not read heading, chart, sentence'
  const f = main.querySelector('details.sb-follow')
  if (!f) return 'Follow is not a disclosure'
  if (f.open) return 'the Follow disclosure opens already open'
  const top = svg.getBoundingClientRect().top, half = svg.getBoundingClientRect().height / 2
  if (top + half > innerHeight) return `the chart starts ${Math.round(top)}px down a ${innerHeight}px screen: its first half is not in view`
  return true
})
/* the pick: Follow closes, its summary names the golfer and holds the focus, and the chart's first line is theirs */
const followPicked = async (page) => page.evaluate(() => {
  const f = document.querySelector('#seasonBookDialog details.sb-follow'), sum = f && f.querySelector('summary'), pick = window.__followPick
  if (!f || !pick) return 'no Follow pick was made'
  if (f.open) return 'the Follow disclosure stayed open after a pick'
  if (sum.textContent.trim() !== `Follow · ${pick}`) return `the summary reads ${JSON.stringify(sum.textContent.trim())}, not Follow · ${pick}`
  if (document.activeElement !== sum) return `the focus is on ${document.activeElement && (document.activeElement.id || document.activeElement.tagName)}, not on the Follow summary`
  const lead = document.querySelector('#seasonBookDialog .sb-race-lab.is-lead')
  if (!lead || !lead.textContent.startsWith(pick)) return `the chart's first line reads ${JSON.stringify(lead && lead.textContent)}, not ${pick}`
  return true
})
const BOOK = [
  { family: 'book', id: 'upcoming', variant: 'rounds_no_league', title: 'The Book before the first tee (The Autumn Fixture Cup, week 0 of 15), from the Scoreboard', fullPage: false,
    prepare: adopt('upcoming'), localStorage: BOOK_LS('upcoming'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-main': 'text:No standing yet\\. Weeks begin at first tee\\.' } },
    check: all(bookIs({ title: 'The Book', head: 'The Autumn Fixture Cup · Season 1 · Oct 5 – Jan 17, 2027' }),
      bandSays('The first tee is Mon Oct 5', 'upcoming'),
      async (page) => page.evaluate(() => document.querySelector('#seasonBookDialog .sb-matrix') ? 'a matrix rendered before the first tee' : true)) },
  { family: 'book', id: 'squads', variant: 'rounds_no_league', title: 'The Book, four squads in week 13 (North Grove, the squads envelope), from the Scoreboard', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-matrix': 'visible', '#seasonBookDialog #sb-group': 'visible', '#seasonBookDialog .sb-matrix th.sb-current': 'text:W13' } },
    check: all(bookIs({ title: 'The Book', head: 'North Grove (fixture) · Season 1 · Jul 6 – Oct 18, 2026' }),
      bandSays('326[\\s\\S]*3rd', 'squads: 3rd, 326 points'), bookStartEdge, bookGridKeys,
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr')]
        if (rows.length !== 4) return `${rows.length} squad rows, expected 4`
        const names = rows.map((r) => r.querySelector('th').innerText.split('\n')[0].trim())
        if (names.join('|') !== 'Fixture Quail|Fixture Wrens|Fixture Javelinas|Fixture Gilas') return 'squad order ' + names.join('|')
        return document.querySelectorAll('#seasonBookDialog .sb-adjustment').length >= 3 ? true : 'the adjustments in the totals are missing'
      })) },
  /* TEN / W8 · W7-134 [A2-competition-16] · 'Open the round's receipt' CLOSED the Book with no way back to the cell being read: the round's sheet, dismissed (Escape here; the × and the backdrop take the same path),
     puts the reader back on the same cell: the Book reopened on the same view, squad, display and follow, that cell's receipt open and the cell marked. The Book's round ids are not the world's, so the state gives
     the world a round for each entry of the cell (Avery's, cloned) and the sheet can open one. */
  { family: 'book', id: 'receipt-return', variant: 'rounds_no_league', fullPage: false, title: 'The Book, after the round opened from a cell\u2019s receipt is dismissed: the reader is back on the cell (Fixture Javelinas, week 12)',
    prepare: async (W) => {
      adoptBook(W, readBook('squads'))
      const b = readBook('squads'), row = b.rows.find((r) => r.id === 'squad:c50b0000-0000-4000-8000-000000000300'), base = W.tables.rounds.find((r) => r.profile_id === W.ids.uid(1))
      for (const e of row.entries.filter((x) => x.week === 12 && x.round_id)) if (!W.tables.rounds.some((r) => r.id === e.round_id)) W.tables.rounds.push(Object.assign({}, base, { id: e.round_id }))
    },
    localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await bookFromCompete(page)
      const row = await page.evaluate(() => {
        const th = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody th button')].find((b) => /^Fixture Javelinas/.test(b.innerText.trim()))
        return th ? th.dataset.bookRow : null
      })
      if (row == null) throw new Error('no Fixture Javelinas row in the Book')
      await click(page, `#seasonBookDialog .sb-matrix td button[data-book-row="${row}"][data-book-week="12"]`)
      await until(page, () => /Fixture Javelinas · Week 12/.test((document.querySelector('#seasonBookDialog .sb-receipts h2') || {}).textContent || ''))
      await page.evaluate((row) => { window.__w8Cell = { row, week: '12' } }, row)
      await click(page, '#seasonBookDialog .sb-receipts [data-book-round]')
      await until(page, () => !document.getElementById('seasonBookDialog') && document.getElementById('sheet').classList.contains('open'), null, 12000)
      await page.waitForTimeout(800)
      await page.keyboard.press('Escape')
      await until(page, () => { const d = document.getElementById('seasonBookDialog'); return !!d && d.open && !!d.querySelector('[data-book-row][aria-current="true"]') && /Fixture Javelinas · Week 12/.test((d.querySelector('.sb-receipts h2') || {}).textContent || '') }, null, 12000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-receipts h2': 'text:^Fixture Javelinas \u00b7 Week 12$' } },
    check: async (page) => page.evaluate(() => {
      const d = document.getElementById('seasonBookDialog'); if (!d || !d.open) return 'the Book is not open after the round was dismissed'
      if (document.getElementById('sheet').classList.contains('open')) return 'the round\u2019s sheet is still open'
      const marked = [...d.querySelectorAll('[data-book-row][aria-current="true"]')]
      if (marked.length !== 1) return `${marked.length} cells are marked, expected the one that was open`
      if (marked[0].dataset.bookRow !== window.__w8Cell.row || marked[0].dataset.bookWeek !== window.__w8Cell.week) return `the marked cell is row ${marked[0].dataset.bookRow} week ${marked[0].dataset.bookWeek}, not the one that was open`
      const g = d.querySelector('#sb-group [aria-pressed="true"]'), m = d.querySelector('#sb-mode [aria-pressed="true"]')
      if (!g || g.dataset.v !== 'squad' || !m || m.dataset.v !== 'Weeks') return 'the Book did not keep its view and display'
      const sc = d.querySelector('.sb-matrix'), r = marked[0].getBoundingClientRect(), s = sc.getBoundingClientRect()
      if (r.right < s.left || r.left > s.right) return 'the marked cell is scrolled out of the grid'
      if (window.csBookReturn) return 'the return was not cleared once used'
      return true
    }) },
  /* EXPECTED TO FAIL on current source. The Scoreboard names a season's state
     in one of three words (F11: Upcoming · Live · Final). Seven days before
     this season's first tee its row facts already say "No standing yet. First
     tee is ahead." -- and the band beside them says LIVE, on the live ember.
     csCompeteList (index.html:19787) calls a season Upcoming only when
     home_dispatch's `season.week_no === 0`, and native_home never sends 0 (it
     clamps to week 1 and says `days_to_first_tee` instead -- book-home's own
     record of the server: week_no 1, days_to_first_tee 11); its fallback reads
     `lg.season.status`, which loadMemberships (index.html:27537) never
     selects, so every season in phase `season` is Live from the lock on. */
  { family: 'book', id: 'scoreboard-upcoming', variant: 'rounds_no_league', title: 'The Scoreboard seven days before the first tee (The Autumn Fixture Cup): the state word',
    prepare: adopt('upcoming'), localStorage: BOOK_LS('upcoming'),
    drive: toCompete,
    expect: { view: 'view-compete', selectors: { '#cmpList [data-cband] .cband-name': 'text:^The Autumn Fixture Cup$', '#cmpBookDoor': 'visible' } },
    /* W5 · the upcoming band says WHEN — the first tee's day from the payload
       (it said "No standing yet. First tee is ahead.", "not yet" twice) */
    check: all(bandSays('The first tee is Mon Oct 5', 'upcoming facts'),
      async (page) => page.evaluate(() => {
        const b = document.querySelector('#cmpList [data-cband]'), w = (b.querySelector('.cband-state') || {}).textContent
        return w === 'Upcoming' && b.dataset.live !== 'true' ? true : `the band says ${JSON.stringify(w)} (data-live=${b.dataset.live}) for a season whose first tee is 2026-10-05 -- the Compete row's state tests season.week_no===0 (csCompeteRows), and native_home sends week_no 1 with days_to_first_tee for an upcoming season`
      })) },
  /* the Cup Final: the tick flipped the season on ends_on − 27 and seeded the
     top two; the season page leads with the race (cup_final_race) and the
     Book, opened from the season page's own door, is drawn as the race of the
     golfers (the squads' race cannot plot: one late squad correction sits
     outside the season weeks, and the Book says so rather than drop it) */
  { family: 'book', id: 'race', variant: 'rounds_no_league', title: 'The Book in the Cup Final: the race of the golfers, from the season page (cup_final_race behind)', fullPage: false,
    prepare: async (W) => { adoptBook(W, readBook('squads')); cupFinalOn(W, readBook('squads').season_id) }, localStorage: BOOK_LS('squads'),
    drive: raceDrive,
    expect: { view: 'view-hub', selectors: { '#seasonBookDialog svg.sb-race': 'visible', '#seasonBookDialog .sb-follow > summary': 'text:^Follow · Leading three$' } },
    check: all(bookIs({ title: 'The Book' }), raceOrder, raceEndLabel, tertiaryDoor('#seasonBookDialog .sb-follow > summary'),
      has('#cupRace', 'Fixture Quail[\\s\\S]*Fixture Wrens|Fixture Wrens[\\s\\S]*Fixture Quail', 'the Cup Final race behind the Book'),
      async (page) => page.evaluate(() => {
        const svg = document.querySelector('#seasonBookDialog svg.sb-race')
        if (svg.querySelectorAll('.sb-race-path').length !== 3) return `${svg.querySelectorAll('.sb-race-path').length} race lines, expected 3`
        if (!svg.querySelector('.sb-current-line')) return 'no current-week line in the Cup Final'
        return window.CS && window.CS.season && window.CS.season.status === 'cup_final' ? true : 'the season is not in its Cup Final'
      })) },
  /* TEN / W8 · W7-068 [X05] · the season page in the Cup Final: the locked clinch line names the state 'The Final is set' (TERMINOLOGY row 141, the phone's ScenarioLine), never 'Seeds set' (seed is not a verb) */
  { family: 'season', id: 'cup-final', variant: 'rounds_no_league', title: 'The season page in the Cup Final: the clinch line says the Final is set', fullPage: false,
    prepare: async (W) => { adoptBook(W, readBook('squads')); cupFinalOn(W, readBook('squads').season_id) }, localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => { const b = document.getElementById('scenarioLine'); return !!b && b.style.display !== 'none' && b.textContent.trim().length > 0 }, null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-hub', selectors: { '#scenarioLine': 'visible' } },
    check: all(has('#scenarioLine', '^The Final is set: .+ (is|are) in\\.$', 'the locked clinch line (W7-071: a sentence)'), ptsHead('#cupRace'),
      async (page) => page.evaluate(() => /seeds? set/i.test(document.getElementById('scenarioLine').textContent) ? 'the clinch line still says Seeds set' : true)) },
  /* W7-131 · the same race after a pick: Follow is opened, the second golfer chosen, and the disclosure closes on their name with the focus on its summary */
  { family: 'book', id: 'race-follow', variant: 'rounds_no_league', title: 'The Book in the Cup Final: the race following one golfer (Follow opened, a golfer picked)', fullPage: false,
    prepare: async (W) => { adoptBook(W, readBook('squads')); cupFinalOn(W, readBook('squads').season_id) }, localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await raceDrive(page)
      await click(page, '#seasonBookDialog .sb-follow > summary')
      await until(page, () => document.querySelector('#seasonBookDialog details.sb-follow').open)
      await page.evaluate(() => { window.__followPick = document.querySelectorAll('#seasonBookDialog #sb-follow [data-v]')[2].textContent.trim() })
      await click(page, '#seasonBookDialog #sb-follow [data-v]:nth-of-type(3)')
      await until(page, () => !document.querySelector('#seasonBookDialog details.sb-follow').open && !!document.querySelector('#seasonBookDialog svg.sb-race'))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-hub', selectors: { '#seasonBookDialog svg.sb-race': 'visible', '#seasonBookDialog .sb-follow > summary': 'visible' } },
    check: all(bookIs({ title: 'The Book' }), followPicked, tertiaryDoor('#seasonBookDialog .sb-follow > summary')) },
  { family: 'book', id: 'tie', variant: 'rounds_no_league', title: 'Rounds & points, two golfers level at the top (The Saturday Fixture Cup), from the Scoreboard', fullPage: false,
    prepare: adopt('tie'), localStorage: BOOK_LS('tie'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-totals': 'visible' } },
    check: all(bookIs({ title: 'Rounds & points', head: 'The Saturday Fixture Cup · Season 1' }),
      bandSays('1st · Tied[\\s\\S]*The lead is shared\\.', 'tie'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#seasonBookDialog .sb-totals button')].map((b) => b.innerText.replace(/\s+/g, ' ').trim())
        if (rows.length !== 2) return `${rows.length} totals, expected 2`
        return rows.every((r) => /1st · Tied/.test(r) && /41 pts/.test(r)) ? true : 'the totals read ' + JSON.stringify(rows)
      })) },
  /* a finished season has no Scoreboard band (it waits on Compete's finished
     shelf); its Book opens from the season page */
  { family: 'book', id: 'finished', variant: 'rounds_no_league', title: 'The Book of a complete season (The Summer Fixture Cup), from the finished shelf and the season page', fullPage: false,
    /* the one-time ceremony (openSeasonCeremony) was seen the night the season closed */
    prepare: adopt('finished'), localStorage: { ...BOOK_LS('finished'), ['cs_cer_' + readBook('finished').season_id]: '1' },
    drive: async (page) => {
      await toCompete(page)
      const L = readBook('finished').league_id
      await tapUntil(page, `#cmpFinished [data-peer="league:${L}"]`, () => (document.querySelector('.view.active') || {}).id === 'view-hub')
      await bookFromSeason(page)
    },
    expect: { view: 'view-hub', selectors: { '#seasonBookDialog .sb-matrix': 'visible' } },
    check: all(bookIs({ title: 'The Book', head: 'These are the lines the season closed with. Later rule changes, posts and deletions do not move them.' }),
      async (page) => page.evaluate(() => {
        const rows = document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr').length
        if (rows !== 16) return `${rows} golfer rows, expected 16`
        return document.querySelector('#seasonBookDialog .sb-matrix th.sb-current') ? 'a complete season marks a current week' : true
      }),
      /* Q34 (1) · the Book's pinned names wrap whole: no initial, no ellipsis, no word broken or run past the column */
      namesWrapWhole('#seasonBookDialog .sb-matrix tbody th button', 'Longname')) },
  { family: 'book', id: 'error', variant: 'rounds_no_league', title: 'The Book when its read fails: the error and Try again', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    world: { errors: { rpc: { season_book: { __error: 'fixture: the Book read failed', status: 503, code: 'XX000' } } } },
    expectConsole: [/status of 503/],
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-main [role="alert"]': 'text:^The Book did not load\\. Try again\\.$', '#seasonBookDialog #sb-retry': 'visible' } },
    check: async (page) => page.evaluate(() => (window.__tenNet || []).some((e) => /\/rpc\/season_book/.test(e.url) && e.status === 503) ? true : 'season_book was not read (or did not fail)') },
  /* a real cell: my squad's week 12, the week before the capture's */
  { family: 'book', id: 'cell-receipt', variant: 'rounds_no_league', title: 'The Book, a cell’s receipt: Fixture Javelinas in week 12', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await bookFromCompete(page)
      const row = await page.evaluate(() => {
        const th = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody th button')].find((b) => /^Fixture Javelinas/.test(b.innerText.trim()))
        return th ? th.dataset.bookRow : null
      })
      if (row == null) throw new Error('no Fixture Javelinas row in the Book')
      await click(page, `#seasonBookDialog .sb-matrix td button[data-book-row="${row}"][data-book-week="12"]`)
      await until(page, () => /Fixture Javelinas · Week 12/.test((document.querySelector('#seasonBookDialog .sb-receipts h2') || {}).textContent || ''))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-receipts h2': 'text:^Fixture Javelinas · Week 12$', '#seasonBookDialog .sb-receipts .sb-total': 'visible' } },
    check: all(async (page) => page.evaluate(() => {
      /* TEN / W8 · W7-129 [A2-competition-2]: the cell whose receipt is open is MARKED: exactly one, aria-current, and drawn (a 2px inset ring in ink, never ember); below 900px the receipt
         opens with a 44px 'Back to the grid' link that returns focus to that cell */
      const marked = [...document.querySelectorAll('#seasonBookDialog [data-book-row][aria-current="true"]')]
      if (marked.length !== 1) return `${marked.length} cells are marked as the open receipt, expected one`
      const cs = getComputedStyle(marked[0]), probe = document.createElement('i'); probe.style.color = 'var(--ink)'; document.body.appendChild(probe); const ink = getComputedStyle(probe).color; probe.remove()
      if (!cs.boxShadow || cs.boxShadow === 'none' || !cs.boxShadow.includes(ink) || !/inset/.test(cs.boxShadow)) return `the marked cell draws no ink ring (${cs.boxShadow})`
      const back = document.querySelector('#seasonBookDialog .sb-receipts .sb-back')
      if (innerWidth <= 900) {
        if (!back || back.textContent.trim() !== 'Back to the grid') return 'the phone\'s receipt has no way back to the grid'
        return back.getBoundingClientRect().height >= 43.5 ? true : `the way back is ${Math.round(back.getBoundingClientRect().height)}px tall`
      }
      return back ? 'the desk shows a way back beside a grid that is in view' : true
    }), async (page) => {
      const b = readBook('squads')
      const row = b.rows.find((r) => r.id === 'squad:c50b0000-0000-4000-8000-000000000300')
      const es = row.entries.filter((e) => e.week === 12)
      const want = { n: es.length, total: es.reduce((s, e) => s + e.contribution, 0) }
      return page.evaluate((want) => {
        const box = document.querySelector('#seasonBookDialog .sb-receipts')
        const n = box.querySelectorAll('.sb-entry').length
        const total = parseInt(box.querySelector('.sb-total').textContent, 10)
        if (n !== want.n) return `${n} receipt entries, the envelope holds ${want.n}`
        if (total !== want.total) return `the receipt totals ${total}, the envelope ${want.total}`
        const r = box.getBoundingClientRect()
        return r.top < innerHeight - 40 && r.bottom > 40 ? true : 'the receipt is scrolled out of view'
      }, want)
    }, async (page) => page.evaluate(() => {
      /* last: the way back scrolls the marked cell into view and focuses it (it moves the page, so it runs after the receipt's own checks) */
      const back = document.querySelector('#seasonBookDialog .sb-receipts .sb-back'), marked = document.querySelector('#seasonBookDialog [data-book-row][aria-current="true"]')
      if (!back) return true
      back.click()
      return document.activeElement === marked ? true : 'the way back does not focus the marked cell'
    })) },
]

/* ------------------------------------------------------------ events */
const E_LIVE = ids.event(12), E_DONE = ids.event(11), E_GHOST = ids.event(999)
async function eventFromCompete(page, sel, id) {
  await toCompete(page)
  await until(page, (sel) => !!document.querySelector(sel), sel)
  await tapUntil(page, sel, (id) => (document.querySelector('.view.active') || {}).id === 'view-event' && !!window.CS_EVENT && (window.CS_EVENT.event === null || ['failed', 'unavailable'].includes(window.CS_EVENT.state) || (window.CS_EVENT.event || {}).id === id), id)
  await until(page, () => (document.getElementById('eventBody') || {}).innerText.trim().length > 0)
  await page.waitForTimeout(400)
}
/* TEN / W8 · W7-156 [A2-events-1] · the Ryder room: the golfer's own clash is FIRST in its week and reads 'You' (in the row and in its spoken sentence), and the rules paragraph,
   the taunt and the organiser's controls come AFTER the weeks (they stood a screen and a half above the clash on a phone) */
/* TEN / W8 · W7-153 [A2-events-9, B2-events-7] · the roster's record columns are headed with words, 'Won', 'Lost', 'Halved' (the phone's recordLegend), in sentence case, each on its figures' edge and none clipped
   ('W L H' was never spelled: 'H' least of all) */
/* TEN / W8 · W7-152 [A2-events-5, B2-events-3] · 'Tell me when <opponent> posts' is offered while the opponent has NOT posted this week; once their figure is on the board the ask is for the next one, 'Tell me when
   <opponent> posts again' (it read as a promise about a post already made, a few rows above the figure that said so) */
const tauntAsk = async (page) => page.evaluate(() => {
  const E = window.CS_EVENT || {}, meU = window.CS.user.id, me = (E.players || []).find((p) => p.profile_id === meU)
  const btn = [...document.querySelectorAll('#eventBody button.mini')].find((b) => /^(Tell me when|Mute the taunts)/.test(b.textContent.trim()))
  if (!me || !btn) return 'the room draws no taunt button for the viewer'
  if (/^Mute/.test(btn.textContent.trim())) return true
  const open = (E.sessions || []).find((s) => s.status === 'open'), duel = open && (E.duels || []).find((d) => d.session_id === open.id && (d.a_player === me.id || d.b_player === me.id))
  const t = duel && (E.targets || {})[duel.id], posted = !!t && (duel.a_player === me.id ? t.b : t.a) != null
  const again = / posts again$/.test(btn.textContent.trim())
  return posted === again ? true : `the opponent ${posted ? 'has' : 'has not'} posted and the button reads ${JSON.stringify(btn.textContent.trim())}`
})
const rosterHeads = async (page) => page.evaluate(() => {
  const heads = [...document.querySelectorAll('#eventBody .evrrow-hd')].filter((h) => h.getBoundingClientRect().width > 0)
  if (!heads.length) return 'no roster head is drawn'
  for (const h of heads) {
    const cells = [...h.children].slice(2), words = cells.map((c) => c.textContent.trim())
    if (words.join('|') !== 'Won|Lost|Halved') return `a roster head reads ${JSON.stringify(words)}, expected Won, Lost, Halved`
    if (getComputedStyle(h).textTransform !== 'none') return 'the roster head is set in caps, not the sentence-case phrase'
    const row = h.nextElementSibling; if (!row || !row.classList.contains('evrrow')) return 'no roster row follows the head'
    const figs = [...row.querySelectorAll('.cs-col-m')]
    for (let i = 0; i < 3; i++) {
      if (cells[i].scrollWidth > cells[i].clientWidth + 1) return `${JSON.stringify(words[i])} is clipped in its column`
      if (Math.abs(cells[i].getBoundingClientRect().right - figs[i].getBoundingClientRect().right) > 1) return `${JSON.stringify(words[i])} is not on its figure's edge`
    }
  }
  return true
})
const ryderOrder = async (page) => page.evaluate(() => {
  const weeks = [...document.querySelectorAll('#eventBody .evsess')]
  if (!weeks.length) return 'the room draws no week'
  const rules = [...document.querySelectorAll('#eventBody p.fine')].find((p) => /Each week pairs everyone/.test(p.textContent))
  if (!rules) return 'the rules paragraph is missing'
  if (weeks.some((w) => w.compareDocumentPosition(rules) & Node.DOCUMENT_POSITION_PRECEDING)) return 'the rules paragraph is still above a week'
  let mineWeeks = 0
  for (const w of weeks) {
    const clashes = [...w.querySelectorAll('.evclash')], mine = clashes.filter((c) => /(^| )You( |$)/.test(c.getAttribute('aria-label') || ''))
    if (!mine.length) continue
    mineWeeks++
    if (clashes[0] !== mine[0]) return `the viewer's clash is not first in its week: ${JSON.stringify((clashes[0].getAttribute('aria-label') || '').slice(0, 60))}`
    /* textContent, not innerText: a finished week is a closed <details>, whose rows have no box and so no innerText at all (and the role's caps would say YOU) */
    const sides = ['.nm.a', '.nm.b'].map((q) => (mine[0].querySelector(q).textContent || '').trim())
    if (!sides.includes('You')) return `the viewer's side does not read You in the row: ${JSON.stringify(sides)}`
  }
  return mineWeeks ? true : 'no week holds the viewer\'s clash (the state is not the one it claims)'
})
const EVENTS = [
  /* W5 (4a703402) moved Compete's moments into their own column, #cmpMoments;
     the events states tap the row where it now lives */
  { family: 'events', id: 'live', variant: 'member', title: 'The event room · a live Ryder, week 3 of 3, from Compete’s moments',
    prepare: async (W) => { ryderWorld(W) },
    drive: (page) => eventFromCompete(page, `#cmpMoments [data-peer="event:${E_LIVE}"]`, E_LIVE),
    /* W2 2026-09-28 · the side scores ride the plate now (owner H: the score
       was under the fold at 375), so the rail below it is gone; and the
       series line says the holder once — "hold the Ryder 1–0 · Fixture Hawks
       hold it" was one fact twice (owner C, category C, critique-B P3). */
    expect: { view: 'view-event', selectors: { '#eventBody h1': 'text:^The North Grove Ryder \\(fixture\\)$', '#eventBody .evbrow': 'text:Live · week 3 of 3 · 2 days left', '#eventBody .evside .fig': 'visible' } },
    check: all(has('#eventBody .evclinch', 'First to 6½\\. Fixture Hawks need 1, Fixture Bobcats need 4\\.', 'the clinch line'),
      has('#eventBody', 'Still to post: [^.]*Emery[^.]*Harper|Still to post: [^.]*Harper[^.]*Emery', 'the open week’s still-to-post line'),
      has('#eventBody', 'The 2nd Ryder · Fixture Hawks hold it, 1–0', 'the series line (event_lineage)'),
      has('#eventBody', 'Fixture Hawks lead 5½–2½ after week 2\\.', 'the board’s week-2 line'),
      /* TEN / W8 · W7-K040 [B2-events-10]: the Ryder page does not own the season standing, it competes with it: the sidebar's season row stands down beside its two sides */
      standsDown(['#sideMe [data-mego="season_row"]']), ryderOrder, rosterHeads, tauntAsk,
      async (page) => page.evaluate(() => Object.keys((window.CS_EVENT || {}).targets || {}).length === 4 ? true : 'event_session_targets did not reach the four open duels')) },
  { family: 'events', id: 'finished', variant: 'member', title: 'The event room · a finished Ryder (Fixture Hawks 7–5), from Compete’s finished shelf',
    prepare: async (W) => { ryderWorld(W) },
    drive: (page) => eventFromCompete(page, `#cmpFinished [data-peer="event:${E_DONE}"]`, E_DONE),
    expect: { view: 'view-event', selectors: { '#eventBody h1': 'text:^The North Grove Ryder \\(fixture\\)$', '#eventBody .evbrow': 'text:^Final · ' } },
    check: all(has('#eventBody .evclinch', '^Final\\. Fixture Hawks took it 7–5\\.$', 'the result line'),
      has('#eventBody', 'Fixture Hawks take The North Grove Ryder \\(fixture\\) 7–5\\. Devon is MVP at 3-0-0\\.', 'the settlement post'),
      async (page) => page.evaluate(() => [...document.querySelectorAll('#eventBody button')].some((b) => /Run it back/.test(b.textContent)) ? true : 'no Run it back')) },
  /* an id nobody holds -- the stale link, the event scrapped while the list
     was open -- through the page's own router */
  /* S8 (root f6d30196 / d86b15ad): the room's own recovery plate. A read
     that comes back with no row is `unavailable` (no retry: removed, or not
     on the roster); a read that fails is `failed` (Try again). */
  { family: 'events', id: 'unavailable', variant: 'member', title: 'The event room · an event id that does not resolve (the recovery plate: not open to you)',
    expectConsole: [/status of 406/],
    drive: async (page) => {
      await page.evaluate((id) => window.openEvent(id), E_GHOST)
      await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-event' && !!window.CS_EVENT && (window.CS_EVENT.state === 'unavailable' || window.CS_EVENT.event === null), null, 10000)
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-event', minText: 10, selectors: { '#evrecHead': 'text:Not open to you', '[data-go-compete]': 'visible', '#evRetry': 'hidden' } },
    check: async (page) => page.evaluate((id) => (window.__tenNet || []).some((e) => e.url.includes('/rest/v1/events') && e.url.includes(id) && (e.status === 406 || e.status === 200)) ? true : 'the event read did not come back empty', E_GHOST) },
  { family: 'events', id: 'failed-read', variant: 'member', title: 'The event room · the event read fails, from Compete (the recovery plate: didn’t load, Try again)',
    prepare: async (W) => {
      ryderWorld(W)
      W.errors.when = [...(W.errors.when || []), { table: 'events', match: (q) => q.includes('id=eq.' + E_LIVE), error: { __error: 'fixture: the event read failed', status: 503 } }]
    },
    expectConsole: [/status of 503/, /\[event\]/, /^\[cs\] error:\s+fixture: the event read failed/],
    drive: async (page) => {
      await eventFromCompete(page, `#cmpMoments [data-peer="event:${E_LIVE}"]`, E_LIVE).catch(() => {})
      await until(page, () => !!window.CS_EVENT && window.CS_EVENT.state === 'failed' && !!document.getElementById('evRetry'), null, 15000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-event', minText: 10, selectors: { '#evrecHead': 'text:Didn.t load', '#evRetry': 'visible', '[data-go-compete]': 'visible' } },
    check: async (page) => page.evaluate((id) => (window.__tenNet || []).some((e) => e.url.includes('/rest/v1/events') && e.url.includes(id) && e.status === 503) ? true : 'the event read did not fail', E_LIVE) },
]

/* ------------------------------------------------------------ print */
/* TEN / W8 · W7-013 [B2-season-14] · the season page AS PRINTED. A probe, run with `--only print --widths 816`: print
   media at a paper's width (816 CSS px is Letter at 96dpi), because a sheet is laid out at the page's width and not the
   window's. From the dark or the light default the sheet prints the light printing: every token the light theme
   flips (held to tokens.json, so a drifted print block fails here), the main text darker than the secondary text, and
   both at AA on the paper. */
/* TEN / W8 · W7-014 [B2-season-14] (E3, D's second reader) · the sheet measured with the print dialog's DEFAULT: background graphics OFF. A fill is dropped unless the sheet
   asks for it (print-color-adjust: exact), and ink that assumed the fill is then ink on white. For the live season's name, standfirst and eyebrow, the leader's rank
   tile and the viewer's, the ink's contrast against the ground it will really land on (the nearest ancestor fill that PRINTS, else the paper) is at least 4.5 */
const printedInk = async (page) => page.evaluate(() => {
  const rgb = (c) => (c.match(/[\d.]+/g) || []).slice(0, 4).map(Number)
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }
  const lum = (c) => { const [r, g, b] = rgb(c); return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05) }
  const prints = (el) => { const cs = getComputedStyle(el); return (cs.printColorAdjust || cs.webkitPrintColorAdjust) === 'exact' }
  const ground = (el) => { for (let n = el; n && n.nodeType === 1; n = n.parentElement) { const bg = getComputedStyle(n).backgroundColor; if (rgb(bg).length === 4 && rgb(bg)[3] === 0) continue; if (prints(n)) return bg } return 'rgb(255, 255, 255)' }
  const parts = [['#seasonEyebrow, #seasonDateline', 'the eyebrow'], ['#seasonTitle', "the season's name"], ['#seasonLead', 'the standfirst'], ['#standings tr.lead .rk, #indTable tr.lead .rk', "the leader's rank tile"]]
  const bad = []
  for (const [sel, what] of parts) {
    const el = document.querySelector(sel); if (!el || !(el.getBoundingClientRect().width > 0)) continue
    const c = getComputedStyle(el).color, g = ground(el), r = ratio(c, g)
    if (r < 4.5) bad.push(`${what} prints ${c} on ${g}: ${r.toFixed(2)}:1`)
  }
  return bad.length ? 'with background graphics off the sheet prints ink that assumed a fill: ' + bad.join('; ') : true
})
const PRINT = [
  { family: 'print', id: 'season', variant: 'member', probe: true, title: 'The season page as printed (print media, paper width), from the dark or the light default',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'standings'); await page.emulateMedia({ media: 'print' }); await page.waitForTimeout(500) },
    expect: { view: 'view-hub' },
    check: all(onNorthGrove, async (page) => page.evaluate((want) => {
      const cs = getComputedStyle(document.documentElement)
      const bad = Object.entries(want).filter(([n, v]) => cs.getPropertyValue('--' + n).trim().toLowerCase() !== v.toLowerCase()).map(([n, v]) => `--${n} is ${cs.getPropertyValue('--' + n).trim()}, the light printing is ${v}`)
      return bad.length ? `the sheet does not print the light printing (${bad.length} of ${Object.keys(want).length} tokens): ` + bad.slice(0, 3).join('; ') : true
    }, LIGHT_PRINTING),
    stateContrast([{ sel: '#standingsStory', prop: 'color', min: 4.5, what: 'the story (ink) on the paper' },
      { sel: '#standings th', prop: 'color', min: 4.5, what: 'a column head (mut) on the paper' }]),
    printedInk,
    async (page) => page.evaluate(() => {
      const l = (c) => { const v = (c.match(/[\d.]+/g) || []).slice(0, 3).map(Number).map((x) => { x /= 255; return x <= 0.03928 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4 }); return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2] }
      const ink = l(getComputedStyle(document.querySelector('#standingsStory')).color), mut = l(getComputedStyle(document.querySelector('#standings th')).color)
      return ink < mut ? true : 'the main text prints lighter than the secondary text'
    })) },
]

export default [...SEASON, ...COMPETE, ...BOOK, ...EVENTS, ...PRINT]
