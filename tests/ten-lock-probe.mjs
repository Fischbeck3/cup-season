#!/usr/bin/env node
/* Cup Season · the navigator.locks probe (WX lane, I04 evidence).
 *
 *   node tests/ten-lock-probe.mjs --root <app dir> [--ref <commit>] [--out <dir>]
 *
 * The question: may the web client drop supabase-js's deprecated `lock`
 * option? The pass-through lock exists because navigator.locks is ORIGIN-WIDE
 * and one wedged tab would freeze every tab (CLAUDE.md landmine). So the
 * option may go only if supabase-js 2.112's lockless coordination cannot
 * block across tabs. This probe measures exactly that, in a real browser:
 *
 *   variants (index.html rewritten IN THE RESPONSE only; nothing on disk):
 *     as-shipped      the three createClient calls as committed (pass-through lock)
 *     no-lock-option  the `lock` option removed from all three (proposal A)
 *     navigator-lock  CONTRAST: the main client given auth-js's own
 *                     navigatorLock -- the landmine, to prove the probe
 *                     detects blocking when it exists
 *   scenarios, each in a fresh browser context (one origin, one lock manager):
 *     single          one tab boots signed in
 *     wedged-tab      tab A holds `lock:sb-<ref>-auth-token` (the exact name
 *                     auth-js locks on) FOREVER, as a zombie tab would; tab B
 *                     then boots signed in
 *     refresh-race    two tabs boot at once on a session expiring in 5 s, so
 *                     both refresh concurrently
 *   recorded per tab: reached Home or not (within 15 s), boot ms, how many
 *   navigator.locks.request calls the page made, the locks held origin-wide
 *   (navigator.locks.query), auth requests.
 *
 * Every Supabase request is answered by the synthetic world
 * (tests/fixtures/ten); nothing reaches production. Test-only. */
import { createRequire } from 'node:module'
import { readFileSync, writeFileSync, mkdirSync, mkdtempSync, rmSync, existsSync } from 'node:fs'
import { join, resolve, dirname } from 'node:path'
import { tmpdir } from 'node:os'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { cdnCache, supabaseResponder, realtimeMock, SUPABASE_HOST, CDN_HOSTS, sha } from './ten-net.mjs'
import { makeWorld, loadHandlers, worldApi } from './fixtures/ten/world.mjs'
import { CAPTURE_NOW } from './fixtures/ten/cast.mjs'

const HERE = dirname(fileURLToPath(import.meta.url))
const args = process.argv.slice(2)
const arg = (k, d = null) => { const i = args.indexOf('--' + k); return i >= 0 && i + 1 < args.length ? args[i + 1] : d }
const ROOT_ARG = resolve(arg('root', resolve(HERE, '..')))
const REF = arg('ref', null)
const OUT = resolve(arg('out', '/Users/fischbeck3/cup-season-claude-ten-gallery/wx/lock-probe'))
const PW = process.env.TEN_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright'
const CHROME = process.env.TEN_CHROME || '/Users/fischbeck3/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell'
const require = createRequire(import.meta.url)
const { chromium } = require(PW)
const LOCK_NAME = 'lock:sb-zddbfcokmvneltrgukzf-auth-token'
const BASE = 'http://127.0.0.1:8898'

let ROOT = ROOT_ARG, SNAP = null
if (REF) { SNAP = mkdtempSync(join(tmpdir(), 'ten-lock-')); execFileSync('bash', ['-c', `git -C "${ROOT_ARG}" archive --format=tar "${REF}" | tar -x -C "${SNAP}"`]); ROOT = SNAP }
const shipped = readFileSync(join(ROOT, 'index.html'), 'utf8')
const gitSha = (() => { try { return execFileSync('git', ['-C', ROOT_ARG, 'rev-parse', REF || 'HEAD'], { encoding: 'utf8' }).trim() } catch { return null } })()

/* the three variants, as response rewrites; each asserts it matched */
function variant(name) {
  let s = shipped
  const must = (from, to, n) => { const c = s.split(from).length - 1; if (c !== n) throw new Error(`${name}: expected ${n} of ${JSON.stringify(from.slice(0, 60))}, found ${c}`); s = s.split(from).join(to) }
  if (name === 'as-shipped') return s
  if (name === 'no-lock-option' || name === 'navigator-lock') {
    must('    lock: (_name, _timeout, fn) => fn(),\n', name === 'navigator-lock' ? '    lock: __tenNavigatorLock,\n' : '', 1)
    must('lock:(_n,_t,fn)=>fn()', name === 'navigator-lock' ? 'lock:(_n,_t,fn)=>fn()' : "storageKey:'cs-realtime'", 2)
  }
  if (name === 'navigator-lock') {
    must("import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.112.4';",
      "import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.112.4';\nimport { navigatorLock as __tenNavigatorLock } from 'https://esm.sh/@supabase/auth-js@2.112.4/es2022/auth-js.mjs';", 1)
  }
  return s
}

async function tab(context, { wedge = false } = {}) {
  const page = await context.newPage()
  const messages = []
  page.on('console', (m) => { if (['warning', 'error'].includes(m.type())) messages.push(m.type() + ': ' + m.text().slice(0, 160)) })
  if (wedge) {
    /* a zombie tab: loads a blank same-origin page and takes the exact lock
       auth-js would take, forever */
    await page.goto(BASE + '/__ten_blank', { waitUntil: 'load' })
    await page.evaluate((name) => { navigator.locks.request(name, () => new Promise(() => {})); return new Promise((r) => setTimeout(r, 200)) }, LOCK_NAME)
    return { page, messages }
  }
  return { page, messages }
}

