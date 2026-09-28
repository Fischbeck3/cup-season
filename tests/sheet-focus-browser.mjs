#!/usr/bin/env node
/* F03 · the modal lifecycle, driven with REAL key presses. A page-evaluated
   suite cannot test this: a synthetic Tab moves nothing, and focus order is
   exactly what is under test.

     python3 -m http.server 8801 --bind 127.0.0.1 --directory <repo>
     node tests/sheet-focus-browser.mjs [--base http://127.0.0.1:8801] [--width 375]

   Playwright is not a dependency of this repo. The runner resolves it from
   CS_PLAYWRIGHT or the Codex runtime this Mac already has, and the headless
   shell from ~/Library/Caches/ms-playwright. Every Supabase request is
   aborted; no account is touched. Exit code 1 on any failed check. */
import { createRequire } from 'node:module'
import { existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const WIDTH = parseInt(arg('width', '375'), 10)
const PW = process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright'
const { chromium } = require(PW)
function shell(){
  const root = join(homedir(), 'Library', 'Caches', 'ms-playwright')
  for (const d of readdirSync(root).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) {
    const p = join(root, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell')
    if (existsSync(p)) return p
  }
  return undefined
}

const results = []
const check = (name, ok, got) => { results.push({ name, ok: !!ok, got }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got))) }

