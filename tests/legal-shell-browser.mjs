#!/usr/bin/env node
/* F04 · the legal page wears the product's paper and action roles, lands a
   new visitor in the dark room, follows an explicit choice, and every link
   state reads at AA. Legal WORDS are not this test's job to judge; it only
   proves they are all still there (the text is compared with a hash of the
   body's text content taken before the shell changed).

     node tests/legal-shell-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]

   Playwright resolves as in sheet-focus-browser.mjs. Exit 1 on any failure. */
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
import { createHash } from 'node:crypto'

const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null)
if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || (process.env.HOME || '') + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }

/* sha256 of document.body.textContent (scripts removed, whitespace runs
   collapsed). The words may not move without this pin moving WITH a reason.
   Was ac76bd84… (1b5916b2, before the F04 shell). Re-pinned 2026-09-28 (W4,
   the static pages' one shell) for exactly these changes and no others:
   - the masthead's "Cup Season" replaces "← Back to Cup Season", and the
     page title "Cup Season · Legal" becomes "Privacy, terms and the pot"
     with a one-sentence summary under it (owner D);
   - contents rows for the three documents and the privacy policy's six
     heads, and a "Back to top" at each document's foot (owner M/R);
   - the pot document is named "The pot", not "Prize Pool Disclaimer", and
     the terms' one cross-reference follows it (TERMINOLOGY T-12, which names
     this rename; the owner panel's C) — the same rename in legal/*.md;
   - the footer says "Need a hand? Support · Get the app" and names the
     operator, as /get and /support do.
   Every clause of the three documents is otherwise the text counsel has. */
const TEXT_SHA = '292cb3285e29990a7c77d95e617718f44db46a8f96c86193a7adac8ab6da755f'

