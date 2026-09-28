/* Cup Season · the ten-capture harness, network half (WX lane, 2026-09-28).
 *
 * Nothing the page asks for leaves this machine except the three public CDN
 * hosts the shipped page itself loads (esm.sh for supabase-js, Google Fonts
 * css + font files), and those are RECORDED once into a local cache and
 * REPLAYED on every later run, so two runs of the same source render the same
 * bytes. Every request to *.supabase.co -- REST, RPC, auth, storage, edge
 * functions, the realtime socket -- is answered here from the synthetic world
 * (tests/fixtures/ten/world.mjs) or ABORTED and written down as a fixture gap.
 * Production Supabase is never contacted: there is no code path below that
 * calls route.continue() or route.fetch() for a supabase.co URL.
 *
 * Test-only. Not served (tests/ is outside stamp-version.sh's allowlist). */
import { createHash } from 'node:crypto'
import { mkdirSync, existsSync, readFileSync, writeFileSync } from 'node:fs'
import { join } from 'node:path'
import { spawn } from 'node:child_process'

export const SUPABASE_HOST = /(^|\.)supabase\.co$/i
export const CDN_HOSTS = new Set(['esm.sh', 'fonts.googleapis.com', 'fonts.gstatic.com'])

const sha = (buf) => createHash('sha256').update(buf).digest('hex')

/* ---------------------------------------------------------------- server */
/* python3 -m http.server, bound to 127.0.0.1 on the lane's own port, serving
   the app root passed on the command line. The PID is returned so the caller
   stops exactly the process it started. */
export async function startStaticServer({ root, port }) {
  const child = spawn('python3', ['-m', 'http.server', String(port), '--bind', '127.0.0.1', '--directory', root],
    { stdio: ['ignore', 'ignore', 'pipe'] })
  let err = ''
  child.stderr.on('data', (d) => { err += d.toString(); if (err.length > 20000) err = err.slice(-20000) })
  const base = `http://127.0.0.1:${port}`
  for (let i = 0; i < 80; i++) {
    if (child.exitCode != null) throw new Error(`http.server exited (${child.exitCode}): ${err.slice(-400)}`)
    try { const r = await fetch(base + '/index.html', { method: 'HEAD' }); if (r.ok) return { base, pid: child.pid, child, stderr: () => err } } catch { /* not up yet */ }
    await new Promise((r) => setTimeout(r, 125))
  }
  child.kill('SIGTERM')
  throw new Error('http.server never answered on ' + base)
}
export function stopStaticServer(srv) {
  if (!srv || !srv.child) return
  try { process.kill(srv.pid, 'SIGTERM') } catch { /* already gone */ }
}

/* ------------------------------------------------------------- CDN cache */
/* Record/replay for the three public hosts. The key is the full URL; the
   entry keeps status, the content-type and the body. A miss in --offline mode
   is a gap, never a live fetch. */
export function cdnCache(dir, { offline = false } = {}) {
  mkdirSync(dir, { recursive: true })
  const stats = { hits: 0, recorded: 0, misses: [] }
  const keyOf = (url) => sha(url).slice(0, 40)
  return {
    stats,
    async handle(route, request) {
      const url = request.url()
      const k = keyOf(url)
      const meta = join(dir, k + '.json'), body = join(dir, k + '.body')
      if (existsSync(meta) && existsSync(body)) {
        const m = JSON.parse(readFileSync(meta, 'utf8'))
        stats.hits++
        return route.fulfill({ status: m.status, headers: m.headers, body: readFileSync(body) })
      }
      if (offline) { stats.misses.push(url); return route.abort('internetdisconnected') }
      const resp = await route.fetch()
      const buf = await resp.body()
      const h = resp.headers()
      const keep = {}
      for (const name of ['content-type', 'access-control-allow-origin', 'cache-control']) if (h[name]) keep[name] = h[name]
      if (!keep['access-control-allow-origin']) keep['access-control-allow-origin'] = '*'
      if (resp.status() === 200) {
        writeFileSync(body, buf)
        writeFileSync(meta, JSON.stringify({ url, status: resp.status(), headers: keep, sha256: sha(buf), recorded_at: new Date().toISOString() }, null, 1))
        stats.recorded++
      }
      return route.fulfill({ status: resp.status(), headers: keep, body: buf })
    },
  }
}

/* ------------------------------------------------------- PostgREST mimic */
/* Enough of PostgREST's query grammar for this client: eq/neq/gt/gte/lt/lte,
   is, in, like/ilike, not.*, or=(...), order, limit, offset. Rows in the world
   are stored in the SHAPE the client selects (embeds pre-joined), so no join
   engine is needed; a filter on an embedded path (league.id) walks the object. */
