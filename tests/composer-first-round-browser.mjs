#!/usr/bin/env node
/* F09 · a golfer with no league meets the course and the score, and one
   short consequence; the five bands wait behind "How points work". A golfer in
   a live season keeps the bands open. The scoring itself is untouched: the
   same inputs give the same points either way.

     node tests/composer-first-round-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
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
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [375, 1280]) for (const theme of ['dark', 'light']) for (const who of ['no-league', 'live-season']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => typeof switchView === 'function' && window.CS, null, { timeout: 15000 })
  await page.waitForTimeout(300)
  const ss = await page.evaluate(w => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false
    CS.user = { id: '00000000-0000-4000-8000-00000000f1f1', email: 'avery@example.invalid' }
    CS.profile = { id: CS.user.id, display_name: 'Avery Fixture', handle: 'fixture_avery', marker: 'saguaro' }
    CS.memberships = []
    CS.league = w === 'live-season' ? { id: '00000000-0000-4000-8000-0000000000a1', name: 'Fixture League', phase: 'season', code: 'FIXTUR' } : null
    state.lastPost = null
    switchView('post')
    return seasonState()
  }, who)
  const label = `${width} ${theme} ${who} (${ss})`
  const before = await page.evaluate(() => ({ k: document.querySelector('.calc .k').textContent, exp: document.getElementById('postBandsDoor').getAttribute('aria-expanded'), hidden: document.getElementById('postBandsCard').hidden, doorH: document.getElementById('postBandsDoor').getBoundingClientRect().height }))
  if (who === 'no-league') {
    check(`${label}: the figure speaks to a golfer with no league`, before.k === 'This round would score', before.k)
    check(`${label}: the bands wait behind "How points work"`, before.exp === 'false' && before.hidden, before)
  } else {
    check(`${label}: a live season keeps "League points this round" and the bands open`, before.k === 'League points this round' && before.exp === 'true' && !before.hidden, before)
  }
  check(`${label}: the help control is a 44px target`, before.doorH >= 44, before.doorH)
  if (SHOTS) await page.screenshot({ path: join(SHOTS, `composer-${who}--${width}--${theme}.png`), fullPage: true })
  /* keyboard: the disclosure toggles and keeps focus */
  await page.focus('#postBandsDoor'); await page.keyboard.press('Enter')
  const toggled = await page.evaluate(() => ({ exp: document.getElementById('postBandsDoor').getAttribute('aria-expanded'), hidden: document.getElementById('postBandsCard').hidden, focus: document.activeElement?.id, rows: document.querySelectorAll('#postBandsCard .bands tr').length }))
  check(`${label}: Enter toggles the bands and focus stays on the control`, toggled.exp === (who === 'no-league' ? 'true' : 'false') && toggled.hidden === (who !== 'no-league') && toggled.focus === 'postBandsDoor' && toggled.rows === 5, toggled)
  /* the same round scores the same either way */
  const scored = await page.evaluate(() => {
    document.getElementById('inRating').value = '71.2'; document.getElementById('inSlope').value = '131'
    const g = document.getElementById('inGross'); if (g) { g.value = '88'; g.dispatchEvent(new Event('input', { bubbles: true })) }
    recalc()
    return { pts: document.getElementById('calcPts').textContent, msg: document.getElementById('calcMsg').textContent, k: document.querySelector('.calc .k').textContent, last: state.lastPost && state.lastPost.pts }
  })
  check(`${label}: a typed round previews its points (${scored.pts}) — "${scored.msg}"`, /^\d+$/.test(scored.pts) && scored.last === Number(scored.pts), scored)
  if (who === 'no-league') check(`${label}: no league is implied as a prerequisite`, !/join .* to post|need a league|set up a league/i.test(scored.msg + before.k), scored.msg)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