async function bootAndMeasure(page, t0) {
  await page.goto(BASE + '/', { waitUntil: 'load', timeout: 30000 })
  const reached = await page.waitForFunction(() => {
    const ob = document.getElementById('onboard')
    const v = document.querySelector('.view.active')
    return window.bootStep === 'reveal' && ob && (ob.classList.contains('hide') || getComputedStyle(ob).display === 'none') && v && v.id === 'view-home'
  }, null, { timeout: 15000 }).then(() => true, () => false)
  const ms = Date.now() - t0
  const facts = await page.evaluate(async () => {
    let held = []
    try { const q = await navigator.locks.query(); held = (q.held || []).map((l) => l.name); } catch (_) {}
    const status = (document.getElementById('obStatus') || {}).textContent || ''
    return { locksRequested: window.__tenLocks ?? null, held, bootStep: window.bootStep || null, view: (document.querySelector('.view.active') || {}).id || null, doorStatus: status.slice(0, 120) }
  }).catch((e) => ({ error: String(e.message || e) }))
  return { reached, ms, ...facts }
}

async function run() {
  mkdirSync(OUT, { recursive: true })
  const browser = await chromium.launch({ headless: true, executablePath: CHROME })
  const cdn = cdnCache('/Users/fischbeck3/cup-season-claude-ten-gallery/wx/cdn-cache')
  const results = []
  try {
    for (const vname of ['as-shipped', 'no-lock-option', 'navigator-lock']) {
      const html = variant(vname)
      for (const scen of ['single', 'wedged-tab', 'refresh-race']) {
        const world = makeWorld('member', scen === 'refresh-race' ? { sessionTtl: 5 } : {})
        await loadHandlers(world)
        const api = worldApi(world)
        const context = await browser.newContext({ viewport: { width: 402, height: 874 }, serviceWorkers: 'block', reducedMotion: 'reduce', timezoneId: 'America/Phoenix' })
        await context.clock.install({ time: new Date(CAPTURE_NOW) })
        const log = [], gaps = []
        const handle = supabaseResponder({ world: api, gaps, log })
        await context.route('**/*', async (route, req) => {
          const u = new URL(req.url())
          if (SUPABASE_HOST.test(u.hostname)) return handle(route, req)
          if (CDN_HOSTS.has(u.hostname)) return cdn.handle(route, req)
          if (u.origin === BASE) {
            if (u.pathname === '/__ten_blank') return route.fulfill({ status: 200, contentType: 'text/html', body: '<!doctype html><title>zombie tab</title><p>holding the auth lock</p>' })
            if (u.pathname === '/' || u.pathname === '/index.html') return route.fulfill({ status: 200, contentType: 'text/html; charset=utf-8', body: html })
            const p = join(ROOT, decodeURIComponent(u.pathname))
            if (existsSync(p)) return route.fulfill({ status: 200, body: readFileSync(p) })
            return route.fulfill({ status: 404, body: '' })
          }
          return route.abort('blockedbyclient')
        })
        await context.routeWebSocket(/supabase\.co/, (ws) => realtimeMock(ws, log))
        await context.addInitScript((session) => {
          try { localStorage.setItem('cs_theme', 'dark'); localStorage.setItem('sb-zddbfcokmvneltrgukzf-auth-token', JSON.stringify(session)) } catch (_) {}
          try { const L = navigator.locks; window.__tenLocks = 0; if (L && L.request) { const o = L.request.bind(L); L.request = function (...a) { window.__tenLocks++; return o(...a) } } } catch (_) {}
        }, api.session)
        const row = { variant: vname, scenario: scen, tabs: [] }
        try {
          if (scen === 'single') {
            const a = await tab(context)
            row.tabs.push({ tab: 'A', ...(await bootAndMeasure(a.page, Date.now())), warnings: a.messages.filter((m) => /lock|GoTrue/i.test(m)) })
          } else if (scen === 'wedged-tab') {
            await tab(context, { wedge: true })
            const b = await tab(context)
            row.tabs.push({ tab: 'B (after a zombie tab took the auth lock)', ...(await bootAndMeasure(b.page, Date.now())), warnings: b.messages.filter((m) => /lock|GoTrue/i.test(m)) })
          } else {
            const a = await tab(context), b = await tab(context)
            const t0 = Date.now()
            const [ra, rb] = await Promise.all([bootAndMeasure(a.page, t0), bootAndMeasure(b.page, t0)])
            row.tabs.push({ tab: 'A', ...ra }, { tab: 'B', ...rb })
          }
        } catch (e) { row.error = String(e.message || e).split('\n')[0] }
        row.authRequests = log.filter((e) => (e.path || '').startsWith('/auth/v1/')).map((e) => `${e.method} ${e.path}${(e.query || '').slice(0, 30)} -> ${e.result}`)
        row.gaps = gaps.length
        results.push(row)
        const line = row.tabs.map((t) => `${t.tab}: ${t.reached ? 'HOME' : 'STUCK'} ${t.ms}ms locks=${t.locksRequested} held=${JSON.stringify(t.held)}`).join(' | ')
        console.log(`${vname.padEnd(15)} ${scen.padEnd(13)} ${line}${row.error ? ' ERROR ' + row.error : ''}`)
        await context.close()
      }
    }
  } finally {
    await browser.close()
    if (SNAP) rmSync(SNAP, { recursive: true, force: true })
  }
  const out = { probe: 'tests/ten-lock-probe.mjs', root: ROOT_ARG, ref: REF, gitSha, indexSha256: sha(Buffer.from(shipped)), lockName: LOCK_NAME, at: new Date().toISOString(), results }
  writeFileSync(join(OUT, 'lock-probe.json'), JSON.stringify(out, null, 1))
  console.log('\nwrote ' + join(OUT, 'lock-probe.json'))
}
run().catch((e) => { console.error(e); process.exit(1) })
