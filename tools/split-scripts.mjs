#!/usr/bin/env node
/* ============================================================================
 * split-scripts.mjs — Q12 part 2 ("Split, keep comments", owner, 2026-09-29).
 *
 * Moves index.html's two large script blocks into their own cached files, and
 * gives every static reader (preflight, the pure-function suites, the report)
 * the byte-exact single file back. The plan, the risks and root's apply steps:
 * docs/design/ten-2026-09-27/launch/SPLIT-PLAN.md.
 *
 * WHAT MOVES, WHAT STAYS (index.html has four script blocks; the tool refuses
 * to run on any other shape):
 *   0  the pre-paint theme script (in <head>)     STAYS INLINE — it must run
 *                                                  before first paint
 *   1  the #errbar handlers + SW registration      STAYS INLINE — the reporter
 *                                                  for everything below, and
 *                                                  the update path, never
 *                                                  depend on a file loading
 *   2  the classic UI block (the boot render chain) -> app/classic.js
 *   3  the type="module" backend block              -> app/module.js
 * Each moved block is replaced, IN PLACE, by one tag with no defer/async:
 *   <script src="/app/classic.js?v=__CS_VERSION__"></script>
 *   <script>…the Supabase bridge (R13, see CONSTS)…</script>
 *   <script type="module" src="/app/module.js?v=__CS_VERSION__"></script>
 * The bridge keeps the module's two `const SUPABASE_URL/KEY = '…'` lines in
 * index.html, verbatim, because netlify/edge-functions/share-preview.ts parses
 * them out of the served HTML; app/module.js reads them from window.
 * A classic external script without defer/async is parser-blocking exactly
 * where the inline block stood, and a module script is deferred whether it is
 * inline or external, so document order and the classic-before-module boot are
 * unchanged. The `?v=` placeholder is stamped by stamp-version.sh's existing
 * sed (the same substitution as the version lines, which this tool never
 * edits), so every deploy's HTML names its own scripts and sw.js's cache-first
 * branch can never pair a new shell with an old script.
 *
 * NO JS PARSER. The split is a text operation at the HTML tokenizer's own
 * boundary: an inline script ends at the first `</script`. The tool asserts
 * the file holds exactly four `<script` openings (all real tags) and that no
 * moved block contains `<script`, `</script` or `<!--<script`, so the
 * tokenizer's escape states cannot move that boundary. Comments stay: the
 * bytes between the tags are written unchanged (but for the two bridged lines).
 *
 *   node tools/split-scripts.mjs split [--root .] [--dry]   index.html -> index.html + app/*.js
 *   node tools/split-scripts.mjs wire  [--root .] [--dry]   the plan's §4 edits (stamp, sw, readers), asserted
 *   node tools/split-scripts.mjs join  [--root .] [--out f]  the single file back (stdout or f)
 *   node tools/split-scripts.mjs check [--root .]            round trip + layout invariants + the share-preview guard
 *   node tools/split-scripts.mjs where <line> [--root .]     joined line -> file:line
 *   node tools/split-scripts.mjs joined <file> <line> [--root .]  a split file's line -> the joined line
 *
 * Library use (every static reader, before and after the split):
 *   import { readAppSource } from '../tools/split-scripts.mjs'
 *   const html = readAppSource(root)   // byte-identical to the pre-split index.html
 * ========================================================================== */
import { readFileSync, writeFileSync, existsSync, mkdirSync } from 'node:fs'
import { resolve, dirname } from 'node:path'
import { createHash } from 'node:crypto'
import { fileURLToPath } from 'node:url'

/* The two moved blocks. `open` is the exact inline opening tag the block must
   carry (so join restores it byte for byte); `tag` is the exact external tag
   that replaces it (so join can find it without parsing HTML). */
