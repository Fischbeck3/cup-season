#!/usr/bin/env node
/* F10 · You says what it knows: a record with nothing in it says so ONCE, at
   Recent rounds, with the one next step; a failed read never claims "no
   rounds"; a record shows its sections. Synthetic identities; Supabase is
   aborted, so the retry path is a real failed read.

     node tests/you-record-states-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null); if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || (process.env.HOME || '') + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const row = (i, gross, pvi) => ({ id: 'r' + i, gross, differential: 10, played_on: `2026-09-${String(20 - i).padStart(2, '0')}`, course_label: 'North Grove (fixture)', holes_played: 18, pvi, beat: pvi >= 1 })
const CASES = {
  empty: { career: { rounds: 0, rows: [], best: null, avg: null, counting: 0, recent: [] }, careerState: 'ready', trophies: [] },
  failed: { career: null, careerState: 'failed', trophies: [] },
  one: { career: { rounds: 1, rows: [row(1, 88, -1.4)], best: -1.4, avg: -1.4, counting: 1, recent: [row(1, 88, -1.4)] }, careerState: 'ready', trophies: [] },
  populated: { career: { rounds: 12, rows: [1, 2, 3, 4, 5].map(i => row(i, 80 + i, 2 - i)), best: 1, avg: -1, counting: 12, recent: [1, 2, 3, 4, 5].map(i => row(i, 80 + i, 2 - i)) }, careerState: 'ready', trophies: [{ id: 't1', kind: 'cup', title: 'The Fixture Cup', season_year: 2026 }] },
}
const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [375, 1280]) for (const theme of ['dark', 'light']) for (const [name, fx] of Object.entries(CASES)) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t); localStorage.removeItem('cs.courses.v1') } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => typeof switchView === 'function' && window.CS && typeof renderCareer === 'function', null, { timeout: 15000 })
  await page.waitForTimeout(300)
  await page.evaluate(fx => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false
    CS.user = { id: '00000000-0000-4000-8000-00000000f1f1', email: 'avery@example.invalid' }
    CS.profile = { id: CS.user.id, display_name: 'Avery Fixture', handle: 'fixture_avery', marker: 'saguaro' }
    CS.memberships = []; CS.league = null
    /* the real signed-in, no-league shell (showWelcome), and the golfer's own card */
    try { showWelcome() } catch (e) { document.body.classList.add('noleague') }
    state.demo = false
    refreshWhoChip()
    window.career = fx.career; window.careerState = fx.careerState
    window.trophies = fx.trophies; window.achievements = []; window.careerRec = null
    switchView('stats')
    renderCareer(); renderTrophyCase(); renderCareerRecord(); renderCourseBooks()
  }, fx)
  await page.waitForTimeout(120)
  const v = await page.evaluate(() => {
    const shown = el => !!el && el.getClientRects().length > 0
    const view = document.getElementById('view-stats')
    const texts = [...view.querySelectorAll('h3, h4, p, small, .v')].filter(shown).map(e => e.textContent.trim())
    const absence = texts.filter(t => /no rounds|the case is empty|nothing kept|none yet|no rounds count/i.test(t))
    return {
      record: view.dataset.record,
      absence,
      /* W7-115 · the empty record's one line is its headline, under a drawn object and an eyebrow */
      emptyHeads: [...view.querySelectorAll('#youRecent .tempty h3')].filter(shown).map(e => e.textContent.trim()),
      trophies: shown(document.getElementById('trophyCase')),
      /* W2 2026-09-28 · the all-time figures are a strip on a rule now
         (#youAllTime), not the bordered `.stats` tiles */
      allTime: shown(view.querySelector('#youAllTime[data-rec="some"]')),
      courses: shown(document.getElementById('youCourses')),
      door: [...view.querySelectorAll('[data-empty-go="record"]')].filter(shown).map(b => ({ tag: b.localName, h: b.getBoundingClientRect().height })),
      retry: shown(document.getElementById('youRecentRetry')),
      failedLine: texts.some(t => /didn’t load/.test(t)),
      recentRows: view.querySelectorAll('#youRecent .yrow').length,
    }
  })
  const label = `${width} ${theme} ${name}`
  if (name === 'empty') {
    check(`${label}: says its one empty line ONCE (${JSON.stringify(v.emptyHeads)})`, v.record === 'empty' && v.absence.length === 0 && v.emptyHeads.length === 1 && /^Your record fills as you play\.$/.test(v.emptyHeads[0]), v)
    check(`${label}: trophies, all-time and empty courses wait for the record`, !v.trophies && !v.allTime && !v.courses, v)
    check(`${label}: one next step, a real 44px control`, v.door.length === 1 && v.door[0].tag === 'button' && v.door[0].h >= 44, v.door)
  }
  if (name === 'failed') {
    check(`${label}: a failed read never claims "no rounds"`, v.record === 'failed' && !v.absence.some(t => /no rounds yet/i.test(t)) && v.failedLine && v.retry, v)
    /* the retry is a real read: Supabase is refused here, so it fails again, honestly */
    await page.click('#youRecentRetry')
    await page.waitForFunction(() => document.getElementById('view-stats').dataset.record === 'failed' && !!document.getElementById('youRecentRetry') && !document.getElementById('youRecentRetry').disabled, null, { timeout: 15000 })
    check(`${label}: Try again reads again and lands back on the honest failure`, true)
  }
  if (name === 'one' || name === 'populated') {
    check(`${label}: a record shows its sections and its rounds (${v.recentRows})`, v.record === 'some' && v.allTime && v.recentRows === (name === 'one' ? 1 : 5) && !v.absence.some(t => /no rounds yet/i.test(t)), v)
  }
  if (SHOTS) await page.screenshot({ path: join(SHOTS, `you-${name}--${width}--${theme}.png`), fullPage: true })
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
