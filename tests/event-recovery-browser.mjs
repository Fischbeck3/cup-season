#!/usr/bin/env node
/* S8 · the room says what happened. Opening a Ryder or a Major shows the
   room's own redacted plate at once; a failed read says so in the phone's
   words with Try again beside it, and a retry that succeeds opens the room; a
   room that is not open to this golfer says that, with no pointless retry;
   the way back to Compete is always beside the words. The reads are stubbed
   in-page (supabase-js's own {data, error} shape); nothing leaves the page.

     node tests/event-recovery-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
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
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 500))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })
/* a synthetic Ryder, the shapes loadEvent reads */
const EV = { id: 'e0000000-0000-4000-8000-0000000000e1', kind: 'ryder', name: 'The Fixture Cup', status: 'active', session_count: 3, starts_on: '2026-09-20' }
for (const width of [375, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof window.openEvent === 'function', null, { timeout: 20000 })
  await page.evaluate(EV => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false
    CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
    /* the stub answers every read with what the test's mode says, after a beat */
    window.__evMode = 'failed'
    const answer = (table) => {
      const m = window.__evMode
      if (table === 'events') {
        if (m === 'failed') return { data: null, error: { message: 'TypeError: Failed to fetch' } }
        if (m === 'unavailable') return { data: null, error: { code: 'PGRST116', message: 'JSON object requested, multiple (or no) rows returned' } }
        return { data: EV, error: null }
      }
      if (table === 'event_teams') return { data: [{ id: 't1', slot: 0, name: 'Pines', color: 0 }, { id: 't2', slot: 1, name: 'Oaks', color: 1 }], error: null }
      return { data: [], error: null }
    }
    const chain = (table) => { const q = { select: () => q, eq: () => q, order: () => q, limit: () => q, single: () => q,
      then: (res, rej) => new Promise(r => setTimeout(r, window.__evDelay || 60)).then(() => answer(table)).then(res, rej) }; return q }
    window.sb.from = (t) => chain(t)
    window.sb.rpc = async () => ({ data: [], error: null })
  }, EV)
  const label = `${width} ${theme}`
  const shot = async n => { if (SHOTS) await page.screenshot({ path: join(SHOTS, `event-${n}--${width}--${theme}.png`) }) }
  /* opening: the redacted plate, at once */
  await page.evaluate(() => { window.__evDelay = 600; window.__evMode = 'failed'; window.openEvent('e0000000-0000-4000-8000-0000000000e1') })
  await page.waitForTimeout(120)
  const loading = await page.evaluate(() => ({ view: document.querySelector('.view.active')?.id, busy: document.querySelector('#eventBody .evrec[aria-busy="true"]') !== null, plate: !!document.querySelector('#eventBody .evcard-redacted') }))
  check(`${label}: the room opens at once on its own redacted plate`, loading.view === 'view-event' && loading.busy && loading.plate, loading)
  await shot('opening')
  /* a failed read: the phone's words, Try again, the way back */
  await page.waitForFunction(() => !!document.getElementById('evrecHead'), null, { timeout: 5000 })
  const failed = await page.evaluate(() => {
    const lum = s => { const a = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
    const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
    const h = document.getElementById('evrecHead'), why = document.querySelector('.evrec-why'), plate = document.querySelector('.evrec .evcard')
    const retry = document.getElementById('evRetry'), back = document.querySelector('[data-go-compete]')
    const r = el => el.getBoundingClientRect()
    return { head: h.textContent, why: why.textContent, status: why.getAttribute('role'),
      headC: ratio(getComputedStyle(h).color, getComputedStyle(plate).backgroundColor), whyC: ratio(getComputedStyle(why).color, getComputedStyle(plate).backgroundColor),
      retry: !!retry && r(retry).height >= 44, back: !!back && r(back).height >= 44, backText: back?.textContent,
      reach: retry ? r(retry).bottom <= innerHeight : false }
  })
  check(`${label}: a failed read says "${failed.head}" and why ("${failed.why}")`, failed.head === 'The room Didn’t load' && /Connection hiccup/.test(failed.why) && failed.status === 'status', failed)
  check(`${label}: the words read on the plate (${failed.headC.toFixed(2)}:1 / ${failed.whyC.toFixed(2)}:1)`, failed.headC >= 4.5 && failed.whyC >= 4.5, failed)
  check(`${label}: Try again and ${failed.backText} are 44px doors, and Try again is in reach`, failed.retry && failed.back && failed.reach, failed)
  await shot('failed')
  /* the retry is a real read: this time it succeeds, and the room opens */
  await page.evaluate(() => { window.__evMode = 'ready'; window.__evDelay = 60 })
  await page.focus('#evRetry'); await page.keyboard.press('Enter')
  await page.waitForFunction(() => !!document.querySelector('#eventBody .evcard h1') && !document.getElementById('evrecHead'), null, { timeout: 5000 })
  const opened = await page.evaluate(() => document.querySelector('#eventBody .evcard h1')?.textContent)
  check(`${label}: Try again by keyboard opens the room ("${opened}")`, /Fixture Cup/i.test(opened || ''), opened)
  /* not open to this golfer: says so, no retry, the way back leads */
  await page.evaluate(() => { window.__evMode = 'unavailable'; window.CS_EVENT = null; window.openEvent('e0000000-0000-4000-8000-0000000000e2') })
  await page.waitForFunction(() => /Not open to you/.test(document.getElementById('evrecHead')?.textContent || ''), null, { timeout: 5000 })
  const gone = await page.evaluate(() => ({ retry: !!document.getElementById('evRetry'), backIsPrimary: document.querySelector('[data-go-compete]')?.classList.contains('btn'), why: document.querySelector('.evrec-why').textContent }))
  check(`${label}: a room that is not open says so, offers no retry, and leads back ("${gone.why}")`, !gone.retry && gone.backIsPrimary, gone)
  await shot('unavailable')
  await page.click('[data-go-compete]')
  const compete = await page.evaluate(() => document.querySelector('.view.active')?.id)
  check(`${label}: Back to Compete lands on Compete`, compete === 'view-compete', compete)
  /* a refresh that fails keeps the room on screen */
  await page.evaluate(() => { window.__evMode = 'ready'; window.CS_EVENT = null })
  await page.evaluate(() => window.openEvent('e0000000-0000-4000-8000-0000000000e1'))
  await page.waitForFunction(() => /Fixture Cup/i.test(document.querySelector('#eventBody .evcard h1')?.textContent || ''), null, { timeout: 5000 })
  await page.evaluate(() => { window.__evMode = 'failed' })
  await page.evaluate(() => window.openEvent('e0000000-0000-4000-8000-0000000000e1'))
  const kept = await page.evaluate(() => ({ h1: document.querySelector('#eventBody .evcard h1')?.textContent, rec: !!document.getElementById('evrecHead') }))
  check(`${label}: a failed refresh keeps the room that was open`, /Fixture Cup/i.test(kept.h1 || '') && !kept.rec, kept)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