function parseList(s) {
  // in.(a,b,"c,d")
  const out = []; let cur = '', q = false
  for (const ch of s) {
    if (ch === '"') { q = !q; continue }
    if (ch === ',' && !q) { out.push(cur); cur = ''; continue }
    cur += ch
  }
  if (cur.length) out.push(cur)
  return out
}
const getPath = (row, path) => path.split('.').reduce((o, k) => (o == null ? undefined : o[k]), row)
function cmp(a, b) {
  if (a == null && b == null) return 0
  if (a == null) return 1
  if (b == null) return -1
  if (typeof a === 'number' && typeof b === 'number') return a - b
  const na = Number(a), nb = Number(b)
  if (a !== '' && b !== '' && !isNaN(na) && !isNaN(nb) && typeof a !== 'boolean') return na - nb
  return String(a).localeCompare(String(b))
}
function testOp(val, op, arg) {
  switch (op) {
    case 'eq': return val != null && String(val) === arg
    case 'neq': return val == null || String(val) !== arg
    case 'gt': return val != null && cmp(val, arg) > 0
    case 'gte': return val != null && cmp(val, arg) >= 0
    case 'lt': return val != null && cmp(val, arg) < 0
    case 'lte': return val != null && cmp(val, arg) <= 0
    case 'is': return arg === 'null' ? val == null : arg === 'true' ? val === true : arg === 'false' ? val === false : String(val) === arg
    case 'in': { const set = parseList(arg.replace(/^\(|\)$/g, '')); return val != null && set.includes(String(val)) }
    case 'like': case 'ilike': {
      const re = new RegExp('^' + arg.replace(/[.+?^${}()|[\]\\]/g, '\\$&').replace(/[*%]/g, '.*') + '$', op === 'ilike' ? 'i' : '')
      return val != null && re.test(String(val))
    }
    case 'cs': { try { const want = JSON.parse(arg.replace(/^\{/, '[').replace(/\}$/, ']')); return Array.isArray(val) && want.every((w) => val.map(String).includes(String(w))) } catch { return true } }
    case 'ov': { try { const want = parseList(arg.replace(/^\{|\}$/g, '')); return Array.isArray(val) && want.some((w) => val.map(String).includes(String(w))) } catch { return true } }
    case 'fts': case 'plfts': case 'phfts': case 'wfts': return true
    default: return true
  }
}
function evalCond(row, col, expr) {
  let neg = false
  if (expr.startsWith('not.')) { neg = true; expr = expr.slice(4) }
  const dot = expr.indexOf('.')
  const op = dot < 0 ? expr : expr.slice(0, dot)
  /* URLSearchParams already decoded the value once; a second decode throws on
     a literal `%` (an ilike pattern) -- PostgREST reads it as given */
  const arg = dot < 0 ? '' : expr.slice(dot + 1)
  const r = testOp(getPath(row, col), op, arg)
  return neg ? !r : r
}
function splitTop(s) {
  const out = []; let depth = 0, cur = ''
  for (const ch of s) {
    if (ch === '(') depth++
    if (ch === ')') depth--
    if (ch === ',' && depth === 0) { out.push(cur); cur = ''; continue }
    cur += ch
  }
  if (cur) out.push(cur)
  return out
}
function evalLogic(row, kind, inner) {
  const parts = splitTop(inner)
  const res = parts.map((p) => {
    const m = /^(and|or)\((.*)\)$/.exec(p)
    if (m) return evalLogic(row, m[1], m[2])
    const d = p.indexOf('.')
    return evalCond(row, p.slice(0, d), p.slice(d + 1))
  })
  return kind === 'or' ? res.some(Boolean) : res.every(Boolean)
}
export function applyQuery(rows, params) {
  let out = rows.slice()
  let order = null, limit = null, offset = 0
  for (const [k, v] of params) {
    if (k === 'select' || k === 'columns' || k === 'on_conflict') continue
    if (k === 'order') { order = v; continue }
    if (k === 'limit') { limit = parseInt(v, 10); continue }
    if (k === 'offset') { offset = parseInt(v, 10); continue }
    if (/\.(limit|order|offset)$/.test(k)) continue            // embedded modifiers: ignored
    if (k === 'or' || k === 'and') { const inner = v.replace(/^\(|\)$/g, ''); out = out.filter((r) => evalLogic(r, k, inner)); continue }
    if (/\.(or|and)$/.test(k)) continue
    out = out.filter((r) => evalCond(r, k, v))
  }
  if (order) {
    const keys = order.split(',').map((o) => { const [c, dir, nulls] = o.split('.'); return { c, desc: dir === 'desc', nullsFirst: nulls === 'nullsfirst' } })
    out.sort((a, b) => {
      for (const { c, desc } of keys) { const x = cmp(getPath(a, c), getPath(b, c)); if (x) return desc ? -x : x }
      return 0
    })
  }
  const total = out.length
  if (offset) out = out.slice(offset)
  if (limit != null && !isNaN(limit)) out = out.slice(0, limit)
  return { rows: out, total }
}