export const MOVED = [
  { index: 2, file: 'app/classic.js', open: '<script>', tag: '<script src="/app/classic.js?v=__CS_VERSION__"></script>' },
  { index: 3, file: 'app/module.js', open: '<script type="module">', tag: '<script type="module" src="/app/module.js?v=__CS_VERSION__"></script>' },
]
const CLOSE = '</script>'
const EXPECTED_BLOCKS = 4

/* R13 · netlify/edge-functions/share-preview.ts parses the project URL and the
   publishable key out of the ORIGIN HTML (`const SUPABASE_URL = '…'`). The two
   lines lived in the module block, so a plain move would take them out of
   index.html and every share link would fail open to the generic preview. The
   split therefore keeps both lines, verbatim, in a tiny inline classic script
   right before the module tag, which bridges them on window (CLAUDE.md's
   window.* rule); app/module.js reads them from there. join folds them back,
   so every static reader still sees the original module lines. */
export const CONSTS = [
  { name: 'SUPABASE_URL', re: /^const SUPABASE_URL\s*=\s*'[^'\n]+';[^\n]*$/m,
    read: "const SUPABASE_URL  = window.CS_SUPABASE_URL;   /* Q12 · set by index.html's inline bridge, where share-preview.ts reads it */" },
  { name: 'SUPABASE_KEY', re: /^const SUPABASE_KEY\s*=\s*'[^'\n]+';[^\n]*$/m,
    read: "const SUPABASE_KEY  = window.CS_SUPABASE_KEY;" },
]
export const BRIDGE_HEAD = '<script>\n' +
  "/* Q12 · the project URL and publishable key stay in index.html, as the exact\n" +
  "   text netlify/edge-functions/share-preview.ts parses out of the origin HTML.\n" +
  "   app/module.js reads them from window (an explicit bridge). Written by\n" +
  "   tools/split-scripts.mjs; edit the two const lines here, nowhere else. */\n" +
  '(function(){\n'
export const BRIDGE_TAIL = 'window.CS_SUPABASE_URL = SUPABASE_URL;\nwindow.CS_SUPABASE_KEY = SUPABASE_KEY;\n})();\n</script>\n'
const countOf = (text, re) => (text.match(new RegExp(re.source, 'gm')) || []).length

const sha = (s) => createHash('sha256').update(s).digest('hex')
const lineOf = (s, offset) => { let n = 1; for (let i = 0; i < offset; i++) if (s.charCodeAt(i) === 10) n++; return n }

/* Every inline script element, at the tokenizer's boundary. */
export function scriptBlocks(html) {
  const blocks = []
  const re = /<script\b([^>]*)>/gi
  let m
  while ((m = re.exec(html))) {
    const openStart = m.index
    const bodyStart = re.lastIndex
    const closeAt = html.toLowerCase().indexOf('</script', bodyStart)
    if (closeAt < 0) throw new Error(`split-scripts: <script at line ${lineOf(html, openStart)} is never closed`)
    if (html.slice(closeAt, closeAt + CLOSE.length) !== CLOSE) throw new Error(`split-scripts: the close at line ${lineOf(html, closeAt)} is not exactly ${CLOSE}`)
    blocks.push({ openStart, open: m[0], attrs: m[1], bodyStart, bodyEnd: closeAt, end: closeAt + CLOSE.length, line: lineOf(html, openStart) })
    re.lastIndex = closeAt + CLOSE.length
  }
  return blocks
}

