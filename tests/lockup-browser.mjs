#!/usr/bin/env node
/* D358 · ONE LOCKUP. The wordmark was set four ways — serif caps on the Door,
   sans title case in the phone header, board caps at agate tracking in the
   sidebar, mono or board caps on the public pages (craft C, category T, owner
   C, critique-B public shell). The one lockup is the phone masthead's own
   (`CSMasthead.wordmark`, Chrome.swift): the pennant in an s5 × s4 box (32 × 20),
   s2 (8), then "Cup Season" in the `name` role — IBM Plex Sans Condensed 600,
   17px, caps, tracked `caps` (0.035em), in `ink`.

   This walks every place the lockup is drawn and holds each one to that:
     · the phone header (#hdrLogo) at 320 / 390, and the desk sidebar at 1440 / 1600;
     · the public shell (/?share=…, whose signature is drawn before the read,
       so a refused read still shows it);
     · get, support and legal (their own inline twin of the rule).
   The Door keeps its serif name until the owner rules on the 2026-09-14 board
   (root, 2026-09-28) — it is deliberately NOT walked here.

     node tests/lockup-browser.mjs [--base http://127.0.0.1:8801]

   Every *.supabase.co request is aborted. Exit 1 on any failure. */
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
const check = (name, ok, got) => { results.push({ name, ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })

/* the lockup's measured shape, from inside the page */
const measure = (sel) => {
  const box = document.querySelector(sel)
  if (!box) return { missing: sel }
  const r = box.getBoundingClientRect()
  const mark = box.querySelector('svg'), name = [...box.children].find(el => el.tagName !== 'svg' && el.tagName !== 'SVG')
  if (!mark || !name) return { incomplete: sel }
  const m = mark.getBoundingClientRect(), n = name.getBoundingClientRect(), cs = getComputedStyle(name)
  /* the page's own ink, resolved through a probe so a hex token and an rgb() compare */
  const probe = document.createElement('span'); probe.style.color = 'var(--ink)'; box.appendChild(probe)
  const ink = getComputedStyle(probe).color; probe.remove()
  return {
    shown: r.width > 0 && r.height > 0 && getComputedStyle(box).visibility !== 'hidden',
    face: cs.fontFamily, weight: cs.fontWeight, size: cs.fontSize, caps: cs.textTransform,
    track: parseFloat(cs.letterSpacing) / parseFloat(cs.fontSize),
    nameColor: cs.color, markColor: getComputedStyle(mark).color, ink,
    markW: Math.round(m.width), markH: Math.round(m.height), gap: Math.round(n.left - m.right),
    text: name.textContent.trim(),
  }
}
const holds = (label, g) => {
  if (!g || g.missing || g.incomplete) return check(`${label}: the lockup is drawn`, false, g)
  check(`${label}: the lockup is on screen`, g.shown, g)
  check(`${label}: the name is the board face (IBM Plex Sans Condensed)`, /IBM Plex Sans Condensed/.test(g.face), g.face)
  check(`${label}: the name is the name role — 600, 17px, caps`, g.weight === '600' && g.size === '17px' && g.caps === 'uppercase', [g.weight, g.size, g.caps])
  check(`${label}: tracked caps (0.035em)`, Math.abs(g.track - 0.035) < 0.004, g.track)
  check(`${label}: the mark sits in the 32 × 20 box`, g.markW === 32 && g.markH === 20, [g.markW, g.markH])
  check(`${label}: s2 between the mark and the name`, Math.abs(g.gap - 8) <= 1, g.gap)
  check(`${label}: mark and name are both ink`, g.nameColor === g.ink && g.markColor === g.ink, [g.nameColor, g.markColor, g.ink])
  check(`${label}: it says Cup Season (case is the role's job)`, g.text === 'Cup Season', g.text)
}

const run = async (label, path, sel, width, theme) => {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(v => { try { localStorage.setItem('cs_theme', v) } catch (e) {} }, theme)
  const page = await ctx.newPage()
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + path, { waitUntil: 'load' })
  await page.evaluate(() => document.fonts.ready)
  await page.waitForTimeout(700)
  await page.waitForFunction(s => !!document.querySelector(s), sel, { timeout: 8000 }).catch(() => {})
  holds(`${label} ${width} ${theme}`, await page.evaluate(measure, sel))
  await ctx.close()
}

for (const theme of ['dark', 'light']) {
  for (const w of [320, 390]) await run('phone header', '/?exit', '#hdrLogo .cs-lockup', w, theme)
  for (const w of [1440, 1600]) await run('desk sidebar', '/?exit', 'aside.side .brand .cs-lockup', w, theme)
  for (const w of [390, 1440]) await run('public shell', '/?share=lockup-probe-token', '#shareView .sv-signature .cs-lockup', w, theme)
  for (const pg of ['get', 'support', 'legal'])
    for (const w of [390, 1440]) await run(`/${pg}`, `/${pg}.html`, 'header.mast .home', w, theme)
}

await browser.close()
const bad = results.filter(r => !r.ok).length
console.log(bad ? `\nFAIL — ${bad} of ${results.length}` : `\nPASS — ${results.length} checks`)
process.exit(bad ? 1 : 0)
