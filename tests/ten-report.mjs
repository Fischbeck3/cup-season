#!/usr/bin/env node
/* Cup Season · summarize a ten-capture manifest (WX lane).
 *
 *   node tests/ten-report.mjs --manifest <dir>/manifest.json [--root <app dir>] [--md out.md] [--json out.json]
 *
 * Prints (and optionally writes) three tables:
 *   1. states: family/state x viewport x theme, route assertion ok/FAILED;
 *   2. console (the I04 table): every distinct `normal` console line and page
 *      exception, normalized (timestamps, UUIDs, counters), with the
 *      index.html line that emitted it and that line's source text, and the
 *      states it appeared in; `injected` lines are listed separately;
 *   3. fixture gaps: every Supabase request the world did not answer. */
import { readFileSync, writeFileSync } from 'node:fs'
import { resolve, dirname, join } from 'node:path'
import { execFileSync } from 'node:child_process'
/* Q12 · a split tree's source is index.html + app/*.js; the manifest's
   indexLine is in the joined numbering (ten-capture maps /app/ frames), so the
   report reads the joined source. Optional: an older checkout has no tool. */
const SPLIT = await import('../tools/split-scripts.mjs').catch(() => null)

const args = process.argv.slice(2)
const arg = (k, d = null) => { const i = args.indexOf('--' + k); return i >= 0 ? args[i + 1] : d }
const manPath = resolve(arg('manifest', 'manifest.json'))
const man = JSON.parse(readFileSync(manPath, 'utf8'))
const root = resolve(arg('root', man.root || '.'))
let src = []
/* the source lines come from the exact commit the run served when it was a
   snapshot (--ref), else from the working tree the run read */
try {
  const gitShow = (f) => execFileSync('git', ['-C', root, 'show', `${man.gitSha}:${f}`], { encoding: 'utf8', maxBuffer: 64 << 20 })
  if (man.ref && man.gitSha) { const html = gitShow('index.html'); src = (SPLIT ? SPLIT.appSourceOf(html, gitShow, { strict: false }) : html).split('\n') }
  else src = (SPLIT ? SPLIT.readAppSource(root, { strict: false }) : readFileSync(join(root, 'index.html'), 'utf8')).split('\n')
} catch { /* no source */ }

const norm = (t) => String(t || '')
  .replace(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d+)?Z/g, '<ts>')
  .replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, '<uuid>')
  .replace(/avery\.fixture@example\.invalid/g, '<fixture-email>')
  .replace(/\s+/g, ' ').trim().slice(0, 260)

const rows = man.rows || []
const lines = []
const out = (s = '') => lines.push(s)

/* 1 · states */
const byState = new Map()
for (const r of rows) {
  const k = `${r.family}/${r.state}`
  if (!byState.has(k)) byState.set(k, [])
  byState.get(k).push(r)
}
out(`# ten-capture report`)
out('')
out(`Manifest: ${manPath}`)
out(`Root: ${man.root} @ ${man.gitSha}${man.indexDirty ? ' (index.html dirty)' : ''} · index.html sha256 ${man.indexSha256Disk}${man.indexSha256DiskAfter && man.indexSha256DiskAfter !== man.indexSha256Disk ? ' → CHANGED during run: ' + man.indexSha256DiskAfter : ''}`)
out(`Harness: ${man.harnessGitSha || '?'} · serve ${man.serve || 'http'} · clock ${man.captureClock} · ${man.counts.captures} captures, ${man.counts.routeFailed} route failures, ${man.counts.errors} errors, ${man.counts.withGaps} with gaps, ${man.counts.withPageErrors} with page errors, ${man.counts.storms || 0} request storms`)
out('')
out('## States')
out('')
out('| family/state | captures | route ok | failed (viewport/theme: reason) | gaps | page errors |')
out('|---|---|---|---|---|---|')
for (const [k, list] of byState) {
  const ok = list.filter((r) => r.file && r.route && r.route.ok)
  const bad = list.filter((r) => !r.file || !r.route || !r.route.ok)
  const gaps = list.reduce((a, r) => a + ((r.fixtureGaps || []).length), 0)
  const pe = list.reduce((a, r) => a + ((r.pageErrors || []).length), 0)
  const why = bad.map((r) => `${r.viewport ? (r.viewport.width + 'x' + r.viewport.height) : '?'}/${r.theme}: ${r.error || (r.route && r.route.detail) || '?'}`)
  const uniq = [...new Set(why.map((w) => w.replace(/^[^:]+: /, '')))]
  out(`| ${k} | ${list.length} | ${ok.length} | ${bad.length ? `${bad.length}: ${uniq.join(' / ').slice(0, 300)}` : ''} | ${gaps} | ${pe} |`)
}
out('')