const browser = await chromium.launch({ headless: true, executablePath: shell() })
const context = await browser.newContext({ viewport: { width: WIDTH, height: WIDTH < 500 ? 667 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce', timezoneId: 'America/Phoenix' })
const page = await context.newPage()
const exceptions = []
page.on('pageerror', e => exceptions.push(e.message))
await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
await page.goto(BASE + '/?exit', { waitUntil: 'load' })
await page.waitForFunction(() => typeof window.openSheet === 'function' || typeof openSheet === 'function', null, { timeout: 15000 })
await page.waitForTimeout(600)

const active = () => page.evaluate(() => {
  const a = document.activeElement
  return { id: a?.id || null, tag: a?.localName || null, inSheet: !!a?.closest('#sheet'), inBoard: !!a?.closest('#boardFull'), inFinish: !!a?.closest('#finish'), text: (a?.textContent || '').trim().slice(0, 40), key: a?.dataset?.round || null }
})
/* a visible invoker in the page, opened with a real Enter */
await page.evaluate(() => {
  const host = document.createElement('div'); host.id = 'tHost'
  host.style.cssText = 'position:fixed;top:60px;left:10px;z-index:45;display:flex;gap:6px;flex-wrap:wrap;'
  host.innerHTML = '<button id="tOpen">Open</button><button id="tNested">Nested</button><button data-round="fixture|1" id="tKeyed" data-kind="t">Keyed</button><button id="tOne">One</button><button id="tAsync">Async</button><button id="tBoard">Board</button>'
  document.body.appendChild(host)
  const body = '<p>Fixture body.</p><button id="sA">First</button><input id="sB" aria-label="Field"><a href="#" id="sC">Link</a><button id="sReplace">Replace</button>'
  document.getElementById('tOpen').onclick = () => openSheet('Fixture sheet', 'SYNTHETIC', body)
  document.getElementById('tNested').onclick = () => { openSheet('First sheet', 'ONE', '<button id="nGo">Go deeper</button>'); document.getElementById('nGo').onclick = () => openSheet('Second sheet', 'TWO', '<button id="nX">Inner</button>') }
  document.getElementById('tKeyed').onclick = () => openSheet('Keyed sheet', 'KEY', '<button id="kA">A</button>')
  document.getElementById('tOne').onclick = () => openSheet('Only close', 'NONE', '<p>Nothing to press.</p>')
  document.getElementById('tAsync').onclick = () => { openSheet('Loading sheet', 'ASYNC', '<button id="aWait">Waiting</button>'); }
  document.getElementById('tBoard').onclick = () => { openBoardFull(); }
})

/* 1 · open → focus in, background inert, name */
await page.focus('#tOpen'); await page.keyboard.press('Enter')
let a = await active()
check('opening moves focus to the sheet title', a.id === 'shTitle', a)
const iso = await page.evaluate(() => ({
  tabbarInert: !!document.querySelector('.tabbar')?.inert || !!document.querySelector('.tabbar')?.closest('[inert]'),
  hostInert: !!document.getElementById('tHost').inert,
  sheetInert: !!document.getElementById('sheet').closest('[inert]'),
  toastInert: !!document.getElementById('toast').inert,
  name: document.getElementById('sheet').getAttribute('aria-labelledby'),
}))
check('the page behind is inert, the sheet and toast are not', iso.hostInert && iso.tabbarInert && !iso.sheetInert && !iso.toastInert, iso)
check('the sheet is named by its title', iso.name === 'shTitle', iso)
/* 2 · Tab and Shift+Tab never leave */
let escaped = []
for (let i = 0; i < 9; i++) { await page.keyboard.press('Tab'); a = await active(); if (!a.inSheet) escaped.push(a) }
for (let i = 0; i < 9; i++) { await page.keyboard.press('Shift+Tab'); a = await active(); if (!a.inSheet) escaped.push(a) }
check('Tab and Shift+Tab stay inside the sheet (18 presses)', escaped.length === 0, escaped)
/* 3 · Escape closes and restores */
await page.keyboard.press('Escape')
a = await active()
const closed1 = await page.evaluate(() => !document.getElementById('sheet').classList.contains('open') && !document.getElementById('tHost').inert)
check('Escape closes, releases the page and returns focus to the opener', closed1 && a.id === 'tOpen', { closed1, a })
/* 4 · backdrop and the close button restore too */
await page.focus('#tOpen'); await page.keyboard.press('Enter')
await page.mouse.click(5, 5)
a = await active()
check('a backdrop tap returns focus to the opener', a.id === 'tOpen', a)
await page.focus('#tOpen'); await page.keyboard.press('Enter')
await page.focus('#shClose'); await page.keyboard.press('Enter')
a = await active()
check('the Close button returns focus to the opener', a.id === 'tOpen', a)
/* 5 · replacement keeps the first opener */
await page.focus('#tNested'); await page.keyboard.press('Enter')
await page.focus('#nGo'); await page.keyboard.press('Enter')
a = await active()
const title2 = await page.evaluate(() => document.getElementById('shTitle').textContent)
check('a replacement sheet takes focus at its own title', a.id === 'shTitle' && title2 === 'Second sheet', { a, title2 })
await page.keyboard.press('Escape')
a = await active()
check('closing a replacement returns to the ORIGINAL opener', a.id === 'tNested', a)
/* 6 · a re-rendered opener: its replacement by data key; else the page heading */
await page.focus('#tKeyed'); await page.keyboard.press('Enter')
await page.evaluate(() => { const o = document.getElementById('tKeyed'); const n = document.createElement('button'); n.textContent = 'Keyed again'; n.dataset.round = 'fixture|1'; n.onclick = () => openSheet('Keyed sheet', 'KEY', '<button id="kA">A</button>'); o.replaceWith(n) })
await page.keyboard.press('Escape')
a = await active()
check('a re-rendered opener is found by its data key', a.key === 'fixture|1' && a.text === 'Keyed again', a)
await page.evaluate(() => { document.querySelector('[data-round="fixture|1"]').id = 'tKeyed2' })
await page.focus('#tKeyed2'); await page.keyboard.press('Enter')
await page.evaluate(() => document.getElementById('tKeyed2').remove())
await page.keyboard.press('Escape')
a = await active()
const fb = await page.evaluate(() => ({ tag: document.activeElement?.localName, body: document.activeElement === document.body }))
check('a vanished opener falls back to the page heading, not <body>', !fb.body && /^h[1-3]$/.test(fb.tag || ''), fb)
/* 7 · one control only: Tab keeps to it */
await page.focus('#tOne'); await page.keyboard.press('Enter')
for (let i = 0; i < 3; i++) await page.keyboard.press('Tab')
a = await active()
check('a sheet whose only control is Close keeps Tab on it', a.id === 'shClose', a)
await page.keyboard.press('Escape')
/* 8 · async content that removes the focused control keeps focus inside */
await page.focus('#tAsync'); await page.keyboard.press('Enter')
await page.focus('#aWait')
await page.evaluate(() => { document.getElementById('shBody').innerHTML = '<p>Loaded.</p><button id="aDone">Done</button>' })
await page.waitForTimeout(50)
a = await active()
check('a re-render that removes the focused control puts focus back in the sheet', a.inSheet, a)
await page.keyboard.press('Escape')
a = await active()
check('…and closing still returns to the opener', a.id === 'tAsync', a)
/* 9 · a sheet over the full board returns into the board; Escape closes the top layer only */
await page.focus('#tBoard'); await page.keyboard.press('Enter')
a = await active()
check('the full board takes focus at its title', a.id === 'bfTitle', a)
await page.evaluate(() => { const b = document.createElement('button'); b.id = 'bfInner'; b.textContent = 'Round'; b.onclick = () => openSheet('Over the board', 'STACK', '<button id="obX">X</button>'); document.getElementById('feedListFull').appendChild(b) })
await page.focus('#bfInner'); await page.keyboard.press('Enter')
const stack = await page.evaluate(() => ({ boardInert: !!document.getElementById('boardFull').inert, top: window.csModal.top() }))
check('a sheet over the board makes the board background', stack.boardInert && stack.top === 'sheet', stack)
await page.keyboard.press('Escape')
a = await active()
const still = await page.evaluate(() => document.getElementById('boardFull').classList.contains('open'))
check('Escape closed only the sheet; focus is back on the board control', still && a.id === 'bfInner', { still, a })
let boardEscaped = []
for (let i = 0; i < 6; i++) { await page.keyboard.press('Tab'); a = await active(); if (!a.inBoard) boardEscaped.push(a) }
check('Tab stays inside the full board', boardEscaped.length === 0, boardEscaped)
await page.keyboard.press('Escape')
a = await active()
check('Escape closes the board and returns to its opener', a.id === 'tBoard', a)
/* 10 · the ceremony over an epilogue sheet that opened behind it */
await page.focus('#tOpen')
await page.evaluate(() => { finishCeremony({ course: 'North Grove (fixture)', gross: 84, vs: -1, points: 0, inLeague: false, date: new Date(2026, 8, 20) }); openSheet('Epilogue', 'BEHIND', '<button id="eX">After</button>') })
a = await active()
const fin = await page.evaluate(() => ({ top: window.csModal.top(), sheetInert: !!document.getElementById('sheet').inert }))
check('the ceremony keeps focus while the epilogue waits behind it', a.inFinish && fin.top === 'finish' && fin.sheetInert, { a, fin })
await page.keyboard.press('Escape')
a = await active()
check('dismissing the ceremony hands focus to the waiting sheet', a.inSheet, a)
await page.keyboard.press('Escape')
a = await active()
const released = await page.evaluate(() => [...document.body.children].filter(c => c.inert).map(c => c.id || c.className || c.localName))
check('with every layer closed nothing is left inert', released.length === 0, released)
/* 11 · a native <dialog> (the Book's pattern) is never managed */
const native = await page.evaluate(() => { const d = document.createElement('dialog'); d.innerHTML = '<button id="dX">x</button>'; document.body.appendChild(d); d.showModal(); const r = { top: window.csModal.top(), inert: [...document.body.children].filter(c => c.inert).length }; d.close(); d.remove(); return r })
check('a native modal dialog is left to the browser', native.top === null && native.inert === 0, native)
/* 12 · the app's own producers: settings, a confirmation, a receipt, help */
const producers = [
  ['scoring help', () => openScoringHelp()],
  ['scan consent (a confirmation)', () => csAskScanConsent(() => {})],
  ['handle change (a confirmation that resolves on close)', () => { window.__hchg = confirmHandleChange('fixture_old', 'fixture_new') }],
  ['a round receipt', () => showRound(PLAYERS[0].n, 0)],
  ['Card & settings, synthetic profile', () => {
    window.CS = window.CS || {}
    CS.user = { id: '00000000-0000-4000-8000-00000000f1f1', email: 'avery@example.invalid' }
    CS.profile = { id: '00000000-0000-4000-8000-00000000f1f1', display_name: 'Avery Fixture', handle: 'fixture_avery', marker: 'saguaro', city: 'Tempe', home_course: 'North Grove (fixture)' }
    CS.memberships = []
    openProfileHub()
  }],
]
for (const [label, fn] of producers) {
  const before = exceptions.length
  await page.evaluate(src => { document.getElementById('tOpen').onclick = new Function(src) }, `(${fn.toString()})()`)
  await page.focus('#tOpen'); await page.keyboard.press('Enter')
  await page.waitForTimeout(120)
  const open = await page.evaluate(() => ({ open: document.getElementById('sheet').classList.contains('open'), title: document.getElementById('shTitle').textContent }))
  a = await active()
  let out = []
  for (let i = 0; i < 12; i++) { await page.keyboard.press('Tab'); const x = await active(); if (!x.inSheet) out.push(x) }
  await page.keyboard.press('Escape')
  await page.waitForTimeout(60)
  const back = await active()
  const left = await page.evaluate(() => [...document.body.children].filter(c => c.inert).length)
  check(`${label}: opens at its title, keeps Tab inside, Escape returns to the opener`,
    open.open && a.id === 'shTitle' && out.length === 0 && back.id === 'tOpen' && left === 0,
    { open, a, out, back, left })
  if (exceptions.length > before) console.log('    exception during', label, exceptions.slice(before))
}
const resolved = await page.evaluate(() => window.__hchg)
check('the handle change resolves "keep" when Escape closes it', resolved === false, resolved)

check('no page exceptions', exceptions.length === 0, exceptions)

await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed at ${WIDTH}px`)
process.exit(failed.length ? 1 : 0)
