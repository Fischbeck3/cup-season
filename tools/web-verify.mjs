#!/usr/bin/env node
/* Cup Season — the web half's browser walk, with no npm dependency.
 *
 * Drives the cached Chrome-for-Testing headless shell over the DevTools
 * protocol using node's native WebSocket. It exists because CLAUDE.md's
 * "verify before commit" recipe is not optional for the web, and no browser
 * MCP is available in this session.
 *
 *   node web-verify.mjs --url 'http://127.0.0.1:8791/?exit' \
 *        --out /tmp/shots/wave3 --widths 1440,390 [--wait 4000] [--eval 'expr']
 *
 * What it does, in order: launches the shell on a free port, opens the page,
 * UNREGISTERS every service worker and deletes every cache (or you are looking
 * at a stale build — the landmine CLAUDE.md names), reloads, waits, captures a
 * full-page screenshot at each width, and reports every console message and
 * page exception.
 *
 * Exit code 1 if any console error or page exception appears that is not the
 * one known pre-existing boot rejection. Print-only otherwise.
 */
import { spawn } from 'node:child_process'
import { mkdirSync, writeFileSync, existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'

const args = process.argv.slice(2)
const arg = (name, fallback = null) => {
  const i = args.indexOf('--' + name)
  return i >= 0 && i + 1 < args.length ? args[i + 1] : fallback
}

const URL_ = arg('url', 'http://127.0.0.1:8791/?exit')
const OUT = arg('out', '/tmp/cs-web-shots')
const WIDTHS = arg('widths', '1440,390').split(',').map(n => parseInt(n.trim(), 10)).filter(Boolean)
const WAIT = parseInt(arg('wait', '4500'), 10)
const EVAL = arg('eval', null)
const LABEL = arg('label', 'page')

/* The one console line CLAUDE.md says is expected on a cold boot. Anything
   else is a finding. Kept as substrings so a wrapped message still matches. */
const KNOWN_OK = [
  'the one known pre-existing boot rejection',
  'Unchecked runtime.lastError',
  'favicon.ico',
  'Download the React DevTools',
  /* A `--eval` walk clicks with `.click()`, which is not a user gesture, so
     Chrome refuses `navigator.vibrate` and logs it as an error. It is the
     WALK's artefact, not the page's: the same tap by a finger carries a
     gesture and is allowed. Added in wave 8, whose card gate taps a band. */
  "Blocked call to navigator.vibrate",
]

function findShell() {
  const root = join(homedir(), 'Library', 'Caches', 'ms-playwright')
  if (!existsSync(root)) return null
  for (const dir of readdirSync(root)) {
    if (!dir.startsWith('chromium_headless_shell')) continue
    const base = join(root, dir)
    for (const sub of readdirSync(base)) {
      const p = join(base, sub, 'chrome-headless-shell')
      if (existsSync(p)) return p
    }
  }
  for (const dir of readdirSync(root)) {
    if (!dir.startsWith('chromium-')) continue
    const p = join(root, dir, 'chrome-mac-arm64', 'Chromium.app', 'Contents', 'MacOS', 'Chromium')
    if (existsSync(p)) return p
  }
  return null
}

const sleep = ms => new Promise(r => setTimeout(r, ms))

async function main() {
  const bin = findShell()
  if (!bin) { console.error('FAIL: no cached Chromium found under ~/Library/Caches/ms-playwright'); process.exit(2) }
  mkdirSync(OUT, { recursive: true })

  const port = 9200 + Math.floor((Date.now() % 500))
  const proc = spawn(bin, [
    `--remote-debugging-port=${port}`,
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--hide-scrollbars',
    '--force-color-profile=srgb',
    '--user-data-dir=' + join(OUT, '.profile'),
    'about:blank',
  ], { stdio: ['ignore', 'ignore', 'pipe'] })
  let stderr = ''
  proc.stderr.on('data', d => { stderr += d.toString() })

  // wait for the debugger to answer
  let version = null
  for (let i = 0; i < 60; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${port}/json/version`)
      if (r.ok) { version = await r.json(); break }
    } catch { /* not up yet */ }
    await sleep(250)
  }
  if (!version) { proc.kill(); console.error('FAIL: devtools never answered\n' + stderr.slice(0, 800)); process.exit(2) }

  const ws = new WebSocket(version.webSocketDebuggerUrl)
  await new Promise((res, rej) => { ws.onopen = res; ws.onerror = e => rej(new Error('ws: ' + e.message)) })

  let id = 0
  const pending = new Map()
  const events = []
  ws.onmessage = ev => {
    const m = JSON.parse(ev.data)
    if (m.id && pending.has(m.id)) {
      const { resolve, reject } = pending.get(m.id); pending.delete(m.id)
      m.error ? reject(new Error(m.error.message)) : resolve(m.result)
    } else if (m.method) events.push(m)
  }
  const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    const mid = ++id
    pending.set(mid, { resolve, reject })
    ws.send(JSON.stringify({ id: mid, method, params, ...(sessionId ? { sessionId } : {}) }))
    setTimeout(() => { if (pending.has(mid)) { pending.delete(mid); reject(new Error('timeout: ' + method)) } }, 30000)
  })

  const { targetId } = await send('Target.createTarget', { url: 'about:blank' })
  const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true })
  const S = (m, p) => send(m, p, sessionId)

  await S('Page.enable'); await S('Runtime.enable'); await S('Log.enable')
  await S('Network.enable')

  const console_ = []
  ws.addEventListener('message', ev => {
    const m = JSON.parse(ev.data)
    if (m.sessionId !== sessionId) return
    if (m.method === 'Runtime.consoleAPICalled') {
      const text = (m.params.args || []).map(a => a.value ?? a.description ?? a.unserializableValue ?? '').join(' ')
      console_.push({ level: m.params.type, text })
    } else if (m.method === 'Runtime.exceptionThrown') {
      const d = m.params.exceptionDetails
      console_.push({ level: 'exception', text: (d.exception?.description || d.text || 'exception') })
    } else if (m.method === 'Log.entryAdded') {
      console_.push({ level: m.params.entry.level, text: m.params.entry.text })
    }
  })

  // 1 · first load, then kill the service worker and every cache
  await S('Page.navigate', { url: URL_ })
  await sleep(2500)
  await S('Runtime.evaluate', {
    awaitPromise: true,
    expression: `(async () => {
      try { const rs = await navigator.serviceWorker.getRegistrations(); await Promise.all(rs.map(r => r.unregister())) } catch (e) {}
      try { const ks = await caches.keys(); await Promise.all(ks.map(k => caches.delete(k))) } catch (e) {}
      return 'cleared'
    })()`,
  })
  console_.length = 0   // the pre-clear load is not what we are judging

  // 2 · the real walk
  for (const w of WIDTHS) {
    await S('Emulation.setDeviceMetricsOverride', {
      width: w, height: w >= 900 ? 900 : 844, deviceScaleFactor: 2, mobile: w < 900,
    })
    await S('Page.navigate', { url: URL_ })
    await sleep(WAIT)
    if (EVAL) {
      try {
        const r = await S('Runtime.evaluate', { expression: EVAL, awaitPromise: true, returnByValue: true })
        console.log(`eval@${w}:`, JSON.stringify(r.result?.value ?? r.result?.description ?? null))
      } catch (e) { console.log(`eval@${w}: FAILED ${e.message}`) }
    }
    const { data } = await S('Page.captureScreenshot', { format: 'png', captureBeyondViewport: true })
    const file = join(OUT, `${LABEL}-${w}.png`)
    writeFileSync(file, Buffer.from(data, 'base64'))
    console.log(`shot ${file}`)
  }

  const bad = console_.filter(c =>
    (c.level === 'error' || c.level === 'exception') &&
    !KNOWN_OK.some(k => (c.text || '').includes(k)))
  const warn = console_.filter(c => c.level === 'warning')

  console.log(`\nconsole: ${console_.length} message(s) · ${bad.length} error(s) · ${warn.length} warning(s)`)
  for (const c of console_.slice(0, 40)) console.log(`  [${c.level}] ${(c.text || '').slice(0, 300)}`)

  try { ws.close() } catch {}
  proc.kill()

  if (bad.length) { console.log(`\nFAIL — ${bad.length} unexpected console error(s)`); process.exit(1) }
  console.log('\nPASS — console clean but for known lines')
  process.exit(0)
}

main().catch(e => { console.error('FAIL:', e.message); process.exit(2) })
