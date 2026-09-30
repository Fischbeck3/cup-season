#!/usr/bin/env node
/* ============================================================================
 * split-scripts-measure.mjs — the before/after proof for tools/split-scripts.mjs
 * (Q12 part 2). Read-only against two roots; writes only under --out.
 *
 * Method: the round-2 web audit's performance section (AW2-01 / AW2-12,
 * evidence/r2-fd27ace4/audit-web/probe/aw2-probe.mjs, SECTION 'perf'): a cold
 * load at 375x667, dark, CPU throttled with CDP Emulation.setCPUThrottlingRate,
 * every *.supabase.co request answered in-process by the harness's synthetic
 * world, esm.sh + Google Fonts replayed offline from the harness cache (a miss
 * aborts), the root's files answered in-process (no port is bound), anything
 * else aborted. CLS is the audit's layout-shift observer (no recent input);
 * ScriptDuration is CDP Performance.getMetrics. Added here: a Chrome trace of
 * the page, so script parse/compile is split by thread — main thread
 * (CrRendererMain) versus V8's background streaming/compile threads.
 *
 *   node tools/split-scripts-measure.mjs --before <root> --after <root> --out <dir>
 *        [--cpu 4] [--runs 3] [--kinds door,home]
 * ========================================================================== */
import { createRequire } from 'node:module'
import { mkdirSync, writeFileSync, readFileSync, existsSync } from 'node:fs'
import { join, resolve } from 'node:path'

