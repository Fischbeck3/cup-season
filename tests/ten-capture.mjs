#!/usr/bin/env node
/* Cup Season · the ten-capture harness (WX lane, "10/10" Wave A web half).
 *
 *   node tests/ten-capture.mjs --root <app dir> --port 8802 --out <dir>
 *        [--only family,...] [--states id,...] [--widths 375,402,1280,1600]
 *        [--themes dark,light] [--dsf 1] [--offline] [--list] [--explore]
 *
 * Renders every web family/state against the SHIPPED page served from --root
 * (python3 -m http.server on 127.0.0.1:<port>, started and stopped by PID
 * here), with a synthetic signed-in session and a synthetic world answering
 * every Supabase read (tests/fixtures/ten/world.mjs). For each capture:
 *   - a fresh browser context: service workers BLOCKED, caches empty, reduced
 *     motion, America/Phoenix, the capture clock fixed at cast.CAPTURE_NOW;
 *   - viewport 375x667 / 402x874 / 1280x1000 / 1600x1000 CSS px x dark/light,
 *     plus 375x380 (a short-height proxy) for keyboard-relevant states;
 *   - a DOM assertion that the intended view is the one actually showing
 *     (a fall-through to the Door, Home or a blank pane is FAILED);
 *   - page exceptions and console messages, each tagged `injected` (the
 *     state deliberately provoked it), `harness` (a request this harness
 *     aborted) or `normal` (normal operation -- the I04 table);
 *   - a manifest row: file, sha256, family, state, viewport, theme, route
 *     assertion, console summary, fixture gaps, git SHA and the sha256 of the
 *     index.html actually served.
 * No request reaches production Supabase: every *.supabase.co request and
 * the realtime socket are answered in-process or aborted and logged as a
 * fixture gap. Test-only; tests/ is not in the dist allowlist. */
import { createRequire } from 'node:module'
import { mkdirSync, writeFileSync, readFileSync, existsSync, mkdtempSync, rmSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join, resolve, dirname } from 'node:path'
import { execFileSync } from 'node:child_process'
import { fileURLToPath } from 'node:url'
import { startStaticServer, stopStaticServer, cdnCache, supabaseResponder, realtimeMock, SUPABASE_HOST, CDN_HOSTS, sha } from './ten-net.mjs'
import { makeWorld, loadHandlers, worldApi } from './fixtures/ten/world.mjs'
import { CAPTURE_NOW } from './fixtures/ten/cast.mjs'
import { STATES } from './ten-states.mjs'

const HERE = dirname(fileURLToPath(import.meta.url))
const args = process.argv.slice(2)
const arg = (k, d = null) => { const i = args.indexOf('--' + k); return i >= 0 && i + 1 < args.length && !args[i + 1].startsWith('--') ? args[i + 1] : d }
const flag = (k) => args.includes('--' + k)

const ROOT_ARG = resolve(arg('root', resolve(HERE, '..')))
/* --ref <commit>: serve a `git archive` snapshot of that commit instead of the
   working tree, so a run is one consistent source even while another session
   edits the checkout. The snapshot lives under the OS temp dir and is removed
   at exit. */