/* ---------------------------------------------------------- the responder */
/* One per browser context. `world` answers tables, RPCs, auth, storage and
   functions; anything it does not answer is aborted and recorded in `gaps`.
   `log` receives every Supabase request in order, so a manifest row can say
   exactly which reads fed a capture. */
const WORLD_GAP = Symbol.for('ten-fixture-gap')
export function supabaseResponder({ world, gaps, log, hold, limit = 1500, storm }) {
  const json = (route, status, body, headers = {}) => route.fulfill({
    status, contentType: 'application/json; charset=utf-8',
    headers: { 'access-control-allow-origin': '*', 'access-control-expose-headers': 'content-range, x-total-count', ...headers },
    body: body === undefined ? '' : JSON.stringify(body),
  })
  const pgErr = (route, status, message, code = 'FIXTURE') => json(route, status, { code, message, details: null, hint: null })

  return async function handle(route, request) {
    const url = new URL(request.url())
    const method = request.method()
    const path = url.pathname
    let body = null
    try { body = request.postData() ? JSON.parse(request.postData()) : null } catch { body = request.postData() }
    const entry = { method, path, query: url.search.slice(0, 400), at: Date.now() }
    log.push(entry)
    /* a request storm (a client loop) is a finding, not something to feed:
       past the limit every further request is aborted and the capture is
       marked, so a loop can never run away with the harness */
    if (log.length > limit) { if (storm) storm.hit = true; entry.result = 'storm'; return route.abort('failed') }
    if (method === 'OPTIONS') return route.fulfill({ status: 204, headers: { 'access-control-allow-origin': '*', 'access-control-allow-headers': '*', 'access-control-allow-methods': '*' } })

    const answer = async (res) => {
      if (res === WORLD_GAP) res = GAP
      if (res === undefined || res === GAP) {
        entry.result = 'gap'
        gaps.push({ method, path, query: url.search.slice(0, 400), body: body && typeof body === 'object' ? Object.keys(body) : null })
        return route.abort('failed')
      }
      if (hold && hold.match(entry)) { entry.held = true; await hold.wait() }
      if (res.abort) { entry.result = 'abort:' + res.abort; return route.abort(res.abort) }
      entry.result = String(res.status || 200)
      if (res.raw) return route.fulfill(res.raw)
      return json(route, res.status || 200, res.body, res.headers)
    }

    try {
      /* ---- auth ---- */
      if (path.startsWith('/auth/v1/')) {
        const what = path.slice('/auth/v1/'.length)
        return answer(await world.auth(what, { method, body, url }))
      }
      /* ---- storage ---- */
      if (path.startsWith('/storage/v1/')) {
        return answer(await world.storage(path.slice('/storage/v1/'.length), { method, body, url }))
      }
      /* ---- edge functions ---- */
      if (path.startsWith('/functions/v1/')) {
        return answer(await world.fn(path.slice('/functions/v1/'.length), { method, body, url }))
      }
      /* ---- RPC ---- */
      if (path.startsWith('/rest/v1/rpc/')) {
        const name = path.slice('/rest/v1/rpc/'.length)
        entry.rpc = name
        const args = method === 'GET' ? Object.fromEntries(url.searchParams) : (body || {})
        const r = await world.rpc(name, args, { method, headers: request.headers() })
        if (r === undefined || r === GAP || r === WORLD_GAP) return answer(GAP)
        if (r && r.__error) return answer({ status: r.status || 400, body: { code: r.code || 'P0001', message: r.__error, details: null, hint: null } })
        if (r && r.__abort) return answer({ abort: r.__abort })
        return answer({ status: 200, body: r && r.__value !== undefined ? r.__value : r })
      }
      /* ---- tables ---- */
      if (path.startsWith('/rest/v1/')) {
        const table = path.slice('/rest/v1/'.length)
        entry.table = table
        const params = [...url.searchParams]
        const accept = request.headers()['accept'] || ''
        const prefer = request.headers()['prefer'] || ''
        const single = /vnd\.pgrst\.object/.test(accept)
        if (method === 'GET' || method === 'HEAD') {
          const sel = url.searchParams.get('select') || '*'
          const src = await world.table(table, { params, select: sel, headers: request.headers() })
          if (src === undefined || src === GAP || src === WORLD_GAP) return answer(GAP)
          if (src && src.__error) return answer({ status: src.status || 400, body: { code: src.code || 'FIXTURE', message: src.__error, details: null, hint: null } })
          if (src && src.__abort) return answer({ abort: src.__abort })
          /* filter on the base row merged with its projection (so a filter
             may name an unselected column or an embedded path), then return
             only the projection -- exactly the columns the client asked for */
          const views = src.map((base) => {
            const out = world.project ? world.project(table, base, sel) : base
            const v = { ...base, ...out }
            Object.defineProperty(v, '__out', { value: out, enumerable: false })
            return v
          })
          const q = applyQuery(views, params)
          const rows = q.rows.map((v) => v.__out), total = q.total
          const range = rows.length ? `0-${rows.length - 1}/${/count=/.test(prefer) ? total : '*'}` : `*/${/count=/.test(prefer) ? total : '*'}`
          if (method === 'HEAD') return answer({ raw: { status: 200, headers: { 'content-range': range, 'access-control-allow-origin': '*', 'access-control-expose-headers': 'content-range' }, body: '' } })
          if (single) {
            if (rows.length !== 1) return answer({ status: 406, body: { code: 'PGRST116', message: 'JSON object requested, multiple (or no) rows returned', details: `The result contains ${rows.length} rows`, hint: null } })
            return answer({ status: 200, body: rows[0], headers: { 'content-range': range } })
          }
          return answer({ status: 200, body: rows, headers: { 'content-range': range } })
        }
        /* writes: the world decides (telemetry is absorbed; a capture that
           exercises a failure answers with an error; anything else is a gap) */
        const w = await world.write(table, { method, body, params, prefer })
        if (w === undefined || w === GAP || w === WORLD_GAP) return answer(GAP)
        if (w && w.__error) return answer({ status: w.status || 400, body: { code: w.code || 'FIXTURE', message: w.__error, details: null, hint: null } })
        const rep = /return=representation/.test(prefer)
        return answer({ status: method === 'POST' ? 201 : (rep ? 200 : 204), body: rep ? (single ? (Array.isArray(w) ? w[0] : w) : (Array.isArray(w) ? w : [w])) : undefined })
      }
      return answer(GAP)
    } catch (e) {
      entry.error = String(e && e.message || e)
      gaps.push({ method, path, error: entry.error })
      return route.abort('failed')
    }
  }
}
export const GAP = Symbol('fixture-gap')