const results = []
const check = (name, ok, got) => { results.push({ name, ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })

const probe = () => {
  const lum = s => { const a = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
  const bgOf = el => { for (let n = el; n; n = n.parentElement) { const c = getComputedStyle(n).backgroundColor; if (!/rgba\(0, 0, 0, 0\)|transparent/.test(c)) return c } return 'rgb(255,255,255)' }
  const links = [...document.querySelectorAll('a')].map(a => ({ text: a.textContent.trim().slice(0, 30), ratio: ratio(getComputedStyle(a).color, bgOf(a)), h: a.getBoundingClientRect().height, inNav: !!a.closest('nav') || a.classList.contains('home') }))
  const clone = document.body.cloneNode(true); clone.querySelectorAll('script').forEach(s => s.remove())
  return {
    theme: document.documentElement.dataset.theme || null,
    bg: getComputedStyle(document.body).backgroundColor,
    ink: ratio(getComputedStyle(document.body).color, getComputedStyle(document.body).backgroundColor),
    minLink: Math.min(...links.map(l => l.ratio)),
    worst: links.sort((a, b) => a.ratio - b.ratio)[0],
    navTargets: Math.min(...links.filter(l => l.inNav).map(l => l.h)),
    mut: ratio(getComputedStyle(document.querySelector('.updated')).color, bgOf(document.querySelector('.updated'))),
    h3: ratio(getComputedStyle(document.querySelector('h3')).color, bgOf(document.querySelector('h3'))),
    overflow: document.documentElement.scrollWidth - innerWidth,
    text: clone.textContent.replace(/\s+/g, ' ').trim(),
  }
}

const DARK_BG = 'rgb(15, 26, 21)', LIGHT_BG = 'rgb(244, 241, 233)'
const cases = [
  { name: 'new visitor, OS dark', os: 'dark', saved: null, want: DARK_BG },
  { name: 'new visitor, OS light (dark-first still)', os: 'light', saved: null, want: DARK_BG },
  { name: 'explicit light', os: 'dark', saved: 'light', want: LIGHT_BG },
  { name: 'explicit dark on a light OS', os: 'light', saved: 'dark', want: DARK_BG },
  { name: 'auto on a light OS', os: 'light', saved: 'auto', want: LIGHT_BG },
  { name: 'auto on a dark OS', os: 'dark', saved: 'auto', want: DARK_BG },
  { name: 'storage refused', os: 'light', saved: 'DENY', want: DARK_BG },
]
let textHash = null
for (const width of [375, 402, 1280, 1600]) for (const c of cases) {
  if (width !== 375 && !['new visitor, OS dark', 'explicit light'].includes(c.name)) continue
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, colorScheme: c.os, serviceWorkers: 'block' })
  if (c.saved === 'DENY') await ctx.addInitScript(() => { Object.defineProperty(window, 'localStorage', { get() { throw new DOMException('denied', 'SecurityError') } }) })
  else if (c.saved) await ctx.addInitScript(v => { try { localStorage.setItem('cs_theme', v) } catch (e) {} }, c.saved)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  /* the FIRST paint: the background before any later script could run */
  await page.goto(BASE + '/legal.html', { waitUntil: 'commit' })
  await page.waitForSelector('body')
  const first = await page.evaluate(() => getComputedStyle(document.body).backgroundColor)
  await page.waitForLoadState('load')
  const r = await page.evaluate(probe)
  const label = `${width}px · ${c.name}`
  check(`${label}: first paint in the right room`, first === c.want, { first, want: c.want })
  check(`${label}: ink ${r.ink.toFixed(2)}, links ≥4.5 (min ${r.minLink.toFixed(2)}), mut ${r.mut.toFixed(2)}, h3 ${r.h3.toFixed(2)}`, r.ink >= 4.5 && r.minLink >= 4.5 && r.mut >= 4.5 && r.h3 >= 4.5, r.worst)
  check(`${label}: nav and back targets ≥44px (${r.navTargets.toFixed(1)})`, r.navTargets >= 44, r.navTargets)
  check(`${label}: no horizontal overflow`, r.overflow <= 0, r.overflow)
  check(`${label}: no page errors`, errs.length === 0, errs)
  const h = createHash('sha256').update(r.text).digest('hex')
  if (textHash === null) textHash = h
  check(`${label}: the words are the same words`, h === textHash, h)
  if (SHOTS) await page.screenshot({ path: join(SHOTS, `legal--${width}--${c.saved || 'none'}-${c.os}.png`), fullPage: false })
  /* hover and keyboard focus on the first body link, in this room */
  if (width === 375 && ['new visitor, OS dark', 'explicit light'].includes(c.name)) {
    const link = page.locator('section a').first()
    await link.hover()
    /* the ground is the first painted ancestor: the documents are no longer
       boxed in a tinted panel (W4), so the section itself is transparent and
       reading ITS colour measured the link against black */
    const hover = await page.evaluate(() => { const a = document.querySelector('section a'); const lum = s => { const x = s.match(/[\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * x[0] + .7152 * x[1] + .0722 * x[2] }; const ground = el => { for (let n = el; n; n = n.parentElement) { const c = getComputedStyle(n).backgroundColor; if (!/rgba\(0, 0, 0, 0\)|transparent/.test(c)) return c } return 'rgb(255,255,255)' }; const A = lum(getComputedStyle(a).color), B = lum(ground(a.closest('section'))); return (Math.max(A, B) + .05) / (Math.min(A, B) + .05) })
    check(`${label}: hovered link ${hover.toFixed(2)} ≥4.5`, hover >= 4.5, hover)
    await page.mouse.move(0, 0)
    await page.keyboard.press('Tab')
    const order = []
    for (let i = 0; i < 5; i++) { order.push(await page.evaluate(() => ({ t: document.activeElement.textContent.trim().slice(0, 24), ring: getComputedStyle(document.activeElement).outlineStyle }))); await page.keyboard.press('Tab') }
    /* W4 · the way home is the masthead (the pennant and "Cup Season"), and
       the pot document is named "The pot" (T-12) */
    check(`${label}: keyboard order starts Cup Season → Privacy → Terms → The pot, with a drawn ring`,
      /^Cup Season$/.test(order[0].t) && /Privacy/.test(order[1].t) && /Terms/.test(order[2].t) && /^The pot$/.test(order[3].t) && order.slice(0, 4).every(o => o.ring === 'solid'), order)
  }
  await ctx.close()
}
console.log('body text sha256', textHash)
if (TEXT_SHA !== 'unset') check('the words match the pre-change page (sha256 of body text)', textHash === TEXT_SHA, textHash)
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