const args = process.argv.slice(2)
const arg = (k, d = null) => { const i = args.indexOf('--' + k); return i >= 0 && i + 1 < args.length ? args[i + 1] : d }
const ROOTS = { before: resolve(arg('before')), after: resolve(arg('after')) }
const OUT = resolve(arg('out', './split-measure'))
const CPU = Number(arg('cpu', '4'))
const RUNS = Number(arg('runs', '3'))
const KINDS = arg('kinds', 'door,home').split(',')
const BASE = 'http://127.0.0.1:8865'   /* never listened on: every request is answered by the route */
const HOME = process.env.HOME   /* the harness's own defaults (tests/ten-capture.mjs), from $HOME */
const PW = arg('playwright', process.env.TEN_PLAYWRIGHT || HOME + '/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const CHROME = arg('chrome', process.env.TEN_CHROME || HOME + '/Library/Caches/ms-playwright/chromium_headless_shell-1243/chrome-headless-shell-mac-arm64/chrome-headless-shell')
const CDN_DIR = resolve(arg('cdn-cache', HOME + '/cup-season-claude-ten-gallery/wx/cdn-cache'))
const MIME = { '.html': 'text/html; charset=utf-8', '.js': 'text/javascript', '.json': 'application/json', '.css': 'text/css', '.svg': 'image/svg+xml', '.png': 'image/png', '.webmanifest': 'application/manifest+json', '.woff2': 'font/woff2' }
mkdirSync(OUT, { recursive: true })

const H = ROOTS.before   /* the harness modules are identical in both roots (only index.html + app/ differ) */
const { supabaseResponder, realtimeMock, cdnCache, SUPABASE_HOST, CDN_HOSTS } = await import(H + '/tests/ten-net.mjs')
const { makeWorld, loadHandlers, worldApi } = await import(H + '/tests/fixtures/ten/world.mjs')
const require = createRequire(import.meta.url)
const { chromium } = require(PW)
if (!existsSync(CDN_DIR)) throw new Error('no cdn cache')
const cdn = cdnCache(CDN_DIR, { offline: true })

const OBS = () => {
  window.__perf = { lt: [], lcp: null, cls: 0, shifts: [] }
  try { new PerformanceObserver((l) => { for (const e of l.getEntries()) window.__perf.lt.push([Math.round(e.startTime), Math.round(e.duration)]) }).observe({ type: 'longtask', buffered: true }) } catch (_) {}
  try { new PerformanceObserver((l) => { const es = l.getEntries(); const e = es[es.length - 1]; window.__perf.lcp = Math.round(e.startTime) }).observe({ type: 'largest-contentful-paint', buffered: true }) } catch (_) {}
  try { new PerformanceObserver((l) => { for (const e of l.getEntries()) if (!e.hadRecentInput) { window.__perf.cls += e.value; window.__perf.shifts.push([Math.round(e.startTime), +e.value.toFixed(4)]) } }).observe({ type: 'layout-shift', buffered: true }) } catch (_) {}
}

/* trace event names -> buckets (durations are µs in the trace) */
const COMPILE = new Set(['v8.compile', 'v8.compileModule', 'V8.CompileCode', 'V8.CompileLazy', 'v8.parseOnBackground', 'V8.ParseProgram', 'V8.ParseFunction', 'V8.CompileScript', 'V8.StreamingFinalization'])
const EVAL = new Set(['EvaluateScript', 'v8.evaluateModule'])
function digest(trace) {
  const ev = trace.traceEvents || trace
  const tname = new Map()
  for (const e of ev) if (e.ph === 'M' && e.name === 'thread_name') tname.set(e.pid + ':' + e.tid, e.args && e.args.name)
  const main = new Set([...tname].filter(([, n]) => n === 'CrRendererMain').map(([k]) => k))
  const out = { mainCompileMs: 0, bgCompileMs: 0, mainEvalMs: 0, parseHtmlMs: 0, mainCompileByName: {}, bgCompileByName: {} }
  /* nested X events of the same bucket double count: keep only the outermost per thread */
  const byThread = new Map()
  for (const e of ev) if (e.ph === 'X' && e.dur) { const k = e.pid + ':' + e.tid; (byThread.get(k) || byThread.set(k, []).get(k)).push(e) }
  for (const [k, list] of byThread) {
    list.sort((a, b) => a.ts - b.ts || b.dur - a.dur)
    const isMain = main.has(k)
    let compileEnd = -1, evalEnd = -1, htmlEnd = -1
    for (const e of list) {
      if (COMPILE.has(e.name) && e.ts >= compileEnd) {
        compileEnd = e.ts + e.dur
        if (isMain) { out.mainCompileMs += e.dur / 1000; out.mainCompileByName[e.name] = (out.mainCompileByName[e.name] || 0) + e.dur / 1000 }
        else { out.bgCompileMs += e.dur / 1000; out.bgCompileByName[e.name] = (out.bgCompileByName[e.name] || 0) + e.dur / 1000 }
      }
      if (isMain && EVAL.has(e.name) && e.ts >= evalEnd) { evalEnd = e.ts + e.dur; out.mainEvalMs += e.dur / 1000 }
      if (isMain && e.name === 'ParseHTML' && e.ts >= htmlEnd) { htmlEnd = e.ts + e.dur; out.parseHtmlMs += e.dur / 1000 }
    }
  }
  for (const k of ['mainCompileMs', 'bgCompileMs', 'mainEvalMs', 'parseHtmlMs']) out[k] = +out[k].toFixed(1)
  for (const o of [out.mainCompileByName, out.bgCompileByName]) for (const k in o) o[k] = +o[k].toFixed(1)
  return out
}

async function once(browser, which, kind) {
  const ROOT = ROOTS[which]
  const variant = kind === 'door' ? 'signed_out' : 'member'
  const world = makeWorld(variant, {}); await loadHandlers(world); const api = worldApi(world)
  const context = await browser.newContext({ viewport: { width: 375, height: 667 }, deviceScaleFactor: 1, colorScheme: 'dark', reducedMotion: 'reduce', serviceWorkers: 'block', timezoneId: 'America/Phoenix', locale: 'en-US' })
  const gaps = [], log = [], served = [], aborted = []
  const handle = supabaseResponder({ world: api, gaps, log, hold: null, storm: { hit: false }, limit: 3000 })
  await context.route('**/*', async (route, req) => {
    const u = new URL(req.url())
    if (SUPABASE_HOST.test(u.hostname)) return handle(route, req)
    if (CDN_HOSTS.has(u.hostname)) return cdn.handle(route, req)
    if (u.origin === BASE) {
      if (u.pathname === '/tests/fixtures/home-states.json') return route.fulfill({ status: 200, contentType: 'application/json', body: readFileSync(ROOT + '/tests/fixtures/ten/home-states.synthetic.json') })
      let p = decodeURIComponent(u.pathname); if (p.endsWith('/')) p += 'index.html'
      const full = ROOT + p
      if (p.includes('..') || !existsSync(full)) return route.fulfill({ status: 404, body: '' })
      const ext = (p.match(/\.[a-z0-9]+$/i) || [''])[0].toLowerCase()
      served.push(p)
      return route.fulfill({ status: 200, contentType: MIME[ext] || 'application/octet-stream', headers: { 'cache-control': 'no-store' }, body: readFileSync(full) })
    }
    aborted.push(req.url().slice(0, 120)); return route.abort('blockedbyclient')
  })
  await context.routeWebSocket(/supabase\.co/, (ws) => realtimeMock(ws, log))
  await context.addInitScript(({ session }) => { try { localStorage.setItem('cs_theme', 'dark'); if (session) localStorage.setItem('sb-zddbfcokmvneltrgukzf-auth-token', JSON.stringify(session)) } catch (_) {} }, { session: variant === 'signed_out' ? null : api.session })
  await context.addInitScript(OBS)
  const page = await context.newPage()
  const errors = []
  page.on('pageerror', (e) => errors.push(String(e.message).slice(0, 200)))
  page.on('console', (m) => { if (m.type() === 'error') errors.push('console.error: ' + m.text().slice(0, 200)) })
  const cdp = await context.newCDPSession(page)
  await cdp.send('Performance.enable')
  if (CPU > 1) await cdp.send('Emulation.setCPUThrottlingRate', { rate: CPU })
  await browser.startTracing(page, { screenshots: false, categories: ['devtools.timeline', 'v8', 'v8.execute', 'disabled-by-default-devtools.timeline', 'disabled-by-default-v8.compile', 'blink', '__metadata'] })
  const t0 = Date.now()
  await page.goto(BASE + '/', { waitUntil: 'load', timeout: 120000 })
  let ready = null
  if (kind === 'door') { await page.waitForSelector('#obEmail', { timeout: 60000 }); ready = Date.now() - t0 }
  else { await page.waitForFunction(() => { const ob = document.getElementById('onboard'); const v = document.querySelector('.view.active'); return ob && (ob.classList.contains('hide') || getComputedStyle(ob).display === 'none') && v && v.id === 'view-home' && v.innerText.trim().length > 200 }, null, { timeout: 90000 }).catch(() => {}); ready = Date.now() - t0 }
  await page.waitForTimeout(3500)
  const trace = JSON.parse((await browser.stopTracing()).toString('utf8'))
  const st = await page.evaluate(() => {
    const nav = performance.getEntriesByType('navigation')[0]
    const fcp = (performance.getEntriesByType('paint').find((p) => p.name === 'first-contentful-paint') || {}).startTime
    const ob = document.getElementById('onboard'); const v = document.querySelector('.view.active')
    return { dcl: Math.round(nav.domContentLoadedEventEnd), load: Math.round(nav.loadEventEnd), docBytes: nav.decodedBodySize, fcp: Math.round(fcp || 0), perf: window.__perf,
      door: ob ? (ob.classList.contains('hide') ? 'hidden' : 'shown') : null, view: v && v.id, obEmail: !!document.getElementById('obEmail'),
      bridges: { CS: typeof window.CS, sb: typeof window.sb, renderFormation: typeof window.renderFormation }, bootStep: typeof bootStep !== 'undefined' ? String(bootStep) : null }
  })
  const { metrics } = await cdp.send('Performance.getMetrics')
  const M = Object.fromEntries(metrics.map((m) => [m.name, m.value]))
  await cdp.detach().catch(() => {}); await context.close()
  const lt = st.perf.lt || []
  return { which, kind, readyMs: ready, dcl: st.dcl, load: st.load, fcp: st.fcp, lcp: st.perf.lcp, cls: +st.perf.cls.toFixed(4), shifts: st.perf.shifts.slice(0, 12),
    longTaskTotal: lt.reduce((s, x) => s + x[1], 0), longTaskMax: lt.reduce((m, x) => Math.max(m, x[1]), 0),
    ScriptDurationMs: +((M.ScriptDuration || 0) * 1000).toFixed(1), TaskDurationMs: +((M.TaskDuration || 0) * 1000).toFixed(1),
    trace: digest(trace), docBytes: st.docBytes, served: [...new Set(served)].filter((p) => /index\.html|\/app\//.test(p)),
    end: { door: st.door, view: st.view, obEmail: st.obEmail, bridges: st.bridges, bootStep: st.bootStep },
    errors, supabaseGaps: gaps.length, aborted: aborted.length }
}

const med = (xs) => { const s = [...xs].sort((a, b) => a - b); return s.length ? s[Math.floor((s.length - 1) / 2)] : null }
const browser = await chromium.launch({ executablePath: CHROME, headless: true })
const rows = []
for (const kind of KINDS) for (let r = 0; r < RUNS; r++) for (const which of ['before', 'after']) {   /* interleaved, so drift hits both */
  const row = await once(browser, which, kind); row.run = r; rows.push(row)
  console.log(`${kind.padEnd(5)} ${which.padEnd(6)} r${r} · mainCompile ${row.trace.mainCompileMs} ms · bgCompile ${row.trace.bgCompileMs} ms · mainEval ${row.trace.mainEvalMs} ms · ParseHTML ${row.trace.parseHtmlMs} ms · Script ${row.ScriptDurationMs} ms · CLS ${row.cls} · FCP ${row.fcp} · ready ${row.readyMs} ms · errors ${row.errors.length}`)
}
await browser.close()
const summary = {}
for (const kind of KINDS) for (const which of ['before', 'after']) {
  const rs = rows.filter((x) => x.kind === kind && x.which === which)
  summary[`${kind}-${which}`] = { runs: rs.length, mainCompileMs: med(rs.map((x) => x.trace.mainCompileMs)), bgCompileMs: med(rs.map((x) => x.trace.bgCompileMs)), mainEvalMs: med(rs.map((x) => x.trace.mainEvalMs)), parseHtmlMs: med(rs.map((x) => x.trace.parseHtmlMs)),
    ScriptDurationMs: med(rs.map((x) => x.ScriptDurationMs)), cls: med(rs.map((x) => x.cls)), fcp: med(rs.map((x) => x.fcp)), lcp: med(rs.map((x) => x.lcp)), dcl: med(rs.map((x) => x.dcl)), readyMs: med(rs.map((x) => x.readyMs)), longTaskTotal: med(rs.map((x) => x.longTaskTotal)), errors: rs.reduce((s, x) => s + x.errors.length, 0) }
}
writeFileSync(join(OUT, 'measure.json'), JSON.stringify({ method: 'aw2-probe perf section + Chrome trace', cpu: CPU, viewport: '375x667', theme: 'dark', runs: RUNS, roots: ROOTS, summary, rows }, null, 1))
console.table(summary)