const REF = arg('ref', null)
let ROOT = ROOT_ARG
let SNAPSHOT = null
if (REF) {
  SNAPSHOT = mkdtempSync(join(tmpdir(), 'ten-snapshot-'))
  execFileSync('bash', ['-c', `git -C "${ROOT_ARG}" archive --format=tar "${REF}" | tar -x -C "${SNAPSHOT}"`])
  ROOT = SNAPSHOT
}
const PORT = parseInt(arg('port', '8802'), 10)
const OUT = resolve(arg('out', '/Users/fischbeck3/cup-season-claude-ten-gallery/wx/run'))
const ONLY = (arg('only', '') || '').split(',').filter(Boolean)
const ONLY_STATES = (arg('states', '') || '').split(',').filter(Boolean)
const WIDTHS = (arg('widths', '375,402,1280,1600')).split(',').map(Number).filter(Boolean)
const THEMES = (arg('themes', 'dark,light')).split(',').filter(Boolean)
const DSF = Number(arg('dsf', '1'))
const CDN_DIR = resolve(arg('cdn-cache', '/Users/fischbeck3/cup-season-claude-ten-gallery/wx/cdn-cache'))
const PW = arg('playwright', process.env.TEN_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const CHROME = arg('chrome', process.env.TEN_CHROME || '/Users/fischbeck3/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell')
const SERVE = arg('serve', 'http')   /* http: python3 http.server on --port (the default, the lane's own port) · route: files answered from --root in-process, no port bound */
const HEIGHTS = { 375: 667, 402: 874, 1280: 1000, 1600: 1000 }
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.mjs': 'text/javascript', '.json': 'application/json', '.css': 'text/css',
  '.svg': 'image/svg+xml', '.png': 'image/png', '.jpg': 'image/jpeg', '.webmanifest': 'application/manifest+json', '.ico': 'image/x-icon', '.woff2': 'font/woff2', '.ttf': 'font/ttf', '.otf': 'font/otf' }
function diskFile(pathname) {
  let p = decodeURIComponent(pathname)
  if (p === '/' || p.endsWith('/')) p += 'index.html'
  const full = resolve(ROOT, '.' + p)
  if (!full.startsWith(ROOT) || !existsSync(full)) return null
  const ext = (p.match(/\.[a-z0-9]+$/i) || [''])[0].toLowerCase()
  return { body: readFileSync(full), type: MIME[ext] || 'application/octet-stream' }
}
const SHORT = { width: 375, height: 380 }

const require = createRequire(import.meta.url)
const { chromium } = require(PW)

/* `probe: true` states are defect probes, not gallery states: they run only when their family is named in --only */
const selected = STATES.filter((s) => (!ONLY.length ? !s.probe : ONLY.includes(s.family)) && (!ONLY_STATES.length || ONLY_STATES.includes(s.id) || ONLY_STATES.includes(`${s.family}/${s.id}`)))
if (flag('list')) {
  for (const s of STATES) console.log(`${s.family.padEnd(14)} ${s.id.padEnd(34)} ${s.variant || ''}${s.short ? ' +short' : ''}${s.desk ? ' desk-only' : ''}`)
  process.exit(0)
}

function git(root, ...a) { try { return execFileSync('git', ['-C', root, ...a], { encoding: 'utf8' }).trim() } catch { return null } }
const gitSha = git(ROOT_ARG, 'rev-parse', REF || 'HEAD')
const gitDirty = REF ? false : (git(ROOT_ARG, 'status', '--porcelain', '--', 'index.html') || '').length > 0
const harnessSha = git(HERE, 'rev-parse', 'HEAD')
const diskIndexSha = sha(readFileSync(join(ROOT, 'index.html')))

/* classify one console line: `injected` when the state said it would provoke
   it, `harness` when it is the browser reporting a request we aborted or the
   worker we blocked, `normal` otherwise */
function classify(state, m, abortedUrls) {
  const t = m.text || ''
  if ((state.expectConsole || []).some((re) => re.test(t))) return 'injected'
  if (/^Failed to load resource/.test(t) && m.url && abortedUrls.has(m.url)) return 'harness'
  if (/Service Worker registration blocked by Playwright/.test(t)) return 'harness'
  return 'normal'
}

