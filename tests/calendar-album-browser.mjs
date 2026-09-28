#!/usr/bin/env node
/* F15 / F16 web halves.
   F15 · every calendar day a golfer can act on is a real button: at least
   44 × 44 at 375, reachable by keyboard, named for its date and what it
   holds, and Enter opens it.
   F16 · the season album never calls a failed read "empty": a refused read
   says it failed and offers Try again; a refresh that fails keeps the
   photographs on screen; a real empty stays the honest empty.
   Reads are stubbed in-page with supabase-js's own {data, error} shape.

     node tests/calendar-album-browser.mjs [--base http://127.0.0.1:8801]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 500))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [375, 402, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof renderCalendar === 'function' && typeof window.renderAlbum === 'function', null, { timeout: 20000 })
  const label = `${width} ${theme}`
  /* ---- F15 */
  await page.evaluate(() => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false; CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
    window.mySchedule = []; window.watchAll = []
    switchView('schedule'); renderCalendar()
  })
  const cal = await page.evaluate(() => {
    const days = [...document.querySelectorAll('#calGrid .calcell.tap')]
    const r = days.map(d => d.getBoundingClientRect())
    return { n: days.length, tags: [...new Set(days.map(d => d.localName))], minW: Math.min(...r.map(x => x.width)), minH: Math.min(...r.map(x => x.height)),
      named: days.every(d => /\w{3} \w{3} \d+/.test(d.getAttribute('aria-label') || '')), sample: days[0]?.getAttribute('aria-label'),
      overlap: r.some((a, i) => r.some((b, j) => i !== j && a.left < b.right - 0.5 && a.right > b.left + 0.5 && a.top < b.bottom - 0.5 && a.bottom > b.top + 0.5)),
      overflow: document.documentElement.scrollWidth - innerWidth }
  })
  check(`${label}: calendar days are buttons, ≥44×44 (${cal.minW.toFixed(1)}×${cal.minH.toFixed(1)}), never overlapping`, cal.n > 0 && cal.tags.join() === 'button' && cal.minW >= 44 && cal.minH >= 44 && !cal.overlap, cal)
  check(`${label}: each day is named for its date and what it holds ("${cal.sample}")`, cal.named, cal)
  check(`${label}: the page does not scroll sideways`, cal.overflow <= 0, cal.overflow)
  /* keyboard: Tab reaches a day, Enter opens it (a planning sheet for an empty future day) */
  await page.focus('#calGrid .calcell.tap')
  await page.keyboard.press('Enter')
  const opened = await page.evaluate(() => ({ sheet: document.getElementById('sheet').classList.contains('open'), title: document.getElementById('shTitle').textContent }))
  check(`${label}: Enter on a day opens it ("${opened.title}")`, opened.sheet, opened)
  await page.keyboard.press('Escape')
  const back = await page.evaluate(() => document.activeElement?.classList.contains('calcell'))
  check(`${label}: closing it returns focus to the day`, back, back)
  /* ---- F16 */
  const album = async (mode) => page.evaluate(async mode => {
    CS.league = { id: '00000000-0000-4000-8000-0000000000a1', name: 'Fixture League' }
    CS.members = [{ profile_id: 'p1', profile: { display_name: 'Avery Fixture' } }]
    const row = { id: 'r1', profile_id: 'p1', gross: 84, played_on: '2026-09-20', course_label: 'North Grove (fixture)', holes_played: 18, photo_path: 'p1/r1.jpg' }
    const q = { select: () => q, in: () => q, not: () => q, order: () => q, limit: () => q,
      then: (res, rej) => Promise.resolve(mode === 'read-fails' ? { data: null, error: { message: 'TypeError: Failed to fetch' } } : mode === 'empty' ? { data: [], error: null } : { data: [row], error: null }).then(res, rej) }
    window.sb.from = () => q
    window.sb.storage.from = () => ({ createSignedUrls: async () => mode === 'sign-fails' ? { data: null, error: { message: 'signing refused' } } : { data: [{ path: 'p1/r1.jpg', signedUrl: 'data:image/gif;base64,R0lGODlhAQABAAAAACw=' }], error: null } })
    await window.renderAlbum()
    const box = document.getElementById('albumGrid')
    return { text: box.textContent.replace(/\s+/g, ' ').trim(), cells: box.querySelectorAll('.alcell').length, retry: !!document.getElementById('albumRetry'), status: !!box.querySelector('[role="status"]') }
  }, mode)
  const failedRead = await album('read-fails')
  check(`${label}: a failed read says it failed, with Try again — never "add one" ("${failedRead.text.slice(0, 60)}…")`, /didn’t load/.test(failedRead.text) && failedRead.retry && failedRead.status && !/Photos land here/.test(failedRead.text), failedRead)
  const signFails = await album('sign-fails')
  check(`${label}: photographs that cannot be opened are a failure too, not an empty album`, /didn’t load/.test(signFails.text) && signFails.retry, signFails)
  const good = await album('ok')
  check(`${label}: a good read shows the photograph`, good.cells === 1 && !good.retry, good)
  const refresh = await album('read-fails')
  check(`${label}: a refresh that fails keeps the photograph and says so`, refresh.cells === 1 && /didn’t refresh/.test(refresh.text) && refresh.retry, refresh)
  await page.evaluate(() => { document.getElementById('albumGrid').innerHTML = '' })
  const empty = await album('empty')
  check(`${label}: a real empty album stays the honest empty`, /Photos land here/.test(empty.text) && !empty.retry, empty)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
