#!/usr/bin/env node
/* F06 web half, and the course page's own residuals.
   · the lead plate holds its whole name: a four-line course name at 375 used
     to lose its first line off the plate's top edge;
   · the card folds like a real one: the front nine and the back, each with
     its OUT / IN column, whole at 375, 402 and in the desk column; where a nine
     cannot fit (320) the figures scroll under a key that stays put;
   · the card reads as a table: "Hole 3", "Yards", "Handicap";
   · the sentence shows whole, keeps its name when filled, grows as it is
     typed, and Enter saves it (rate_course is stubbed in-page);
   · a long course name in the list gets the measure, not one word a line;
   · the page never scrolls sideways.
   Everything is synthetic and local; every supabase.co request is aborted.

     node tests/course-leaf-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null); if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 600))) }

/* the synthetic books: an 18 with three-digit yardage and a long name (the
   lead), a liked 18 with a longer one, and an unrated nine */
const holes = (n, yards) => [...Array(n).keys()].map(i => ({ hole: i + 1,
  par: [4, 5, 3, 4, 4, 4, 3, 5, 4, 4, 3, 5, 4, 4, 3, 4, 5, 4][i], si: [7, 1, 15, 11, 3, 9, 17, 5, 13, 8, 16, 2, 10, 4, 18, 12, 6, 14][i],
  yards: yards ? 360 + ((i * 37) % 180) : null }))
const tee = (name, n, yards) => { const hs = holes(n, yards); return { tee_name: name, gender: 'male', course_rating: n === 9 ? 34.6 : 71.8, slope_rating: n === 9 ? 112 : 129,
  number_of_holes: n, total_yards: yards ? hs.reduce((a, h) => a + h.yards, 0) : null, par_total: hs.reduce((a, h) => a + h.par, 0), holes: hs } }
const LEAD = { id: 'fixture-wash', club_name: 'Mesquite Wash Golf Club (Fixture)', course_name: 'Mesquite Wash', city: 'Scottsdale', state: 'AZ',
  savedAt: Date.now(), usedAt: Date.now(), tees: [tee('Black', 18, true)] }
const LONG = { id: 'fixture-pines', club_name: 'The Championship Course at Whispering Fixture Pines Country Club', course_name: 'Championship', city: 'Gold Canyon', state: 'AZ',
  savedAt: Date.now(), usedAt: Date.now() - 1000, tees: [tee('Tournament Tips', 18, true)] }
const NINE = { id: 'fixture-nine', club_name: 'Dry Creek Nine (Fixture)', course_name: 'Dry Creek', city: 'Tempe', state: 'AZ',
  savedAt: Date.now(), usedAt: Date.now() - 2000, tees: [tee('Forward', 9, false)] }
const NOTE = 'Greens roll true and fast all year. The 14th will ruin a card, and the walk from 9 to 10 is longer than it looks.'
const RATINGS = {
  [LEAD.id]: { stars: 4.0, count: 5, friends: 4.0, friends_count: 3, mine: 4.5, note: NOTE, notes: [] },
  [LONG.id]: { stars: 4.0, count: 2, friends: null, friends_count: 0, mine: 4.0, note: 'Bring a sleeve for the par 3s.', notes: [] },
}