/* The shape the split is proven on. Anything else refuses, loudly, with why. */
export function assertSplittable(html) {
  const problems = []
  const openings = (html.match(/<script/gi) || []).length
  const blocks = scriptBlocks(html)
  if (blocks.length !== EXPECTED_BLOCKS) problems.push(`expected ${EXPECTED_BLOCKS} script blocks, found ${blocks.length}`)
  if (openings !== blocks.length) problems.push(`${openings} "<script" substrings but ${blocks.length} script elements — a "<script" inside a block would move the tokenizer's boundary`)
  const headEnd = html.indexOf('</head>')
  if (blocks[0] && !(blocks[0].end < headEnd)) problems.push('block 0 (the pre-paint theme script) is no longer in <head>')
  if (blocks[1] && !/id="errbar"/.test(html.slice(Math.max(0, blocks[1].openStart - 200), blocks[1].openStart))) problems.push('block 1 no longer follows #errbar — the inline reporter moved')
  for (const mv of MOVED) {
    const b = blocks[mv.index]
    if (!b) continue
    if (b.open !== mv.open) problems.push(`block ${mv.index} opens with ${JSON.stringify(b.open)}, expected ${JSON.stringify(mv.open)}`)
    const body = html.slice(b.bodyStart, b.bodyEnd)
    if (/<script|<\/script|<!--\s*<script/i.test(body)) problems.push(`block ${mv.index} contains a script tag sequence`)
    if (body.includes(mv.tag)) problems.push(`block ${mv.index} contains its own external tag text`)
  }
  for (const mv of MOVED) if (html.includes(mv.tag)) problems.push(`index.html already carries ${mv.tag} — already split?`)
  if (problems.length) throw new Error('split-scripts: refusing to split —\n  ' + problems.join('\n  '))
  return blocks
}

/* index.html (inline) -> { html (external), files: { path: body } } */
export function split(html) {
  const blocks = assertSplittable(html)
  const files = {}
  let out = ''
  let at = 0
  for (const mv of MOVED) {
    const b = blocks[mv.index]
    let body = html.slice(b.bodyStart, b.bodyEnd)
    let bridge = ''
    if (mv === MOVED[1]) {
      if (/CS_SUPABASE_(URL|KEY)/.test(html)) throw new Error('split-scripts: index.html already names CS_SUPABASE_* — the bridge would be ambiguous')
      const lines = CONSTS.map((c) => {
        const n = countOf(body, c.re)
        if (n !== 1) throw new Error(`split-scripts: the module must declare ${c.name} exactly once as a quoted const (found ${n}) — share-preview.ts reads that line`)
        return body.match(c.re)[0]
      })
      CONSTS.forEach((c, i) => { body = body.replace(lines[i], () => c.read) })
      bridge = BRIDGE_HEAD + lines[0] + '\n' + lines[1] + '\n' + BRIDGE_TAIL
    }
    files[mv.file] = body
    out += html.slice(at, b.openStart) + bridge + mv.tag
    at = b.end
  }
  out += html.slice(at)
  return { html: out, files }
}

export const isSplit = (html) => MOVED.every((mv) => html.includes(mv.tag))

/* index.html (external) + the files -> the single file, byte for byte. */
export function join(html, readFile) {
  let out = html
  for (const mv of MOVED) {
    const n = out.split(mv.tag).length - 1
    if (n !== 1) throw new Error(`split-scripts: expected exactly one ${mv.tag} in index.html, found ${n}`)
    let body = readFile(mv.file)
    const tagAt = out.indexOf(mv.tag)
    let start = tagAt
    if (mv === MOVED[1]) {
      start = out.lastIndexOf(BRIDGE_HEAD, tagAt)
      const bridge = start < 0 ? '' : out.slice(start, tagAt)
      const inner = bridge.slice(BRIDGE_HEAD.length, bridge.length - BRIDGE_TAIL.length)
      const lines = inner.split('\n')
      if (start < 0 || !bridge.endsWith(BRIDGE_TAIL) || lines.length !== 3 || lines[2] !== '' || !CONSTS.every((c, i) => new RegExp(c.re.source).test(lines[i])))
        throw new Error('split-scripts: the inline Supabase bridge is missing or edited outside its two const lines (it must sit right before the module tag)')
      CONSTS.forEach((c, i) => {
        const k = body.split(c.read).length - 1
        if (k !== 1) throw new Error(`split-scripts: app/module.js must read ${c.name} exactly once, as the tool wrote it (found ${k})`)
        body = body.replace(c.read, () => lines[i])
      })
    }
    out = out.slice(0, start) + mv.open + body + CLOSE + out.slice(tagAt + mv.tag.length)
  }
  return out
}