/* ------------------------------------------------------ realtime socket */
/* The realtime socket is answered in-process: joins are acknowledged with the
   bindings the client asked for (so the client reports SUBSCRIBED, as it does
   in production), heartbeats are acknowledged, and nothing is ever pushed.
   The server side of `ws.connectToServer()` is never opened. */
export function realtimeMock(ws, log) {
  const reply = (topic, ref, joinRef, payload, arrayForm) => {
    const msg = arrayForm ? [joinRef ?? null, ref ?? null, topic, 'phx_reply', payload]
                          : { topic, event: 'phx_reply', payload, ref, join_ref: joinRef }
    ws.send(JSON.stringify(msg))
  }
  ws.onMessage((raw) => {
    if (typeof raw !== 'string') return
    let m, arrayForm = false
    try { m = JSON.parse(raw) } catch { return }
    if (Array.isArray(m)) { arrayForm = true; m = { join_ref: m[0], ref: m[1], topic: m[2], event: m[3], payload: m[4] } }
    log.push({ ws: m.event, topic: m.topic })
    if (m.event === 'phx_join') {
      const pc = (m.payload && m.payload.config && m.payload.config.postgres_changes) || []
      reply(m.topic, m.ref, m.join_ref, { status: 'ok', response: { postgres_changes: pc.map((b, i) => ({ ...b, id: 1000 + i })) } }, arrayForm)
      if (m.payload && m.payload.config && m.payload.config.presence) {
        const st = arrayForm ? [m.join_ref, null, m.topic, 'presence_state', {}] : { topic: m.topic, event: 'presence_state', payload: {}, ref: null, join_ref: m.join_ref }
        ws.send(JSON.stringify(st))
      }
    } else if (m.event === 'heartbeat' || m.event === 'phx_leave' || m.event === 'access_token' || m.event === 'presence' || m.event === 'broadcast') {
      reply(m.topic, m.ref, m.join_ref, { status: 'ok', response: {} }, arrayForm)
    }
  })
}

export { sha }