async function captureOne(browser, state, vp, theme, cdn) {
  const world = makeWorld(state.variant || 'member', state.world || {})
  await loadHandlers(world)
  if (state.prepare) await state.prepare(world)
  const api = worldApi(world)
  const context = await browser.newContext({
    viewport: { width: vp.width, height: vp.height }, deviceScaleFactor: DSF, colorScheme: theme, reducedMotion: 'reduce',
    serviceWorkers: 'block', timezoneId: 'America/Phoenix', locale: 'en-US',
  })
  await context.clock.install({ time: new Date(CAPTURE_NOW) })
  const log = [], gaps = [], blocked = [], messages = [], exceptions = [], aborted = new Set(), served = {}
  const storm = { hit: false }
  const hold = state.hold ? { match: state.hold, released: false, waiters: [], wait() { return this.released ? Promise.resolve() : new Promise((r) => this.waiters.push(r)) }, release() { this.released = true; this.waiters.splice(0).forEach((r) => r()) } } : null
  const handle = supabaseResponder({ world: api, gaps, log, hold, storm, limit: state.requestLimit || 1500 })
  const base = `http://127.0.0.1:${PORT}`
  await context.route('**/*', async (route, req) => {
    const u = new URL(req.url())
    if (SUPABASE_HOST.test(u.hostname)) {
      const before = gaps.length
      const r = await handle(route, req)
      if (gaps.length > before) aborted.add(req.url())
      return r
    }
    if (CDN_HOSTS.has(u.hostname)) return cdn.handle(route, req)
    if (u.origin === base) {
      /* the synthetic Home-state payloads replace the legacy file that names pilot people */
      if (u.pathname === '/tests/fixtures/home-states.json') {
        return route.fulfill({ status: 200, contentType: 'application/json', body: readFileSync(join(HERE, 'fixtures/ten/home-states.synthetic.json')) })
      }
      if (SERVE === 'route') {
        const f = diskFile(u.pathname)
        if (!f) return route.fulfill({ status: 404, body: '' })
        if (req.resourceType() === 'document') served[u.pathname] = sha(f.body)
        return route.fulfill({ status: 200, contentType: f.type, headers: { 'cache-control': 'no-store' }, body: f.body })
      }
      if (req.resourceType() === 'document') {
        const resp = await route.fetch()
        const body = await resp.body()
        served[u.pathname] = sha(body)
        return route.fulfill({ response: resp, body })
      }
      return route.continue()
    }
    blocked.push(req.url()); aborted.add(req.url())
    return route.abort('blockedbyclient')
  })
  await context.routeWebSocket(/supabase\.co/, (ws) => realtimeMock(ws, log))
  const session = api.session
  await context.addInitScript(({ theme, session, ls }) => {
    try {
      localStorage.setItem('cs_theme', theme)
      if (session) localStorage.setItem('sb-zddbfcokmvneltrgukzf-auth-token', JSON.stringify(session))
      for (const [k, v] of Object.entries(ls || {})) localStorage.setItem(k, v)
    } catch (_) {}
  }, { theme, session, ls: state.localStorage || {} })
  /* instrumentation only: count navigator.locks.request calls (the
     origin-wide lock CLAUDE.md warns about); calls pass straight through */
  await context.addInitScript(() => {
    /* instrumentation only: route-fulfilled requests leave no Resource Timing
       entry, so a state that must prove a read happened reads this list; the
       wrapper records the URL, method and status and changes nothing */
    try {
      window.__tenNet = []
      const f = window.fetch.bind(window)
      window.fetch = async function (input, init) {
        const url = typeof input === 'string' ? input : (input && input.url) || String(input)
        const method = (init && init.method) || (input && input.method) || 'GET'
        const rec = { url: String(url).slice(0, 300), method, status: null }
        if (window.__tenNet.length < 3000) window.__tenNet.push(rec)
        try { const r = await f(input, init); rec.status = r.status; return r } catch (e) { rec.status = 'failed'; throw e }
      }
    } catch (_) {}
    try {
      const L = navigator.locks
      window.__tenLocks = 0
      if (L && L.request) { const orig = L.request.bind(L); L.request = function (...a) { window.__tenLocks++; return orig(...a) } }
    } catch (_) {}
  })
  const page = await context.newPage()
  const cdp = await context.newCDPSession(page)
  await cdp.send('Runtime.enable')
  cdp.on('Runtime.consoleAPICalled', (e) => {
    const frames = (e.stackTrace && e.stackTrace.callFrames) || []
    const ownFrames = frames.filter((f) => /127\.0\.0\.1/.test(f.url) && /\/(index\.html)?$/.test(f.url.replace(/\?.*$/, '')))
    const own = ownFrames[0]
    const text = (e.args || []).map((a) => a.value !== undefined ? (typeof a.value === 'string' ? a.value : JSON.stringify(a.value)) : (a.description || a.unserializableValue || '')).join(' ')
    messages.push({ level: e.type, text: text.slice(0, 1200), src: frames[0] ? `${frames[0].url.replace(base, '')}:${frames[0].lineNumber + 1}` : null, indexLine: own ? own.lineNumber + 1 : null, indexFrames: ownFrames.slice(0, 4).map((f) => `${f.functionName || '(anon)'}:${f.lineNumber + 1}`), via: 'console' })
  })
  /* browser-originated lines (network failures, deprecations, interventions,
     CSP, violations) arrive on the Log domain, never as console API calls */
  await cdp.send('Log.enable')
  cdp.on('Log.entryAdded', ({ entry }) => {
    if (entry.source === 'console-api') return
    messages.push({ level: entry.level === 'warning' ? 'warning' : entry.level, text: String(entry.text || '').slice(0, 1200), url: entry.url || null,
      src: entry.source === 'network' ? 'network' : `browser:${entry.source}${entry.url ? ' ' + entry.url.replace(base, '') + (entry.lineNumber != null ? ':' + (entry.lineNumber + 1) : '') : ''}`,
      indexLine: entry.url && entry.url.replace(/\?.*$/, '').replace(base, '').match(/^\/(index\.html)?$/) && entry.lineNumber != null ? entry.lineNumber + 1 : null, via: 'browser' })
  })
  page.on('pageerror', (e) => exceptions.push({ text: String(e.message).slice(0, 600), stack: String(e.stack || '').split('\n').slice(0, 6).join(' <- ') }))

  const t0 = Date.now()
  const result = { assert: { ok: false, detail: 'not run' } }
  try {
    await page.goto(base + (state.url || '/'), { waitUntil: 'load', timeout: 30000 })
    if (!state.noSwClear) {
      result.swClear = await page.evaluate(async () => {
        const out = { regs: 0, caches: 0 }
        try { const rs = await navigator.serviceWorker.getRegistrations(); out.regs = rs.length; await Promise.all(rs.map((r) => r.unregister())) } catch (_) {}
        try { const ks = await caches.keys(); out.caches = ks.length; await Promise.all(ks.map((k) => caches.delete(k))) } catch (_) {}
        return out
      })
    }
    await (state.settle ? state.settle(page) : settleDefault(page, state))
    if (state.drive) await state.drive(page, { world, hold, vp, theme })
    await page.evaluate(() => document.fonts && document.fonts.ready).catch(() => {})
    await page.waitForTimeout(state.pause || 250)
    result.assert = await assertRoute(page, state)
    result.geometry = await page.evaluate(() => ({ overflowX: Math.max(0, document.documentElement.scrollWidth - innerWidth), docH: document.documentElement.scrollHeight })).catch(() => null)
    result.locks = await page.evaluate(() => window.__tenLocks).catch(() => null)
  } catch (e) {
    result.assert = { ok: false, detail: 'driver: ' + String(e.message || e).split('\n')[0] }
  }
  /* a held request (the "sending" state) stays held until after the screenshot */
  return { page, context, cdp, world, log, gaps, blocked, messages, exceptions, aborted, served, storm, result, hold, ms: Date.now() - t0 }
}

