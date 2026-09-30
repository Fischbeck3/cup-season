#!/usr/bin/env node
/* F13 · the round-share ARTIFACT (the PNG that leaves the app, not a preview):
   the performance band is drawn once, the facts stay, and the long-name,
   photo and no-photo states still compose. Draws with the page's own
   drawRecapCard on synthetic rounds; nothing is shared or uploaded.

     node tests/share-artifact-browser.mjs [--base http://127.0.0.1:8801] [--out <dir>]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
import { createHash } from 'node:crypto'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const OUT = arg('out', null)
if (OUT) mkdirSync(OUT, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || (process.env.HOME || '') + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }
const browser = await chromium.launch({ headless: true, executablePath: shell() })
const page = await browser.newPage()
await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
await page.goto(BASE + '/?exit', { waitUntil: 'load' })
await page.waitForFunction(() => typeof drawRecapCard === 'function', null, { timeout: 15000 })
/* the marker table is bridged from the module (window.MARKERS); a card drawn before it runs has an empty ring */
await page.waitForFunction(() => !!(window.MARKERS && window.MARKERS.saguaro), null, { timeout: 20000 })
await page.evaluate(() => document.fonts.ready)
const bands = [['played-to', 0.4], ['beat', 2.1], ['torched', 4.0], ['loose', -2.0], ['anyway', -6.0]]
for (const [label, pvi] of bands) for (const photo of [false, true]) for (const long of [false, true]) {
  const r = await page.evaluate(async ({ pvi, photo, long }) => {
    let img = null
    if (photo) { /* a drawn stand-in photograph: no face, no place */ const c = document.createElement('canvas'); c.width = 1600; c.height = 1200; const g = c.getContext('2d'); const gr = g.createLinearGradient(0, 0, 0, 1200); gr.addColorStop(0, '#6b8f6a'); gr.addColorStop(1, '#2f4a33'); g.fillStyle = gr; g.fillRect(0, 0, 1600, 1200); img = c }
    const cv = drawRecapCard({ name: long ? 'Alexandra Montgomery-Williams' : 'Avery Fixture', marker: 'saguaro', gross: 84, pvi, points: 9, course: long ? 'North Grove Country Club (fixture) — East' : 'North Grove (fixture)', date: new Date(2026, 8, 20), badge: null, _img: img })
    const g = cv.getContext('2d')
    /* the strip where the repeated sentence used to sit: centre columns, y 880–930 */
    const strip = g.getImageData(240, 878, 600, 52).data
    let lo = 255, hi = 0; for (let i = 0; i < strip.length; i += 4) { const v = strip[i] + strip[i + 1] + strip[i + 2]; lo = Math.min(lo, v); hi = Math.max(hi, v) }
    /* the name row must fit inside the frame: sample the outer 36px margins at the name's y */
    const edge = g.getImageData(0, 330, 36, 60).data; let ink = 0; for (let i = 0; i < edge.length; i += 4) if (edge[i] > 200 && edge[i + 1] > 200) ink++
    /* the golfer's marker is drawn inside its ring (centre 540,208, r 78) */
    const ring = g.getImageData(500, 170, 80, 80).data; let lo2 = 765, hi2 = 0; for (let i = 0; i < ring.length; i += 4) { const v = ring[i] + ring[i + 1] + ring[i + 2]; lo2 = Math.min(lo2, v); hi2 = Math.max(hi2, v) }
    return { w: cv.width, h: cv.height, stripRange: hi - lo, edgeInk: ink, marker: hi2 - lo2, png: cv.toDataURL('image/png') }
  }, { pvi, photo, long })
  const name = `share-${label}-${photo ? 'photo' : 'nophoto'}-${long ? 'long' : 'short'}`
  check(`${name}: 1080×1350`, r.w === 1080 && r.h === 1350, [r.w, r.h])
  /* no-photo: the old sentence strip is flat panel; photo: it holds only the wash (no glyph edges) */
  check(`${name}: the band is said once — nothing drawn where the repeat sat (range ${r.stripRange})`, r.stripRange <= (photo ? 60 : 6), r.stripRange)
  check(`${name}: the name stays inside the frame`, r.edgeInk === 0, r.edgeInk)
  check(`${name}: the golfer's marker is drawn in its ring`, r.marker > 120, r.marker)
  if (OUT) { const buf = Buffer.from(r.png.split(',')[1], 'base64'); writeFileSync(join(OUT, name + '.png'), buf); console.log('    ', name + '.png', createHash('sha256').update(buf).digest('hex').slice(0, 16)) }
}
/* the caption still carries the margin, verbatim with the phone's caption */
const cap = await page.evaluate(() => recapText({ gross: 84, course: 'North Grove (fixture)', pvi: 2.1, points: 9 }))
check(`the caption keeps the margin: "${cap}"`, /beat their playing HCP by 2\.1|beat your playing HCP by 2\.1/.test(cap) && /84 at North Grove/.test(cap), cap)
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