const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [320, 375, 402, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(({ t, books, ratings }) => {
    try { localStorage.setItem('cs_theme', t); localStorage.setItem('cs.courses.v1', JSON.stringify(books)); localStorage.setItem('cs.ratings.v1', JSON.stringify(ratings)) } catch (e) {}
  }, { t: theme, books: [LEAD, LONG, NINE], ratings: RATINGS })
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof renderCourseBooks === 'function' && typeof csCourseLeafHtml === 'function', null, { timeout: 20000 })
  await page.evaluate(() => document.fonts.ready)
  const label = `${width} ${theme}`
  await page.evaluate((lead) => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false; CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
    switchView('stats')
    window.CS_COURSE_LEAD = lead
    renderCourseBooks()
    /* W2 (f46086b4) put the full book behind You's "Your courses" door; a
       golfer opens it before reading or typing, so the suite does too — in a
       closed <details> the sentence cannot take focus and nothing measures */
    const door = document.getElementById('youCoursesDoor'); if (door) door.open = true
    document.getElementById('youCourses').scrollIntoView({ block: 'start' })
  }, LEAD.id)
  await page.waitForTimeout(150)

  /* ---- the plate holds its name */
  const plate = await page.evaluate(() => {
    const p = document.querySelector('#youCourses .cs-course .cs-plate'), c = p.querySelector('.cs-plate-copy'), n = p.querySelector('.cs-name')
    const pr = p.getBoundingClientRect(), cr = c.getBoundingClientRect(), nr = n.getBoundingClientRect()
    const lines = Math.round(nr.height / parseFloat(getComputedStyle(n).lineHeight))
    return { contained: cr.top >= pr.top - 0.5 && cr.bottom <= pr.bottom + 0.5 && nr.top >= pr.top, ratio: +(pr.width / pr.height).toFixed(2), lines, h: Math.round(pr.height) }
  })
  check(`${label}: the lead plate holds its whole name (${plate.lines} lines, ${plate.h}px, ${plate.ratio}:1)`, plate.contained && plate.ratio <= 2.61, plate)

  /* ---- the card folds, and fits or scrolls under a pinned key */
  const leaf = await page.evaluate(() => {
    const leaf = document.querySelector('#youCourses .cs-course .cs-leaf'), box = leaf.querySelector('.cs-nines')
    const tables = [...box.querySelectorAll('table')]
    const t0 = tables[0]
    const sum = (t, row) => [...t.querySelectorAll(`tbody tr${row} td:not(.tot)`)].reduce((a, td) => a + Number(td.textContent || 0), 0)
    const ydsRow = [...t0.querySelectorAll('tbody tr')].find(tr => tr.querySelector('th').textContent === 'YDS')
    /* the closest two figures in the widest row, ink to ink */
    const ink = [...ydsRow.querySelectorAll('td')].map(td => { const r = document.createRange(); r.selectNodeContents(td); return r.getBoundingClientRect() })
    let gap = Infinity; for (let i = 1; i < ink.length; i++) gap = Math.min(gap, ink[i].left - ink[i - 1].right)
    return {
      tables: tables.length, heads: tables.map(t => t.querySelector('thead th.tot').textContent),
      cols: tables.map(t => t.querySelectorAll('thead th[scope="col"]').length),
      captions: tables.map(t => t.caption && t.caption.textContent),
      keys: [...t0.querySelectorAll('th[scope="row"]')].map(th => th.getAttribute('aria-label') || th.textContent),
      holeNames: [...t0.querySelectorAll('thead th[scope="col"]')].slice(0, 9).map(th => th.getAttribute('aria-label')),
      outYds: ydsRow.querySelector('td.tot').textContent, outYdsSum: sum(t0, ''), parOut: t0.querySelector('tbody tr.par td.tot').textContent,
      fits: box.scrollWidth <= box.clientWidth + 1, over: box.scrollWidth - box.clientWidth, gap: +gap.toFixed(1),
      leafRight: leaf.getBoundingClientRect().right, colRight: leaf.parentElement.getBoundingClientRect().right,
    }
  })
  const outYdsWant = LEAD.tees[0].holes.slice(0, 9).reduce((a, h) => a + h.yards, 0)
  check(`${label}: the card is two nines, OUT and IN, each with its total column`, leaf.tables === 2 && leaf.heads.join() === 'OUT,IN' && leaf.cols.join() === '10,10', leaf)
  check(`${label}: the OUT column adds up (${leaf.outYds} yds, par ${leaf.parOut})`, Number(leaf.outYds) === outYdsWant && leaf.parOut === '36', { leaf, outYdsWant })
  check(`${label}: it reads as a table — ${leaf.keys.join(' / ')}; "${leaf.holeNames[2]}"; "${leaf.captions.join('", "')}"`,
    leaf.keys.join() === 'HOLE,Yards,PAR,Handicap' && leaf.holeNames.every((n, i) => n === `Hole ${i + 1}`) && leaf.captions.join() === 'The front nine,The back nine', leaf)
  check(`${label}: two figures never touch (closest ${leaf.gap}px apart)`, leaf.gap >= 3, leaf)
  check(`${label}: the leaf stays inside its column`, leaf.leafRight <= leaf.colRight + 0.5, leaf)
  if (width >= 375) {
    check(`${label}: a nine with yardage prints whole, no sideways scroll`, leaf.fits, leaf)
  } else {
    check(`${label}: a nine that cannot fit scrolls inside the leaf (${leaf.over}px)`, !leaf.fits, leaf)
    const pinned = await page.evaluate(() => {
      const box = document.querySelector('#youCourses .cs-course .cs-nines'), key = box.querySelector('tbody th[scope="row"]')
      const at0 = key.getBoundingClientRect().left
      box.scrollLeft = box.scrollWidth
      const br = box.getBoundingClientRect(), kr = key.getBoundingClientRect(), tot = box.querySelector('tbody td.tot').getBoundingClientRect()
      const bgKey = getComputedStyle(key).backgroundColor, bgLeaf = getComputedStyle(box.closest('.cs-leaf')).backgroundColor
      const out = { moved: +(kr.left - at0).toFixed(1), keyLeft: +(kr.left - br.left).toFixed(1), totInside: tot.right <= br.right + 1, bgKey, bgLeaf }
      box.scrollLeft = 0
      return out
    })
    check(`${label}: scrolled to its end, the key stays put over the figures (moved ${pinned.moved}px) and OUT is reachable`,
      Math.abs(pinned.moved) <= 0.5 && Math.abs(pinned.keyLeft) <= 0.5 && pinned.totInside && pinned.bgKey === pinned.bgLeaf, pinned)
  }
  /* the nine-hole tee: one block, OUT, no invented yardage */
  const nine = await page.evaluate(() => {
    const d = document.createElement('div'); d.innerHTML = csCourseLeafHtml(csBookHoles(csCourseGet('fixture-nine')))
    const t = d.querySelectorAll('table')
    return { n: t.length, head: t[0].querySelector('thead th.tot').textContent, yds: /YDS/.test(d.textContent), cols: t[0].querySelectorAll('thead th[scope="col"]').length }
  })
  check(`${label}: a nine-hole tee is one block with its OUT column and no yardage row`, nine.n === 1 && nine.head === 'OUT' && !nine.yds && nine.cols === 10, nine)

  /* ---- the sentence */
  const note = await page.evaluate(() => {
    const ta = document.querySelector('#youCourses textarea[data-csnote]')
    const lab = ta && document.querySelector(`label[for="${ta.id}"]`), why = ta && document.getElementById(ta.getAttribute('aria-describedby'))
    const col = ta.closest('.cs-course > div').getBoundingClientRect(), r = ta.getBoundingClientRect()
    return { label: lab && lab.textContent, why: why && why.textContent, value: ta.value, whole: ta.scrollHeight <= ta.clientHeight + 1, h: ta.clientHeight,
      inside: r.left >= col.left - 0.5 && r.right <= col.right + 0.5 }
  })
  check(`${label}: the sentence shows whole (${note.h}px), inside its column`, note.value === NOTE && note.whole && note.inside, note)
  check(`${label}: it keeps its name when filled ("${note.label}") and says who reads it`, note.label === 'What you thought' && /buddies see it/.test(note.why || ''), note)
  const grown = await page.evaluate(() => {
    const ta = document.querySelector('#youCourses textarea[data-csnote]'), before = ta.clientHeight
    ta.value = ta.value + ' The shop sells the best burrito in the valley, and the range balls are new.'
    ta.dispatchEvent(new Event('input', { bubbles: true }))
    return { before, after: ta.clientHeight, whole: ta.scrollHeight <= ta.clientHeight + 1 }
  })
  check(`${label}: it grows as it is typed (${grown.before} → ${grown.after}px)`, grown.after > grown.before && grown.whole, grown)
  await page.evaluate(() => {
    window.__rpc = []
    window.sb.rpc = async (fn, args) => { window.__rpc.push({ fn, args }); return { data: { stars: 4.1, count: 6, friends: 4.0, friends_count: 3, mine: args.p_stars, mine_note: args.p_note }, error: null } }
    const ta = document.querySelector('#youCourses textarea[data-csnote]'); ta.value = 'Fast greens,\nslow pace.'; ta.dispatchEvent(new Event('input', { bubbles: true }))
  })
  await page.focus('#youCourses textarea[data-csnote]')
  await page.keyboard.press('Enter')
  await page.waitForFunction(() => window.__rpc.length > 0, null, { timeout: 3000 }).catch(() => {})
  const saved = await page.evaluate(() => ({ rpc: window.__rpc, focused: document.activeElement?.matches?.('textarea[data-csnote]'), value: document.querySelector('#youCourses textarea[data-csnote]').value }))
  check(`${label}: Enter saves the sentence as one line ("${saved.rpc[0]?.args?.p_note}")`,
    saved.rpc.length === 1 && saved.rpc[0].fn === 'rate_course' && saved.rpc[0].args.p_note === 'Fast greens, slow pace.' && !saved.focused && saved.value === 'Fast greens, slow pace.', saved)

  /* ---- a long name in the list gets the measure */
  const row = await page.evaluate(() => {
    const k = document.querySelector('#youCourses .cs-krow[data-cslead="fixture-pines"]'), h = k.querySelector('h4'), rail = k.querySelector('.cs-krow-rate')
    const kr = k.getBoundingClientRect(), hr = h.getBoundingClientRect(), rr = rail.getBoundingClientRect()
    return { nameW: Math.round(hr.width), rowW: Math.round(kr.width), lines: Math.round(hr.height / parseFloat(getComputedStyle(h).lineHeight)), railBelow: rr.top >= hr.bottom - 1 }
  })
  check(`${label}: a long course name gets the measure (${row.nameW} of ${row.rowW}px, ${row.lines} lines${row.railBelow ? ', rating beneath' : ''})`,
    row.nameW >= Math.min(240, row.rowW) && (row.rowW >= 600 || row.railBelow), row)

  /* ---- TEN / W6 · AW2-09 (WCAG 4.1.2): a row is not a button. A button's
     children are presentational, so the row's own card disclosure fell out of
     the accessibility tree while it stayed in the Tab order. The course NAME
     is the row's one button; the disclosure is exposed and works from the
     keyboard, and opening it never moves the lead. (This moves the lead, so
     it runs after every check that reads the lead.) */
  const rows = await page.evaluate(() => [...document.querySelectorAll('#youCourses .cs-krow[data-cslead]')].map(k => {
    const sm = k.querySelector('details.cs-cardleaf > summary')
    return { id: k.dataset.cslead, role: k.getAttribute('role'), tabindex: k.getAttribute('tabindex'), label: k.getAttribute('aria-label'),
      buttons: [...k.querySelectorAll('button')].map(b => b.textContent.replace(/\s+/g, ' ').trim()),
      name: (k.querySelector('h4')?.textContent || '').replace(/\s+/g, ' ').trim(),
      summary: sm ? sm.textContent.replace(/\s+/g, ' ').trim() : null, summaryInButton: !!(sm && sm.parentElement.closest('button,[role=button]')) }
  }))
  check(`${label}: no course row is a button; each names its course once, on its own button (${rows.length} rows)`,
    rows.length >= 2 && rows.every(r => !r.role && r.tabindex == null && !r.label && r.buttons.length === 1 && r.buttons[0] === r.name && !r.summaryInButton), rows)
  {
    const cdp = await ctx.newCDPSession(page)
    await cdp.send('Accessibility.enable')
    const { nodes } = await cdp.send('Accessibility.getFullAXTree')
    await cdp.detach().catch(() => {})
    /* the tree carries a caps role's text-transform into the name, so the
       names are compared without case */
    const named = (n) => (n.name && n.name.value || '').replace(/\s+/g, ' ').trim().toLowerCase()
    const live = nodes.filter(n => !n.ignored)
    const ax = rows.map(r => ({ id: r.id,
      nameButtons: live.filter(n => n.role && n.role.value === 'button' && named(n) === r.name.toLowerCase()).length,
      card: r.summary == null ? 'none' : live.filter(n => named(n) === r.summary.toLowerCase()).map(n => n.role && n.role.value).join(',') || 'MISSING' }))
    check(`${label}: the accessibility tree has each row's name button once and each row's card disclosure`,
      ax.every(a => a.nameButtons === 1 && a.card !== 'MISSING'), ax)
  }
  {
    const target = rows[0].id
    const named = await page.focus(`#youCourses .cs-krow[data-cslead="${target}"] .cs-krow-open`).then(() => true, () => false)
    if (named) { await page.keyboard.press('Enter'); await page.waitForTimeout(350) }
    const lead1 = await page.evaluate(() => String(window.CS_COURSE_LEAD))
    check(`${label}: Enter on a course's name makes it the lead`, lead1 === String(target), lead1)
    const other = await page.evaluate(() => { const s = document.querySelector('#youCourses .cs-krow[data-cslead] details.cs-cardleaf > summary'); return s ? s.closest('.cs-krow').dataset.cslead : null })
    if (other) {
      await page.focus(`#youCourses .cs-krow[data-cslead="${other}"] details.cs-cardleaf > summary`).catch(() => {})
      await page.keyboard.press('Enter'); await page.waitForTimeout(250)
      const after = await page.evaluate((id) => ({ open: !!document.querySelector(`#youCourses .cs-krow[data-cslead="${id}"] details.cs-cardleaf`)?.open, lead: String(window.CS_COURSE_LEAD) }), other)
      check(`${label}: Enter on a row's card opens the card and leaves the lead`, after.open && after.lead === String(target), after)
    } else check(`${label}: a row carries a card to open`, false, rows)
  }

  /* ---- the page */
  const page0 = await page.evaluate(() => document.documentElement.scrollWidth - innerWidth)
  check(`${label}: the page does not scroll sideways`, page0 <= 0, page0)
  check(`${label}: no page errors`, errs.length === 0, errs)
  if (SHOTS) { await page.evaluate(() => document.getElementById('youCourses').scrollIntoView({ block: 'start' })); await page.locator('#youCourses').screenshot({ path: join(SHOTS, `course--${width}--${theme}.png`) }) }
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
