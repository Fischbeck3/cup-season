#!/usr/bin/env node
/* R01 / R02 · the Door's way back and its send action, with real key
   presses and measured boxes. No email is submitted: Supabase is aborted and
   the check stops at the field.

     node tests/door-residuals-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]

   Playwright resolves as in sheet-focus-browser.mjs. Exit 1 on any failure. */
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null)
if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })

const measure = () => {
  const lum = s => { const a = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
  const bgOf = el => { for (let n = el; n; n = n.parentElement) { const c = getComputedStyle(n).backgroundColor; if (!/rgba\(0, 0, 0, 0\)|transparent/.test(c)) return c } return 'rgb(0,0,0)' }
  const back = document.getElementById('obBack'), go = document.getElementById('obEmailGo'), field = document.getElementById('obEmailIn')
  const r = el => el && el.getBoundingClientRect()
  const b = r(back), g = r(go), f = r(field)
  return {
    backVisible: !!back && getComputedStyle(back).display !== 'none',
    back: b && { w: +b.width.toFixed(1), h: +b.height.toFixed(1), top: +b.top.toFixed(1) },
    backContrast: back ? +ratio(getComputedStyle(back).color, bgOf(back)).toFixed(2) : null,
    backAboveField: !!(b && f && b.bottom <= f.top + 0.5),
    go: g && { w: +g.width.toFixed(1), h: +g.height.toFixed(1), bottom: +g.bottom.toFixed(1), text: go.textContent.trim(), fits: go.scrollWidth <= go.clientWidth + 1 },
    field: f && { w: +f.width.toFixed(1), top: +f.top.toFixed(1) },
    viewportH: innerHeight,
    overflow: document.documentElement.scrollWidth - innerWidth,
  }
}

/* `/?exit` signs out and then REPLACES the page without the query; a door
   driven before that reload was driven on a page about to vanish (the Back
   "disappeared" at random). Every entry waits for the reload first. */
for (const width of [375, 402, 1280, 1600]) for (const theme of ['dark', 'light']) for (const height of (width < 500 ? [667, 380] : [900])) {
  const ctx = await browser.newContext({ viewport: { width, height }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' }); await page.waitForURL(u => !/[?&]exit\b/.test(String(u)), { waitUntil: 'load' })
  await page.waitForSelector('#obEmail', { state: 'visible', timeout: 15000 })
  await page.waitForTimeout(400)
  const label = `${width}×${height} ${theme}`
  /* initial entry, by keyboard */
  await page.focus('#obEmail'); await page.keyboard.press('Enter')
  let m = await page.evaluate(measure)
  const focused = await page.evaluate(() => document.activeElement?.id)
  check(`${label}: email opens with focus in the field`, focused === 'obEmailIn', focused)
  check(`${label}: Back is above the field, ${m.back?.w}×${m.back?.h}, ${m.backContrast}:1`, m.backVisible && m.backAboveField && m.back.w >= 44 && m.back.h >= 44 && m.backContrast >= 4.5, m)
  check(`${label}: the action says "${m.go?.text}" and fits (${m.go?.w}px)`, m.go.text === 'Send code' && m.go.fits && m.go.h >= 44, m.go)
  check(`${label}: the send action is inside the viewport (bottom ${m.go?.bottom} of ${m.viewportH})`, m.go.bottom <= m.viewportH, m.go)
  check(`${label}: no horizontal overflow`, m.overflow <= 0, m.overflow)
  if (SHOTS && height !== 380) await page.screenshot({ path: join(SHOTS, `door-email--${width}--${theme}.png`) })
  if (SHOTS && height === 380) await page.screenshot({ path: join(SHOTS, `door-email-short--${width}--${theme}.png`) })
  /* Back by keyboard returns to the chooser, focus on the email door */
  await page.focus('#obBack'); await page.keyboard.press('Enter')
  const afterBack = await page.evaluate(() => ({ focus: document.activeElement?.id, emailShown: getComputedStyle(document.getElementById('obEmail')).display !== 'none', joinShown: getComputedStyle(document.getElementById('obJoin')).display !== 'none', boxOpen: document.getElementById('emailbox').classList.contains('open') }))
  check(`${label}: Back restores both doors and focuses the email door`, afterBack.focus === 'obEmail' && afterBack.emailShown && afterBack.joinShown && !afterBack.boxOpen, afterBack)
  /* re-entry: Back stays in the same place */
  await page.keyboard.press('Enter')
  const m2 = await page.evaluate(measure)
  /* measured against the field, not the viewport: at 380px the door scrolls to the focused field */
  check(`${label}: re-entry keeps Back above the field at the same offset`, m2.backAboveField && Math.abs((m2.field.top - m2.back.top) - (m.field.top - m.back.top)) < 1, { first: m.field.top - m.back.top, again: m2.field.top - m2.back.top })
  /* the league-code branch, opened FIRST in a fresh page, has its own way back */
  await page.goto(BASE + '/?exit', { waitUntil: 'load' }); await page.waitForURL(u => !/[?&]exit\b/.test(String(u)), { waitUntil: 'load' }); await page.waitForSelector('#obJoin', { state: 'visible' }); await page.waitForTimeout(300)
  await page.focus('#obJoin'); await page.keyboard.press('Enter')
  const jn = await page.evaluate(() => { const b = document.getElementById('obBack'); const j = document.getElementById('obJoin'); const r = b?.getBoundingClientRect(); return { exists: !!b, shown: !!b && getComputedStyle(b).display !== 'none', above: !!b && r.bottom <= j.getBoundingClientRect().top + 0.5, w: r?.width, h: r?.height } })
  check(`${label}: the league-code branch has a Back above it`, jn.exists && jn.shown && jn.above && jn.w >= 44 && jn.h >= 44, jn)
  await page.focus('#obBack'); await page.keyboard.press('Enter')
  const jb = await page.evaluate(() => document.activeElement?.id)
  check(`${label}: Back from the code branch focuses the code door`, jb === 'obJoin', jb)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