async function settleDefault(page, state) {
  if (state.variant === 'signed_out' || state.signedOut) { await page.waitForSelector('#obEmail', { timeout: 15000 }); await page.waitForTimeout(400); return }
  /* the signed-in boot is done when the door is gone (or the card gate shows) */
  await page.waitForFunction(() => {
    const ob = document.getElementById('onboard')
    const gate = document.querySelector('#profileGate, .pgate, #obCard')
    const hidden = ob && (ob.classList.contains('hide') || getComputedStyle(ob).display === 'none')
    return (window.bootStep === 'reveal' || typeof window.bootStep === 'undefined') && (hidden || (gate && gate.offsetParent !== null))
  }, null, { timeout: 20000 }).catch(() => {})
  await page.waitForTimeout(state.bootPause || 1800)
}

/* the route assertion: the state names what must be true; a generic floor
   catches the three fall-throughs (the Door, Home, a blank pane) */
async function assertRoute(page, state) {
  const facts = await page.evaluate(() => {
    const ob = document.getElementById('onboard')
    const obShown = !!ob && !ob.classList.contains('hide') && getComputedStyle(ob).display !== 'none'
    const view = document.querySelector('.view.active')
    const sheet = document.getElementById('sheet')
    const sheetOpen = !!sheet && (sheet.classList.contains('open') || sheet.classList.contains('show') || getComputedStyle(sheet).display !== 'none' && getComputedStyle(sheet).visibility !== 'hidden' && parseFloat(getComputedStyle(sheet).opacity) > 0.5)
    const vtext = view ? view.innerText.trim().length : 0
    return { obShown, view: view ? view.id : null, vtext, sheetOpen, sheetTitle: sheetOpen ? (document.getElementById('shTitle') || {}).textContent : null, title: document.title }
  })
  const exp = state.expect || {}
  const why = []
  if (exp.door) { if (!facts.obShown) why.push('expected the Door, it is hidden') }
  else if (exp.overlay) { /* overlay states (share view, unsubscribe) are checked by their own selector */ }
  else if (facts.obShown && !exp.allowDoor) why.push('fell through to the Door')
  if (exp.view) {
    if (facts.view !== exp.view) why.push(`active view is ${facts.view}, expected ${exp.view}`)
    else if (facts.vtext < (exp.minText || 20)) why.push(`active view ${facts.view} is blank (${facts.vtext} chars)`)
  }
  if (exp.sheet === true && !facts.sheetOpen) why.push('expected the sheet open')
  if (exp.sheet && exp.sheet !== true && !(facts.sheetOpen && new RegExp(exp.sheet).test(facts.sheetTitle || ''))) why.push(`expected sheet "${exp.sheet}", got ${facts.sheetOpen ? JSON.stringify(facts.sheetTitle) : 'none'}`)
  for (const [sel, want] of Object.entries(exp.selectors || {})) {
    const got = await page.evaluate(([sel, want]) => {
      const el = document.querySelector(sel)
      if (!el) return { ok: false, why: 'missing ' + sel }
      const r = el.getBoundingClientRect(), cs = getComputedStyle(el)
      const visible = r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' && cs.display !== 'none'
      if (want === 'visible' && !visible) return { ok: false, why: sel + ' not visible' }
      if (want === 'hidden' && visible) return { ok: false, why: sel + ' visible' }
      if (typeof want === 'string' && want.startsWith('text:') && !new RegExp(want.slice(5), 'i').test(el.innerText || el.textContent || '')) return { ok: false, why: `${sel} text ${JSON.stringify((el.innerText || '').slice(0, 80))} !~ ${want.slice(5)}` }
      return { ok: true }
    }, [sel, want])
    if (!got.ok) why.push(got.why)
  }
  if (state.check) { try { const c = await state.check(page); if (c && c !== true) why.push(String(c)) } catch (e) { why.push('check: ' + e.message.split('\n')[0]) } }
  return { ok: why.length === 0, detail: why.join('; ') || 'ok', facts }
}