/* THE reader. Returns what index.html was before the split (or is, unsplit).
   `strict: false` is for the capture harness and its report, which also read
   OLD commits: an unsplit index.html is then returned as it is, whatever its
   block count. A half split, or /app/ tags this tool did not write, still throw. */
export function readAppSource(root = '.', { strict = true } = {}) {
  const html = readFileSync(resolve(root, 'index.html'), 'utf8')
  return appSourceOf(html, (f) => readFileSync(resolve(root, f), 'utf8'), { strict })
}
/* the same, from any byte source (e.g. `git show <sha>:<file>`) */
export function appSourceOf(html, readFile, { strict = true } = {}) {
  if (!isSplit(html)) {
    /* not the exact split layout: it must then be the whole single file, or a
       reader would silently scan an index.html with no script in it */
    if (MOVED.some((mv) => html.includes(mv.tag))) throw new Error('split-scripts: index.html is half split (one external tag without the other)')
    if (/<script\b[^>]*\bsrc=["']?\/?app\//i.test(html)) throw new Error('split-scripts: index.html loads /app/ scripts, but not with the exact tags this tool writes (defer/async/renamed?)')
    if (strict) assertSplittable(html)
    return html
  }
  return join(html, readFile)
}

/* the served paths of the split files */
export const APP_PATHS = MOVED.map((mv) => '/' + mv.file)

/* pathname -> the joined line of that file's line 1 (joined = offset + line - 1),
   or null for an unsplit tree. Computed once per run by ten-capture, which
   maps console frames from /app/<file> into the numbering its report reads. */
export function joinedLineOffsets(root = '.') {
  const html = readFileSync(resolve(root, 'index.html'), 'utf8')
  if (!isSplit(html)) return null
  const whole = readAppSource(root, { strict: false })
  const blocks = scriptBlocks(whole)
  return Object.fromEntries(MOVED.map((mv) => ['/' + mv.file, lineOf(whole, blocks[mv.index].bodyStart)]))
}

/* joined line -> the real file and line (for messages that cite index.html:N) */
export function where(root, joinedLine) {
  const html = readFileSync(resolve(root, 'index.html'), 'utf8')
  if (!isSplit(html)) return { file: 'index.html', line: joinedLine }
  const whole = readAppSource(root)
  const blocks = scriptBlocks(whole)
  for (const mv of MOVED) {
    const b = blocks[mv.index]
    const first = lineOf(whole, b.bodyStart), last = lineOf(whole, b.bodyEnd)
    if (joinedLine >= first && joinedLine <= last) return { file: mv.file, line: joinedLine - first + 1 }
  }
  /* outside the moved blocks: index.html's own line, shifted by the lines the
     moved blocks no longer occupy above it */
  let shift = 0
  for (const mv of MOVED) {
    const b = blocks[mv.index]
    if (lineOf(whole, b.end) < joinedLine) shift += lineOf(whole, b.end) - lineOf(whole, b.openStart)
  }
  /* the bridge's lines sit in index.html just before the module tag */
  if (lineOf(whole, blocks[MOVED[1].index].openStart) <= joinedLine) shift -= (BRIDGE_HEAD + BRIDGE_TAIL).split('\n').length - 1 + 2
  return { file: 'index.html', line: joinedLine - shift }
}

/* app/<file>:<line> -> the joined (pre-split) line: what a console frame from a
   split file cites, in the numbering every pin and report was written against.
   (ten-capture's indexLine only recognises frames from / and /index.html.) */
export function joinedLine(root, file, line) {
  const whole = readAppSource(root)
  const blocks = scriptBlocks(whole)
  const f = String(file).replace(/^\//, '').replace(/\?.*$/, '')
  const mv = MOVED.find((m) => m.file === f)
  if (!mv) return null
  return lineOf(whole, blocks[mv.index].bodyStart) + line - 1
}

/* The invariants the split layout must hold (the plan's guards 1-5). */
/* R13 · the edge function's own regexes, read out of its source, must still
   match the SERVED index.html, and must capture what the app itself uses. */
export function sharePreviewProblems(root, html, whole) {
  const f = resolve(root, 'netlify', 'edge-functions', 'share-preview.ts')
  if (!existsSync(f)) return []
  const src = readFileSync(f, 'utf8')
  const found = new Map([...src.matchAll(/html\.match\(\/(const (SUPABASE_URL|SUPABASE_KEY)[^\n]*?)\/\)/g)].map((m) => [m[2], m[1]]))
  const problems = []
  for (const name of ['SUPABASE_URL', 'SUPABASE_KEY']) {
    if (!found.has(name)) { problems.push(`share-preview.ts no longer parses ${name} with html.match(/…/) — this guard went blind; re-read R13`); continue }
    const re = new RegExp(found.get(name))
    const served = re.exec(html)
    if (!served) { problems.push(`share-preview.ts's ${name} regex no longer matches index.html — every share link would fall back to the generic preview (R13)`); continue }
    const used = whole ? re.exec(whole) : served
    if (!used || used[1] !== served[1]) problems.push(`index.html's ${name} is not the value the app uses — share previews would query a different project/key (R13)`)
  }
  return problems
}

export function check(root = '.') {
  const problems = []
  const html = readFileSync(resolve(root, 'index.html'), 'utf8')
  if (!isSplit(html)) {
    try { readAppSource(root) } catch (e) { return { split: false, problems: [e.message, ...sharePreviewProblems(root, html, null)] } }
    return { split: false, problems: sharePreviewProblems(root, html, null) }
  }
  let whole
  try { whole = readAppSource(root) } catch (e) { return { split: true, problems: [...sharePreviewProblems(root, html, null), e.message] } }
  problems.push(...sharePreviewProblems(root, html, whole))
  /* 1 · the round trip is exact: splitting the joined file reproduces the tree */
  try {
    const again = split(whole)
    if (again.html !== html) problems.push('split(join(tree)) does not reproduce index.html byte for byte')
    for (const mv of MOVED) if (again.files[mv.file] !== readFileSync(resolve(root, mv.file), 'utf8')) problems.push(`split(join(tree)) does not reproduce ${mv.file}`)
  } catch (e) { problems.push(e.message) }
  /* 2 · no defer/async crept onto a moved tag, and the order is classic then module */
  const iClassic = html.indexOf(MOVED[0].tag), iModule = html.indexOf(MOVED[1].tag)
  if (!(iClassic >= 0 && iModule > iClassic)) problems.push('the classic tag must precede the module tag')
  if (/<script[^>]*\b(defer|async)\b/i.test(html)) problems.push('a script tag carries defer/async — boot order is no longer the proven one')
  /* 3 · the stamp follows every placeholder: stamp-version.sh copies and stamps each moved file */
  const stamp = existsSync(resolve(root, 'stamp-version.sh')) ? readFileSync(resolve(root, 'stamp-version.sh'), 'utf8') : ''
  const copiesDir = /^cp -r app "\$DIST\/app"$/m.test(stamp)
  for (const mv of MOVED) {
    if (!copiesDir && !new RegExp('^cp [^\\n]*\\b' + mv.file.replace(/[./]/g, '\\$&') + '\\b', 'm').test(stamp)) problems.push(`stamp-version.sh does not copy ${mv.file} into dist/ (it would 404)`)
  }
  /* the sed loop itself (`for file in ...; do`), not any line that merely names the file */
  const loop = (stamp.match(/^for file in ([^\n]*); do$/m) || [])[1] || ''
  if (!loop.includes('"$DIST/index.html"')) problems.push('stamp-version.sh: the sed loop no longer stamps $DIST/index.html (the ?v= query would ship unstamped)')
  for (const mv of MOVED) {
    const body = readFileSync(resolve(root, mv.file), 'utf8')
    if (body.includes('__CS_VERSION__') && !loop.includes('"$DIST/' + mv.file + '"')) problems.push(`${mv.file} carries __CS_VERSION__ but stamp-version.sh's sed loop does not stamp $DIST/${mv.file}`)
  }
  /* 4 · the service worker precaches each moved file under the stamped query */
  const sw = existsSync(resolve(root, 'sw.js')) ? readFileSync(resolve(root, 'sw.js'), 'utf8') : ''
  for (const mv of MOVED) if (!sw.includes(`'/${mv.file}?v=' + VERSION`) && !sw.includes('`/' + mv.file + '?v=${VERSION}`')) problems.push(`sw.js SHELL does not precache /${mv.file}?v=VERSION (offline boot would break)`)
  /* 5 · the joined file is the one the readers were written against */
  if ((whole.match(/<script/gi) || []).length !== EXPECTED_BLOCKS) problems.push('the joined file does not hold four script blocks')
  return { split: true, problems, sha256: sha(whole) }
}

/* ------------------------------------------------ WIRE (the §4 edits, asserted) */
/* The small edits the split layout needs outside index.html, as exact anchors.
   Each anchor must be found (a moved anchor refuses, naming the file) and each
   reader gets its import right after its FIRST import line: ESM imports hoist,
   and build-markers.mjs emits an `import SwiftUI` inside a template string, so
   "after the last import line" would land inside the generated Swift. */
const READ_STD = ["readFileSync(join(root, 'index.html'), 'utf8')", 'readAppSource(root)']
const IMP_TESTS = "import { readAppSource } from '../tools/split-scripts.mjs';"
const IMP_TOOLS = "import { readAppSource } from './split-scripts.mjs';"
export const WIRE = [
  { file: 'stamp-version.sh', edits: [
    ['cp -r brand "$DIST/brand"\n', 'cp -r brand "$DIST/brand"\n# Q12 · the app\'s two scripts, split out of index.html by tools/split-scripts.mjs\n# (index.html names them /app/<file>?v=<sha>; the sed below stamps that query).\ncp -r app "$DIST/app"\n'],
    ['for file in "$DIST/index.html" "$DIST/sw.js"; do', 'for file in "$DIST/index.html" "$DIST/sw.js" "$DIST/app/classic.js" "$DIST/app/module.js"; do'],
    ['if grep -q "__CS_VERSION__" "$DIST/index.html" "$DIST/sw.js"; then', 'if grep -q "__CS_VERSION__" "$DIST/index.html" "$DIST/sw.js" "$DIST/app/classic.js" "$DIST/app/module.js"; then'],
    ['for f in index.html sw.js manifest.webmanifest; do', 'for f in index.html sw.js manifest.webmanifest app/classic.js app/module.js; do'],
  ] },
  { file: 'sw.js', edits: [
    ["const SHELL = [\n  '/',\n", "const SHELL = [\n  '/',\n  '/app/classic.js?v=' + VERSION,   // Q12 · the split scripts, under the query index.html names them by\n  '/app/module.js?v=' + VERSION,\n"],
  ] },
  { file: 'tests/preflight.mjs', imports: [IMP_TESTS, "import { check as splitCheck } from '../tools/split-scripts.mjs';"], edits: [
    READ_STD,
    ["    ['web', join(root, 'index.html')],\n", "    ['web', join(root, 'index.html')],\n    ['web', join(root, 'app', 'classic.js')],\n    ['web', join(root, 'app', 'module.js')],\n"],
    ["  const files = [join(root, 'index.html')];", "  const files = [join(root, 'index.html'), join(root, 'app', 'classic.js'), join(root, 'app', 'module.js')].filter(f => existsSync(f));"],
    ["    .matchAll(/'([^']+)'/g)].map(m => m[1]).filter(p => p !== '/');\n", "    .matchAll(/'([^']+)'/g)].map(m => m[1]).filter(p => p !== '/').map(p => p.replace(/\\?v=$/, ''));\n  /* Q12 · a `cp -r <dir>` ships everything under it (brand/, app/) */\n  const cpDirs = [...stamp.matchAll(/^cp -r (\\S+) /gm)].map(m => m[1] + '/');\n"],
    ["  const missing = shell.filter(p => !cpLine.includes(p.replace(/^\\//, '')));", "  const missing = shell.filter(p => { const f = p.replace(/^\\//, ''); return !cpLine.includes(f) && !cpDirs.some(d => f.startsWith(d)); });"],
    ['/* 2 · every client RPC has an execute grant in a migration ----------------- */', "/* 1b · Q12 · the split layout holds (tools/split-scripts.mjs check) --------- */\n{\n  const r = splitCheck(root);\n  !r.split && !r.problems.length ? pass('split layout', 'index.html is one file')\n    : r.problems.length === 0 ? pass('split layout', 'app/classic.js + app/module.js join back byte for byte · stamped · precached · no defer/async')\n    : fail('split layout', r.problems.join(' · '));\n}\n\n/* 2 · every client RPC has an execute grant in a migration ----------------- */"],
  ] },
  /* tests/ten-report.mjs and tests/ten-capture.mjs read the split directly (loose, for old commits too) */
  ...['attribution-trace.test.mjs', 'homefold.test.mjs', 'post-request.test.mjs', 'rating.test.mjs', 'sunningdale.test.mjs', 'trophycase.test.mjs']
    .map((f) => ({ file: 'tests/' + f, imports: [IMP_TESTS], edits: [READ_STD] })),
  { file: 'tests/season-book.test.mjs', imports: [IMP_TESTS], edits: [["readFileSync(new URL('../index.html',import.meta.url),'utf8')", "readAppSource(new URL('..',import.meta.url).pathname)"]] },
  { file: 'tests/share-consent-flow.test.mjs', imports: [IMP_TESTS], edits: [["readFileSync(new URL('../index.html', import.meta.url), 'utf8')", "readAppSource(new URL('..', import.meta.url).pathname)"]] },
  { file: 'tests/ten-lock-probe.mjs', imports: [IMP_TESTS], edits: [["readFileSync(join(ROOT, 'index.html'), 'utf8')", 'readAppSource(ROOT)']] },
  { file: 'tools/build-markers.mjs', imports: [IMP_TOOLS], edits: [READ_STD] },
  { file: 'tools/extract-strings.mjs', imports: [IMP_TOOLS], edits: [READ_STD] },
  { file: 'tools/deploy-status.mjs', edits: [["'index.html', 'sw.js', 'manifest.webmanifest'", "'index.html', 'app', 'sw.js', 'manifest.webmanifest'"]] },
  /* true only after the split, so it rides the apply */
  { file: 'package.json', edits: [['The client ships as a single static index.html \u2014 nothing here is served', 'The client ships as a static index.html plus app/classic.js and app/module.js (tools/split-scripts.mjs) \u2014 nothing here is served']] },
]
export function wire(root, { dry = false } = {}) {
  const planned = [], problems = []
  for (const w of WIRE) {
    const p = resolve(root, w.file)
    if (!existsSync(p)) { problems.push(`${w.file}: missing`); continue }
    let s = readFileSync(p, 'utf8')
    if (s.includes('split-scripts.mjs') || s.includes('/app/classic.js') || s.includes('"$DIST/app"')) { problems.push(`${w.file}: already wired`); continue }
    for (const [a, b] of w.edits) {
      const n = s.split(a).length - 1
      if (n < 1) { problems.push(`${w.file}: anchor not found: ${JSON.stringify(a.slice(0, 70))}`); continue }
      s = s.split(a).join(b)
    }
    for (const imp of (w.imports || [])) {
      const lines = s.split('\n'); const first = lines.findIndex((l) => l.startsWith('import '))
      if (first < 0) { problems.push(`${w.file}: no import line to follow`); continue }
      lines.splice(first + 1, 0, imp); s = lines.join('\n')
    }
    planned.push([p, s, w.file])
  }
  if (problems.length) throw new Error('split-scripts: refusing to wire (nothing written) —\n  ' + problems.join('\n  '))
  if (!dry) for (const [p, s] of planned) writeFileSync(p, s)
  return planned.map(([, , f]) => f)
}

/* ---------------------------------------------------------------- CLI */
const isMain = process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)
if (isMain) {
  process.on('uncaughtException', (e) => { console.error(String(e && e.message || e)); process.exit(1) })
  const args = process.argv.slice(2)
  const cmd = args[0]
  const opt = (k, d = null) => { const i = args.indexOf('--' + k); return i >= 0 && i + 1 < args.length ? args[i + 1] : d }
  const root = resolve(opt('root', '.'))
  if (cmd === 'split') {
    const html = readFileSync(resolve(root, 'index.html'), 'utf8')
    const before = sha(html)
    const { html: out, files } = split(html)
    const back = join(out, (f) => files[f])
    if (back !== html) { console.error('split-scripts: the round trip is not exact — nothing written'); process.exit(1) }
    const sizes = Object.entries(files).map(([f, b]) => `${f} ${Buffer.byteLength(b)} B`).join(' · ')
    if (args.includes('--dry')) { console.log(`[split] dry run · index.html ${Buffer.byteLength(html)} -> ${Buffer.byteLength(out)} B · ${sizes} · round trip exact (sha256 ${before.slice(0, 12)})`); process.exit(0) }
    for (const [f, b] of Object.entries(files)) { mkdirSync(dirname(resolve(root, f)), { recursive: true }); writeFileSync(resolve(root, f), b) }
    writeFileSync(resolve(root, 'index.html'), out)
    const reread = readAppSource(root)
    if (sha(reread) !== before) { console.error('split-scripts: the files on disk do not join back to the original — restore index.html from git'); process.exit(1) }
    console.log(`[split] index.html ${Buffer.byteLength(html)} -> ${Buffer.byteLength(out)} B · ${sizes}`)
    console.log(`[split] round trip exact on disk · joined sha256 ${before}`)
  } else if (cmd === 'wire') {
    const files = wire(root, { dry: args.includes('--dry') })
    console.log(`[wire] ${args.includes('--dry') ? 'would edit' : 'edited'} ${files.length} file(s): ${files.join(', ')}`)
  } else if (cmd === 'join') {
    const whole = readAppSource(root)
    const out = opt('out')
    if (out) writeFileSync(resolve(out), whole); else process.stdout.write(whole)
  } else if (cmd === 'check') {
    const r = check(root)
    if (!r.split && r.problems.length) { console.log('[split] FAIL\n  ' + r.problems.join('\n  ')); process.exit(1) }
    if (!r.split) { console.log('[split] index.html is the single file (four inline blocks) · nothing else to check'); process.exit(0) }
    if (r.problems.length) { console.log('[split] FAIL\n  ' + r.problems.join('\n  ')); process.exit(1) }
    console.log(`[split] ok · round trip exact · joined sha256 ${r.sha256}`)
  } else if (cmd === 'joined') {
    console.log(joinedLine(root, args[1], parseInt(args[2], 10)))
  } else if (cmd === 'where') {
    const n = parseInt(args[1], 10)
    const w = where(root, n)
    console.log(`${w.file}:${w.line}`)
  } else {
    console.log('usage: node tools/split-scripts.mjs split|wire|join|check|where <line>|joined <file> <line> [--root .] [--dry] [--out file]')
    process.exit(cmd ? 1 : 0)
  }
}