/* 2 · console */
const table = new Map()
const injected = new Map()
for (const r of rows) {
  for (const m of r.messages || []) {
    if (m.category === 'harness') continue
    const key = `${m.level}|${m.indexLine || m.src || ''}|${norm(m.text)}`
    const bucket = m.category === 'injected' ? injected : table
    if (!bucket.has(key)) bucket.set(key, { level: m.level, text: norm(m.text), indexLine: m.indexLine, frames: m.indexFrames || [], src: m.src, states: new Set(), count: 0 })
    const e = bucket.get(key); e.count++; e.states.add(`${r.family}/${r.state}`)
  }
  for (const e of r.pageErrors || []) {
    const key = `exception||${norm(e.text)}`
    if (!table.has(key)) table.set(key, { level: 'exception', text: norm(e.text), indexLine: null, src: e.stack, states: new Set(), count: 0 })
    const x = table.get(key); x.count++; x.states.add(`${r.family}/${r.state}`)
  }
}
const srcLine = (n) => (n && src[n - 1] ? src[n - 1].trim().slice(0, 160) : '')
out('## Console, normal operation (I04)')
out('')
out('| level | message (normalized) | index.html line (call chain) | source at that line | captures | states |')
out('|---|---|---|---|---|---|')
for (const e of [...table.values()].sort((a, b) => b.count - a.count)) {
  out(`| ${e.level} | ${e.text.replace(/\|/g, '\\|')} | ${e.indexLine || (e.src || '').slice(0, 60)}${e.frames && e.frames.length > 1 ? ' (' + e.frames.join(' ← ') + ')' : ''} | \`${srcLine(e.indexLine).replace(/\|/g, '\\|').replace(/`/g, "'")}\` | ${e.count} | ${[...e.states].slice(0, 8).join(', ')}${e.states.size > 8 ? ` +${e.states.size - 8}` : ''} |`)
}
out('')
out('## Console, deliberately provoked (injected failures)')
out('')
out('| level | message | index.html line | states |')
out('|---|---|---|---|')
for (const e of injected.values()) out(`| ${e.level} | ${e.text.replace(/\|/g, '\\|')} | ${e.indexLine || e.src || ''} | ${[...e.states].join(', ')} |`)
out('')

/* 3 · gaps */
const gaps = new Map()
for (const r of rows) for (const g of r.fixtureGaps || []) {
  const k = `${g.method} ${g.path}`
  if (!gaps.has(k)) gaps.set(k, new Set())
  gaps.get(k).add(`${r.family}/${r.state}`)
}
out('## Fixture gaps (requests the synthetic world did not answer; each was aborted)')
out('')
if (!gaps.size) out('None.')
for (const [k, s] of gaps) out(`- \`${k}\` — ${[...s].join(', ')}`)
out('')
const blocked = new Map()
for (const r of rows) for (const b of r.blockedRequests || []) { const h = (() => { try { return new URL(b).host } catch { return b } })(); blocked.set(h, (blocked.get(h) || 0) + 1) }
out('## Other blocked hosts')
out('')
if (!blocked.size) out('None.')
for (const [h, n] of blocked) out(`- ${h}: ${n}`)

const text = lines.join('\n') + '\n'
if (arg('md')) writeFileSync(resolve(arg('md')), text)
if (arg('json')) writeFileSync(resolve(arg('json')), JSON.stringify({
  states: [...byState].map(([k, l]) => ({ state: k, captures: l.length, ok: l.filter((r) => r.file && r.route && r.route.ok).length })),
  console: [...table.values()].map((e) => ({ ...e, states: [...e.states], source: srcLine(e.indexLine) })),
  injected: [...injected.values()].map((e) => ({ ...e, states: [...e.states] })),
  gaps: [...gaps].map(([k, s]) => ({ request: k, states: [...s] })),
}, null, 1))
process.stdout.write(text)