async function main() {
  mkdirSync(OUT, { recursive: true })
  const srv = SERVE === 'route' ? { pid: null, base: `http://127.0.0.1:${PORT}` } : await startStaticServer({ root: ROOT, port: PORT })
  const stop = () => { stopStaticServer(srv); if (SNAPSHOT) { try { rmSync(SNAPSHOT, { recursive: true, force: true }) } catch { /* temp */ } } }
  process.on('SIGINT', () => { stop(); process.exit(130) })
  process.on('SIGTERM', () => { stop(); process.exit(143) })
  const browser = await chromium.launch({ headless: true, executablePath: CHROME, args: ['--hide-scrollbars', '--force-color-profile=srgb', '--font-render-hinting=none'] })
  const cdn = cdnCache(CDN_DIR, { offline: flag('offline') })
  const rows = []
  const t0 = Date.now()
  console.log(`ten-capture · root ${ROOT} @ ${gitSha ? gitSha.slice(0, 10) : '?'}${gitDirty ? ' (index.html dirty)' : ''} · ${selected.length} state(s) · ${SERVE === 'route' ? 'served in-process (no port bound)' : `server pid ${srv.pid} on :${PORT}`}`)
  /* the job list: every state x viewport x theme, in catalogue order; a pool
     of --workers contexts runs them (each capture still gets its own fresh
     context); rows are written back in job order so manifests diff cleanly */
  const jobs = []
  for (const state of selected) {
    const widths = state.desk ? WIDTHS.filter((w) => w >= 1280) : state.phoneOnly ? WIDTHS.filter((w) => w < 900) : WIDTHS
    const vps = widths.map((w) => ({ width: w, height: state.height || HEIGHTS[w] || 1000, tag: String(w) }))
    if (state.short) vps.push({ ...SHORT, tag: '375x380' })
    for (const vp of vps) for (const theme of (state.themes || THEMES)) jobs.push({ state, vp, theme, i: jobs.length })
  }
  const slots = new Array(jobs.length)
  let next = 0
  async function runJob({ state, vp, theme, i }) {
    const file = `${state.family}--${state.id}--${vp.tag}--${theme}.png`
    let cap
    try {
      cap = await captureOne(browser, state, vp, theme, cdn)
      const fullPage = state.fullPage !== false && !(vp.tag === '375x380')
      if (state.shot) await cap.page.locator(state.shot).first().screenshot({ path: join(OUT, file), animations: 'disabled', caret: 'hide', timeout: 30000 })
      else await cap.page.screenshot({ path: join(OUT, file), fullPage, animations: 'disabled', caret: 'hide', timeout: 30000 })
    } catch (e) {
      slots[i] = { file: null, family: state.family, state: state.id, viewport: vp, theme, error: String(e.message || e).split('\n')[0] }
      console.log(`  ERROR ${file}: ${String(e.message || e).split('\n')[0]}`)
      if (cap) { if (cap.hold && !cap.hold.released) cap.hold.release(); await cap.context.close().catch(() => {}) }
      return
    }
    if (cap.hold && !cap.hold.released) cap.hold.release()
    await cap.page.waitForTimeout(50)
    const buf = readFileSync(join(OUT, file))
    const msgs = cap.messages.map((m) => ({ ...m, category: classify(state, m, cap.aborted) }))
    const summary = { total: msgs.length, byLevel: {}, byCategory: {}, exceptions: cap.exceptions.length }
    for (const m of msgs) { summary.byLevel[m.level] = (summary.byLevel[m.level] || 0) + 1; summary.byCategory[m.category] = (summary.byCategory[m.category] || 0) + 1 }
    const row = {
      file, sha256: sha(buf), bytes: buf.length, family: state.family, state: state.id, title: state.title || null,
      variant: state.variant || 'member', url: state.url || '/', viewport: { width: vp.width, height: vp.height }, theme, dsf: DSF,
      route: { ok: cap.result.assert.ok, detail: cap.result.assert.detail, activeView: cap.result.assert.facts ? cap.result.assert.facts.view : null, door: cap.result.assert.facts ? cap.result.assert.facts.obShown : null },
      console: summary, messages: msgs, pageErrors: cap.exceptions, fixtureGaps: cap.gaps, blockedRequests: cap.blocked,
      requestStorm: cap.storm.hit, supabaseRequests: cap.log.filter((e) => e.path || e.ws).length,
      geometry: cap.result.geometry, swClear: cap.result.swClear || null, navigatorLocksRequests: cap.result.locks,
      authRequests: cap.log.filter((e) => (e.path || '').startsWith('/auth/v1/')).map((e) => `${e.method} ${e.path}${(e.query || '').slice(0, 40)} -> ${e.result}`),
      gitSha, indexDirty: gitDirty, indexSha256Served: cap.served['/'] || cap.served['/index.html'] || null, indexSha256Disk: diskIndexSha,
      capturedAt: new Date().toISOString(), ms: cap.ms,
    }
    slots[i] = row
    const mark = row.route.ok ? 'ok  ' : 'FAIL'
    console.log(`  ${mark} ${file}  view=${row.route.activeView} gaps=${cap.gaps.length} normal=${summary.byCategory.normal || 0} exc=${cap.exceptions.length}${row.requestStorm ? ' STORM' : ''}${row.route.ok ? '' : '  -- ' + row.route.detail}`)
    if (flag('explore')) writeFileSync(join(OUT, file.replace(/\.png$/, '.requests.json')), JSON.stringify(cap.log, null, 1))
    await cap.context.close().catch(() => {})
  }
  try {
    const WORKERS = Math.max(1, parseInt(arg('workers', '1'), 10) || 1)
    await Promise.all(Array.from({ length: Math.min(WORKERS, jobs.length || 1) }, async () => {
      while (next < jobs.length) { const j = jobs[next++]; await runJob(j) }
    }))
    rows.push(...slots.filter(Boolean))
  } finally {
    await browser.close().catch(() => {})
    stop()
  }
  const manifest = {
    harness: 'tests/ten-capture.mjs', harnessGitSha: harnessSha, root: ROOT_ARG, ref: REF, servedFrom: SNAPSHOT ? 'git archive snapshot of ' + REF : 'working tree', gitSha, indexDirty: gitDirty, indexSha256Disk: diskIndexSha,
    indexSha256DiskAfter: SNAPSHOT ? diskIndexSha : sha(readFileSync(join(ROOT, 'index.html'))), captureClock: CAPTURE_NOW, port: PORT, serverPid: srv.pid,
    serve: SERVE, widths: WIDTHS, themes: THEMES, dsf: DSF, cdn: cdn.stats, startedAt: new Date(t0).toISOString(), finishedAt: new Date().toISOString(),
    serviceWorkers: 'blocked per context (Playwright serviceWorkers:block); registrations unregistered and caches cleared after load',
    network: 'every *.supabase.co request and the realtime socket answered in-process from tests/fixtures/ten or aborted as a fixture gap; esm.sh and Google Fonts replayed from the local record/replay cache; anything else aborted',
    counts: {
      captures: rows.filter((r) => r.file).length, errors: rows.filter((r) => !r.file).length,
      routeFailed: rows.filter((r) => r.file && !r.route.ok).length,
      withGaps: rows.filter((r) => r.fixtureGaps && r.fixtureGaps.length).length,
      withPageErrors: rows.filter((r) => r.pageErrors && r.pageErrors.length).length,
      storms: rows.filter((r) => r.requestStorm).length,
    },
    rows,
  }
  writeFileSync(join(OUT, 'manifest.json'), JSON.stringify(manifest, null, 1))
  console.log(`\n${manifest.counts.captures} capture(s), ${manifest.counts.routeFailed} route failure(s), ${manifest.counts.errors} error(s), ${manifest.counts.withGaps} with fixture gaps, ${manifest.counts.withPageErrors} with page errors · ${((Date.now() - t0) / 1000).toFixed(0)}s · manifest ${join(OUT, 'manifest.json')}`)
  if (manifest.indexSha256DiskAfter !== diskIndexSha) console.log('WARNING: index.html changed on disk during the run; per-row indexSha256Served says which bytes each capture saw.')
}

main().catch((e) => { console.error(e); process.exit(1) })
