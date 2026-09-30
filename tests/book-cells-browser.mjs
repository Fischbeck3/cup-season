#!/usr/bin/env node
/* F11 · a Book cell reads as a figure with its status marks beside it (33 and
   D, never "33D"), says the status in its accessible name, keeps the key
   beside the control that changes what cells mean, and still opens receipts
   that add up to the cell exactly (§16). The real dialog, fed the synthetic
   Book (tests/fixtures/ten/book-squads.synthetic.json) through a stubbed
   season_book read; nothing else is requested.

     node tests/book-cells-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync, readFileSync, mkdirSync } from 'node:fs'
import { join, dirname } from 'node:path'
import { homedir } from 'node:os'
import { fileURLToPath } from 'node:url'
const require = createRequire(import.meta.url)
const HERE = dirname(fileURLToPath(import.meta.url))
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null); if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const BOOK = JSON.parse(readFileSync(join(HERE, 'fixtures/ten/book-squads.synthetic.json'), 'utf8'))
const { chromium } = require(process.env.CS_PLAYWRIGHT || (process.env.HOME || '') + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 600))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [375, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof csOpenSeasonBook === 'function', null, { timeout: 20000 })
  await page.evaluate(async book => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false
    CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
    window.sb.rpc = async name => name === 'season_book' ? { data: book, error: null } : { data: null, error: { message: 'no fixture ' + name } }
    await csOpenSeasonBook(book.league_id, book.season_id)
    /* the golfer view, in weeks: the cells that carry marks. W5 · the Book's
       controls are segments now (one component, UI_SYSTEM §7.2), not native
       selects: the view is chosen by its button, as a golfer chooses it */
    document.querySelector('#sb-group [data-v="golfer"]')?.click()
  }, BOOK)
  await page.waitForTimeout(150)
  const v = await page.evaluate(() => {
    const d = document.getElementById('seasonBookDialog')
    const cells = [...d.querySelectorAll('.sb-matrix td button')]
    const marked = cells.filter(b => b.querySelector('.sb-marks'))
    const one = marked[0]
    const fig = one ? [...one.childNodes].filter(n => n.nodeType === 3).map(n => n.textContent).join('') : null
    const mk = one?.querySelector('.sb-marks')
    const key = d.querySelector('.sb-key'), grid = d.querySelector('.sb-matrix')
    return {
      open: !!d && d.open, cells: cells.length, marked: marked.length,
      fig, marks: mk?.textContent, marksHidden: mk?.getAttribute('aria-hidden'),
      marksSize: mk ? parseFloat(getComputedStyle(mk).fontSize) : null, figSize: one ? parseFloat(getComputedStyle(one).fontSize) : null,
      name: one?.getAttribute('aria-label'),
      keyFirst: !!key && !!grid && !!(key.compareDocumentPosition(grid) & Node.DOCUMENT_POSITION_FOLLOWING),
      keyInView: key ? key.getBoundingClientRect().top < innerHeight : false,
      glued: cells.filter(b => /^\d+[*D]/.test(b.textContent.trim()) && !b.querySelector('.sb-marks')).length,
    }
  })
  const label = `${width} ${theme}`
  check(`${label}: the Book opens with its week cells (${v.cells}, ${v.marked} carry marks)`, v.open && v.cells > 0 && v.marked > 0, v)
  check(`${label}: a marked cell is a figure "${v.fig}" with its marks "${v.marks}" apart, smaller (${v.marksSize}px vs ${v.figSize}px)`, /^\d+$/.test(v.fig || '') && /^[*D]+$/.test(v.marks || '') && v.marksSize < v.figSize && v.marksHidden === 'true', v)
  check(`${label}: no cell glues a status to its figure`, v.glued === 0, v.glued)
  check(`${label}: the cell SAYS its status: "${v.name}"`, /dropped rounds retained in receipt|adjustment or bye recorded/.test(v.name || '') && /points (in|through) week \d+/.test(v.name || ''), v.name)
  check(`${label}: the key comes before the grid${width < 500 ? '' : ''} and is in the first view`, v.keyFirst && v.keyInView, v)
  /* §16 · the receipt for that cell adds up to the cell, by keyboard */
  const r = await page.evaluate(() => {
    const d = document.getElementById('seasonBookDialog')
    /* a cell with real points, marked if one exists: 0 = 0 proves nothing */
    const all = [...d.querySelectorAll('.sb-matrix td button')].filter(x => !x.disabled && parseInt(x.textContent, 10) > 0)
    const b = all.find(x => x.querySelector('.sb-marks')) || all[0]
    b.focus(); return { fig: parseInt(b.textContent, 10), marked: !!b.querySelector('.sb-marks') }
  })
  await page.keyboard.press('Enter')
  await page.waitForTimeout(80)
  const rc = await page.evaluate(() => { const d = document.getElementById('seasonBookDialog'); const t = d.querySelector('.sb-receipts .sb-total'); return { total: t ? parseInt(t.textContent, 10) : null, focus: document.activeElement?.localName, entries: d.querySelectorAll('.sb-receipts .sb-entry').length } })
  check(`${label}: Enter opens that cell's receipt; it adds up to the cell (${rc.total} = ${r.fig}), ${rc.entries} entries, focus on its heading`, rc.total === r.fig && rc.entries > 0 && rc.focus === 'h2', { r, rc })
  if (SHOTS) await page.screenshot({ path: join(SHOTS, `book-golfers--${width}--${theme}.png`) })
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
