#!/usr/bin/env node
/* F14 · every wizard help control is an honest 44 × 44 target that no other
   control shares, opens and closes by keyboard, says what it explains, and
   draws its glyph at AA; the composer's figure labels meet the 11px floor.
   The wizard runs in the signed-out demo state, which is allowed to edit
   (switchView's Pro gate passes demo) and never writes.

     node tests/wizard-help-targets-browser.mjs [--base http://127.0.0.1:8801]
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
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })

const audit = () => {
  const lum = s => { const a = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
  const interactive = [...document.querySelectorAll('button,a[href],input,select,textarea,[tabindex]:not([tabindex="-1"])')].filter(n => n.getClientRects().length && !n.closest('[hidden]'))
  return [...document.querySelectorAll('.wizstep.on .ibtn')].filter(b => b.getClientRects().length).map(b => {
    const r = b.getBoundingClientRect(), cx = r.left + r.width / 2, cy = r.top + r.height / 2
    const box = { l: cx - 22, t: cy - 22, r: cx + 22, b: cy + 22 }
    /* every point of the 44px square, sampled on a 4px grid, lands on this control */
    let misses = 0, total = 0
    for (let x = box.l + 1; x <= box.r - 1; x += 4) for (let y = box.t + 1; y <= box.b - 1; y += 4) {
      total++; const hit = document.elementFromPoint(x, y); if (!(hit === b || b.contains(hit))) misses++
    }
    /* and no other control's own box enters it */
    const shared = interactive.filter(n => n !== b && !b.contains(n)).filter(n => { const q = n.getBoundingClientRect(); return q.left < box.r && q.right > box.l && q.top < box.b && q.bottom > box.t }).map(n => n.id || n.textContent.trim().slice(0, 20))
    return { key: b.dataset.i, name: b.getAttribute('aria-label'), misses, total, shared, glyph: +ratio(getComputedStyle(b).color, getComputedStyle(b).backgroundColor).toFixed(2), inView: cy > 22 && cy < innerHeight - 22 }
  })
}

for (const width of [375, 402, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => typeof switchView === 'function', null, { timeout: 15000 })
  await page.waitForTimeout(400)
  await page.evaluate(() => { const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'; switchView('wizard') })
  let seen = 0
  for (const step of [0, 1, 2]) {
    await page.evaluate(s => { state.wiz = s; renderWizard() }, step)
    await page.waitForTimeout(80)
    /* the dials (squads, how squads fill, how it ends, the pot split) live behind Customize */
    if (step === 1) { await page.focus('#wizCustomize'); await page.keyboard.press('Enter'); await page.waitForTimeout(80) }
    const keys = await page.evaluate(() => [...document.querySelectorAll('.wizstep.on .ibtn')].filter(b => b.getClientRects().length).map(b => b.dataset.i))
    for (const key of keys) {
      await page.evaluate(k => document.querySelector(`.wizstep.on .ibtn[data-i="${k}"]`).scrollIntoView({ block: 'center' }), key)
      const row = (await page.evaluate(audit)).find(a => a.key === key)
      seen++
      check(`${width} ${theme} step ${step + 1} · ${key}: 44px reach (${row.total - row.misses}/${row.total} points), shares with none${row.shared.length ? ' — ' + row.shared.join(', ') : ''}, glyph ${row.glyph}:1, named`,
        row.misses === 0 && row.shared.length === 0 && row.glyph >= 4.5 && !!row.name, row)
      /* keyboard: Enter opens its explanation, Enter closes it */
      await page.focus(`.wizstep.on .ibtn[data-i="${key}"]`)
      await page.keyboard.press('Enter')
      const open = await page.evaluate(k => { const b = document.querySelector(`.wizstep.on .ibtn[data-i="${k}"]`); const h = document.querySelector('.ihelp.open'); return { exp: b.getAttribute('aria-expanded'), panel: !!h && h.getClientRects().length > 0, col: getComputedStyle(b).borderColor, act: getComputedStyle(document.documentElement).getPropertyValue('--act').trim() } }, key)
      await page.keyboard.press('Enter')
      const shut = await page.evaluate(k => document.querySelector(`.wizstep.on .ibtn[data-i="${k}"]`).getAttribute('aria-expanded'), key)
      check(`${width} ${theme} step ${step + 1} · ${key}: Enter opens (aria-expanded ${open.exp}, panel shown) and closes (${shut})`, open.exp === 'true' && open.panel && shut === 'false', open)
    }
  }
  check(`${width} ${theme}: every wizard help control was measured (${seen})`, seen >= 7, seen)
  /* the composer's figure labels */
  const trio = await page.evaluate(() => { switchView('post'); const s = document.querySelector('.calc .trio span'); return s ? parseFloat(getComputedStyle(s).fontSize) : null })
  check(`${width} ${theme}: composer figure labels ≥11px (${trio})`, trio === null || trio >= 11, trio)
  check(`${width} ${theme}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
