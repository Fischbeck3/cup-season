/* TEN / W6 · AW2-06 + OB-05 · UI_SYSTEM §1.4: Plex Mono is never a label, a
 * button or a sentence — it keeps columns of figures, codes, handles and
 * times. `notMono(selectors, need)` is a ten-capture check: it fails the
 * capture when any VISIBLE element a selector names is set in mono. The
 * selectors are the audit's own sites (AUDIT.md AW2-06, DETECTOR.md OB-05)
 * and the labels beside them in the same component. `need` names the ones
 * the state must actually draw, so the check never passes by finding
 * nothing; a need written `{ sel, below: 960 }` applies only under that width
 * (the phone's tab bar is not drawn on the desk). */
export const notMono = (sels, need = []) => async (page) => page.evaluate(([sels, need]) => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
  const mono = (el) => /plex mono|monospace|menlo/i.test(getComputedStyle(el).fontFamily.split(',')[0])
  const missing = need.map((n) => (typeof n === 'string' ? { sel: n } : n))
    .filter((n) => !(n.below && innerWidth >= n.below))
    .filter((n) => ![...document.querySelectorAll(n.sel)].some(shown)).map((n) => n.sel)
  if (missing.length) return 'the state does not draw ' + missing.join(', ')
  const bad = []
  for (const sel of sels.map((n) => (typeof n === 'string' ? n : n.sel))) for (const el of document.querySelectorAll(sel)) {
    if (shown(el) && mono(el)) bad.push(`${sel} ${JSON.stringify((el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 40))}`)
  }
  return bad.length ? 'set in mono (§1.4): ' + [...new Set(bad)].slice(0, 6).join('; ') : true
}, [sels, need])

/* TEN / W6 · AW2-07 · UI_SYSTEM §1.4 and §1.6: a number is never the serif. A
 * figure in a serif sentence is a run the producer marked (csFigRun, `.cfrun`),
 * set in the board face. `noSerifFigure(selectors, need)` fails the capture
 * when a digit under a selector renders in the serif; `need` works as in
 * `notMono`. */
export const noSerifFigure = (sels, need = []) => async (page) => page.evaluate(([sels, need]) => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
  const serif = (el) => /^\s*("?ui-serif|"?new york|"?iowan|georgia|serif)\b/i.test(getComputedStyle(el).fontFamily.split(',')[0])
  const missing = need.map((n) => (typeof n === 'string' ? { sel: n } : n))
    .filter((n) => !(n.below && innerWidth >= n.below))
    .filter((n) => ![...document.querySelectorAll(n.sel)].some(shown)).map((n) => n.sel)
  if (missing.length) return 'the state does not draw ' + missing.join(', ')
  const bad = []
  for (const sel of sels.map((n) => (typeof n === 'string' ? n : n.sel))) for (const root of document.querySelectorAll(sel)) {
    if (!shown(root)) continue
    const w = document.createTreeWalker(root, NodeFilter.SHOW_TEXT)
    for (let t = w.nextNode(); t; t = w.nextNode()) {
      if (/\d/.test(t.textContent) && t.parentElement && serif(t.parentElement)) bad.push(`${sel} ${JSON.stringify(t.textContent.trim().slice(0, 40))}`)
    }
  }
  return bad.length ? 'a number set in the serif (§1.4): ' + [...new Set(bad)].slice(0, 6).join('; ') : true
}, [sels, need])

/* TEN / W6 · AW2-15 · UI_SYSTEM §1.3: a phrase a person could read aloud is
 * set in sentence case, never tracked caps. `readsAsWritten(pairs)` checks
 * the RENDERED text (innerText carries text-transform), case-sensitively —
 * the harness's own `text:` expectation ignores case, so it cannot see caps.
 * Each pair is [selector, exact text] or [selector, /regex/ source]; the
 * first visible match must read as written, and a missing one fails. */
export const readsAsWritten = (pairs) => async (page) => page.evaluate((pairs) => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
  const bad = []
  for (const [sel, want, isRe] of pairs) {
    const el = [...document.querySelectorAll(sel)].find(shown)
    if (!el) { bad.push(`the state does not draw ${sel}`); continue }
    const got = (el.innerText || '').replace(/\s+/g, ' ').trim()
    const ok = isRe ? new RegExp(want).test(got) : got === want
    if (!ok) bad.push(`${sel} reads ${JSON.stringify(got.slice(0, 60))}`)
  }
  return bad.length ? 'a phrase is not in sentence case (§1.3): ' + bad.join('; ') : true
}, pairs)

/* TEN / W6 · AW2-08 · UI_SYSTEM §5.2: the retired glyphs — typed arrows (a
 * link's arrow is absorbed into its underline; a span is an en dash) and the
 * dingbats (⚑ ✦ ◆ ◇ ✕ ✓ ★ ⇄ ⊕ ✉ ☀). `noRetiredGlyph()` fails the capture
 * when any VISIBLE text on the page carries one. A golfer's own typed text
 * (a chat's body, `.mtxt`) may, so it is not read. */
export const noRetiredGlyph = () => async (page) => page.evaluate(() => {
  const RE = /[→←↗↑↓⇄⚑✦◆◇✕✓★⊕✉☀]/
  const bad = []
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
  for (let t = w.nextNode(); t; t = w.nextNode()) {
    if (!RE.test(t.textContent)) continue
    const el = t.parentElement
    if (!el || el.closest('.mtxt, script, style, [aria-hidden="true"] svg')) continue
    const r = el.getBoundingClientRect(), cs = getComputedStyle(el)
    if (!(r.width > 0 && r.height > 0) || cs.visibility === 'hidden') continue
    bad.push(JSON.stringify(t.textContent.replace(/\s+/g, ' ').trim().slice(0, 40)))
  }
  return bad.length ? 'a retired glyph is on the page (§5.2): ' + [...new Set(bad)].slice(0, 6).join('; ') : true
})

/* TEN / W6 · AW2-13 · the retired shapes (UI_SYSTEM §3, §8): no pill ("there
 * is no pill" — a radius is one of the five, and `p` is 3px), no spine (a
 * card's coloured left edge), and no glass (the header and the tab bar sit on
 * the page's own ground, opaque, with no backdrop blur). `noRetiredShape()`
 * reads every VISIBLE element: a pill is 8–48px tall (a 44px chip counts), wider
 * than tall, and
 * rounded to half its height; a spine is a left border wider than the other
 * three; glass is a translucent or blurred .hdr or .tabbar. */
export const noRetiredShape = () => async (page) => page.evaluate(() => {
  const bad = []
  /* rgb(), rgba() and color(srgb … / a), which color-mix() computes to */
  const alpha = (c) => { c = c || ''; const sl = /\/\s*([0-9.]+)\s*\)\s*$/.exec(c); if (sl) return parseFloat(sl[1]); const m = /rgba?\(([^)]+)\)/.exec(c); if (!m) return /^color\(/.test(c) ? 1 : 0; const v = m[1].split(','); return v[3] !== undefined ? parseFloat(v[3]) : 1 }
  for (const el of document.querySelectorAll('body *')) {
    const r = el.getBoundingClientRect()
    if (!(r.width > 0 && r.height > 0)) continue
    const cs = getComputedStyle(el)
    if (cs.visibility === 'hidden' || cs.display === 'none') continue
    const rad = parseFloat(cs.borderTopLeftRadius) || 0
    if (r.height >= 8 && r.height <= 48 && r.width > r.height * 1.2 && rad >= r.height / 2 - 0.5) {
      bad.push(`a pill: ${el.tagName.toLowerCase()}${el.id ? '#' + el.id : ''}.${[...el.classList].slice(0, 2).join('.')} (${Math.round(r.width)}×${Math.round(r.height)}, r${Math.round(rad)})`)
    }
    /* a spine is a coloured left edge ON A CARD: a boxed or filled element. A
       transparent edge is no mark, and a bare row's left rule (the desk nav's
       selection mark) is not a card's spine */
    const bl = parseFloat(cs.borderLeftWidth) || 0, bt = parseFloat(cs.borderTopWidth) || 0
    const boxed = bt > 0 || alpha(cs.backgroundColor) > 0
    if (bl >= 2 && bl > bt && cs.borderLeftStyle !== 'none' && alpha(cs.borderLeftColor) > 0 && boxed && r.height > 16) bad.push(`a spine: ${el.tagName.toLowerCase()}.${[...el.classList].slice(0, 2).join('.')} (${bl}px)`)
  }
  for (const sel of ['.hdr', '.tabbar']) {
    const el = document.querySelector(sel); if (!el) continue
    const r = el.getBoundingClientRect(); if (!(r.width > 0 && r.height > 0)) continue
    const cs = getComputedStyle(el), a = alpha(cs.backgroundColor)
    const blur = (cs.backdropFilter && cs.backdropFilter !== 'none') || (cs.webkitBackdropFilter && cs.webkitBackdropFilter !== 'none')
    /* glass is a bar that floats over the page: blurred, or see-through while
       it is stuck (the desk's static header on the page's own ground is not) */
    const floats = cs.position === 'sticky' || cs.position === 'fixed'
    if (blur || (floats && a < 1)) bad.push(`glass: ${sel} (alpha ${a}${blur ? ', blurred' : ''})`)
  }
  return bad.length ? 'a retired shape (§3, §8): ' + [...new Set(bad)].slice(0, 6).join('; ') : true
})

/* TEN / W6 · AW2-04 · L-34 and §16A.4: one fact, one encoding, per viewport.
 * `onceInView(facts, from)` counts each fact in the VISIBLE text that stands
 * in the viewport and fails the capture when one is printed twice. A fact is
 * [name, regex source, need]: with `need` a fact the state must show, without
 * it a fact that may be out of view but is never in view twice. `from` is the
 * width the check starts at (the desk's second column stands beside the
 * reading column only from 960). */
export const onceInView = (facts, from = 0) => async (page) => page.evaluate(([facts, from]) => {
  if (innerWidth < from) return true
  const inView = (r) => r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight && r.right > 0 && r.left < innerWidth
  const texts = []
  const w = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT)
  for (let t = w.nextNode(); t; t = w.nextNode()) {
    const el = t.parentElement
    if (!el || !t.textContent.trim() || el.closest('script, style, [aria-hidden="true"]')) continue
    const cs = getComputedStyle(el)
    if (cs.visibility === 'hidden' || Number(cs.opacity) === 0) continue
    const range = document.createRange(); range.selectNodeContents(t)
    if ([...range.getClientRects()].some(inView)) texts.push(t.textContent)
  }
  const all = texts.join('\n')
  const bad = []
  for (const [name, src, need] of facts) {
    const n = (all.match(new RegExp(src, 'g')) || []).length
    if (n > 1) bad.push(`${name} is printed ${n} times`)
    else if (n === 0 && need) bad.push(`${name} is not in view`)
  }
  return bad.length ? 'one fact, one place per viewport (L-34, §16A.4): ' + bad.join('; ') : true
}, [facts, from])

/* TEN / W6 · DX2 OB2-03 · UI_SYSTEM §7.1 "Destructive, armed": a `bg2` fill
 * and a `neg` label (the phone's CSDestructiveStyle), and the label reads at
 * AA on its fill. `armedDelete(sel)` fails the capture otherwise. The tokens
 * are read beside the control, so a room's own ground re-declaration counts. */
export const armedDelete = (sel) => async (page) => page.evaluate((sel) => {
  const b = [...document.querySelectorAll(sel)].find((el) => { const r = el.getBoundingClientRect(); return r.width > 0 && r.height > 0 })
  if (!b) return `the state does not draw ${sel}`
  const tok = (n) => { const i = document.createElement('i'); i.style.color = `var(${n})`; b.parentElement.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
  const cs = getComputedStyle(b)
  if (cs.backgroundColor !== tok('--bg2')) return `${sel}'s fill is ${cs.backgroundColor}, not bg2 (${tok('--bg2')}) — §7.1`
  if (cs.color !== tok('--neg')) return `${sel}'s label is ${cs.color}, not neg (${tok('--neg')}) — §7.1`
  const lum = (c) => { const [r, g, bl] = (c.match(/[\d.]+/g) || []).slice(0, 3).map(Number).map((v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }); return 0.2126 * r + 0.7152 * g + 0.0722 * bl }
  const a = lum(cs.color), z = lum(cs.backgroundColor), ratio = (Math.max(a, z) + 0.05) / (Math.min(a, z) + 0.05)
  return ratio >= 4.5 ? true : `${sel}'s label is ${ratio.toFixed(2)}:1 on its fill`
}, sel)

/* TEN / W6 · DX2 OB2-02 · UI_SYSTEM §1.3 produces capitals ONE way: the
 * role's transform. `capsFromRole(sels, need)` fails the capture when a
 * visible element's own text is TYPED in capitals (a word of three or more
 * letters, every one a capital; HCP and its kind are not words), or when the
 * element does not take its caps from its role (`text-transform:uppercase`).
 * The rendered line is the same either way. What changes is the string a
 * screen reader is handed and a caps rule can judge. `need` works as in
 * `notMono`. */
export const capsFromRole = (sels, need = []) => async (page) => page.evaluate(([sels, need]) => {
  const shown = (el) => { const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
  const missing = need.map((n) => (typeof n === 'string' ? { sel: n } : n))
    .filter((n) => !(n.below && innerWidth >= n.below))
    .filter((n) => ![...document.querySelectorAll(n.sel)].some(shown)).map((n) => n.sel)
  if (missing.length) return 'the state does not draw ' + missing.join(', ')
  const ACRO = new Set(['HCP', 'GHIN', 'PGA', 'USGA', 'WHS'])
  const bad = []
  for (const sel of sels.map((n) => (typeof n === 'string' ? n : n.sel))) for (const el of document.querySelectorAll(sel)) {
    if (!shown(el)) continue
    const typed = ((el.textContent || '').match(/\b[A-Z]{3,}\b/g) || []).filter((w) => !ACRO.has(w))
    if (typed.length) bad.push(`${sel} types ${JSON.stringify(typed.slice(0, 5).join(' '))}`)
    else if (getComputedStyle(el).textTransform !== 'uppercase') bad.push(`${sel} does not take its caps from its role`)
  }
  return bad.length ? 'capitals typed into the string, not set by the role (§1.3): ' + [...new Set(bad)].slice(0, 6).join('; ') : true
}, [sels, need])

/* TEN / W6 · E's twin (N4-087) · UI_SYSTEM §10.3: copy over a photograph is
 * measured on the photograph. `bandContrast(card, parts)` scrolls the first
 * visible `card` into view, paints each part's own text transparent (and any
 * ring drawn in it), and screenshots the card. What is left under each line
 * is exactly its ground: photo, scrim, panel. It then measures each line's
 * colour against the WORST pixel of that ground inside the line's own box
 * (the brightest for light type, the darkest for dark). A part fails under
 * 4.5:1, or 3:1 when `large` (a figure at 18.66px bold or more). The scroll
 * is put back, so the capture frames as it did. Every part's number goes to
 * the log (`[bandContrast]`). The PNG is decoded with node:zlib; no
 * dependency. */
import { inflateSync } from 'node:zlib'
function decodePNG(buf) {
  let off = 8, w = 0, h = 0, ct = 0, bd = 0, il = 0; const idat = []
  while (off < buf.length) {
    const len = buf.readUInt32BE(off), type = buf.toString('ascii', off + 4, off + 8), data = buf.subarray(off + 8, off + 8 + len)
    if (type === 'IHDR') { w = data.readUInt32BE(0); h = data.readUInt32BE(4); bd = data[8]; ct = data[9]; il = data[12] }
    else if (type === 'IDAT') idat.push(data)
    else if (type === 'IEND') break
    off += 12 + len
  }
  if (bd !== 8 || (ct !== 6 && ct !== 2) || il) throw new Error(`png: depth ${bd}, colour type ${ct}, interlace ${il}`)
  const bpp = ct === 6 ? 4 : 3, stride = w * bpp, raw = inflateSync(Buffer.concat(idat)), px = Buffer.alloc(h * stride)
  for (let y = 0; y < h; y++) {
    const f = raw[y * (stride + 1)], line = raw.subarray(y * (stride + 1) + 1, (y + 1) * (stride + 1))
    const out = px.subarray(y * stride, (y + 1) * stride), prev = y ? px.subarray((y - 1) * stride, y * stride) : null
    for (let i = 0; i < stride; i++) {
      const a = i >= bpp ? out[i - bpp] : 0, b = prev ? prev[i] : 0, c = prev && i >= bpp ? prev[i - bpp] : 0
      let v = line[i]
      if (f === 1) v += a; else if (f === 2) v += b; else if (f === 3) v += (a + b) >> 1
      else if (f === 4) { const p = a + b - c, pa = Math.abs(p - a), pb = Math.abs(p - b), pc = Math.abs(p - c); v += (pa <= pb && pa <= pc) ? a : (pb <= pc ? b : c) }
      out[i] = v & 255
    }
  }
  return { w, h, bpp, px }
}
const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }
const lum = ([r, g, b]) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
export const bandContrast = (card, parts) => async (page) => {
  const got = await page.evaluate(({ card, parts }) => {
    const el = [...document.querySelectorAll(card)].find((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 })
    if (!el) return { err: `no ${card} is drawn` }
    const scrolled = []; for (let p = el.parentElement; p; p = p.parentElement) if (p.scrollTop) scrolled.push([p, p.scrollTop])
    window.__bcRestore = { y: scrollY, scrolled }
    el.scrollIntoView({ block: 'center' })
    const r = el.getBoundingClientRect()
    const out = []
    for (const part of parts) {
      const t = [...el.querySelectorAll(part.sel)].find((e) => { const b = e.getBoundingClientRect(); return b.width > 0 && b.height > 0 })
      if (!t) { out.push({ name: part.name, missing: true }); continue }
      const nodes = part.own ? [...t.childNodes].filter((n) => n.nodeType === 3 && n.textContent.trim()) : [t]
      let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
      for (const n of nodes) { const rg = document.createRange(); rg.selectNodeContents(n); for (const b of rg.getClientRects()) { if (!b.width) continue; x0 = Math.min(x0, b.left); y0 = Math.min(y0, b.top); x1 = Math.max(x1, b.right); y1 = Math.max(y1, b.bottom) } }
      t.setAttribute('data-bc-hide', '')
      out.push({ name: part.name, large: !!part.large, color: getComputedStyle(t).color, box: [x0 - r.left, y0 - r.top, x1 - r.left, y1 - r.top] })
    }
    const st = document.createElement('style'); st.id = 'bc-hide'
    st.textContent = '[data-bc-hide], [data-bc-hide] *{color:transparent !important; text-shadow:none !important; border-color:transparent !important}'
    document.head.appendChild(st)
    return { clip: { x: r.left, y: r.top, width: r.width, height: r.height }, parts: out }
  }, { card, parts })
  if (got.err) return got.err
  let png
  try { png = decodePNG(await page.screenshot({ clip: got.clip })) }
  finally {
    await page.evaluate(() => {
      document.getElementById('bc-hide')?.remove(); document.querySelectorAll('[data-bc-hide]').forEach((e) => e.removeAttribute('data-bc-hide'))
      const s = window.__bcRestore; if (s) { s.scrolled.forEach(([p, t]) => { p.scrollTop = t }); scrollTo(0, s.y) }
    })
  }
  const k = png.w / got.clip.width, bad = [], log = []
  for (const p of got.parts) {
    if (p.missing) { bad.push(`${p.name} is not drawn`); continue }
    const fg = (p.color.match(/[\d.]+/g) || []).slice(0, 3).map(Number), lf = lum(fg)
    const [bx0, by0, bx1, by1] = p.box.map((v) => Math.round(v * k))
    let hi = 0, lo = 1
    for (let y = Math.max(0, by0); y < Math.min(png.h, by1); y++) for (let x = Math.max(0, bx0); x < Math.min(png.w, bx1); x++) {
      const i = (y * png.w + x) * png.bpp, l = lum([png.px[i], png.px[i + 1], png.px[i + 2]]); if (l > hi) hi = l; if (l < lo) lo = l
    }
    const worst = lf > (hi + lo) / 2 ? hi : lo   /* light type fails on the brightest ground, dark type on the darkest */
    const ratio = (Math.max(lf, worst) + 0.05) / (Math.min(lf, worst) + 0.05)
    log.push(`${p.name} ${ratio.toFixed(2)}`)
    if (ratio < (p.large ? 3 : 4.5)) bad.push(`${p.name} ${ratio.toFixed(2)}:1 on its worst ground`)
  }
  console.log(`[bandContrast] ${card} @${Math.round(got.clip.width)}w · ${log.join(' · ')}`)
  return bad.length ? 'copy over the photograph under AA (§10.3): ' + bad.join('; ') : true
}

/* TEN / W8 · W7-009 · L-34 and UI_SYSTEM §16A.4 (one fact, one encoding, per
 * viewport): at the desk a second print of a fact yields to the first.
 * `standsDown(sels)` fails the capture when an element a selector names (the
 * sidebar's strip, an aside's headline) is drawn at 960 or wider, or when the
 * page never built it (the check must find the element it says stands down).
 * Below 960 the desk's shape is not drawn and the check passes. */
export const standsDown = (sels) => async (page) => page.evaluate((sels) => {
  if (innerWidth < 960) return true
  const bad = []
  for (const sel of sels) {
    const el = document.querySelector(sel)
    if (!el) { bad.push(`${sel} was never built, so nothing yielded`); continue }
    const r = el.getBoundingClientRect(), cs = getComputedStyle(el)
    if (cs.display !== 'none' && r.width > 0 && r.height > 0) bad.push(`${sel} still prints (${JSON.stringify((el.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 50))})`)
  }
  return bad.length ? 'the desk prints a fact twice (§16A.4): ' + bad.join('; ') : true
}, sels)

/* TEN / W8 · W7-011, W7-012 · UI_SYSTEM §16.1 and WCAG 1.4.11: rule may
 * separate and never state, and a mark that carries a state reads at 3:1 or
 * better on its ground. `stateContrast(parts)` measures each part
 * `{ sel, prop, min, what }` (the first VISIBLE element's computed colour, its
 * `prop` — backgroundColor or a border colour — against the first opaque
 * ground above it) and fails the capture when a ratio is under `min` or a
 * part is not drawn. */
export const stateContrast = (parts) => async (page) => {
  const got = await page.evaluate((parts) => {
    const rgb = (c) => (c.match(/[\d.]+/g) || []).slice(0, 4).map(Number)
    const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }
    const lum = ([r, g, b]) => 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b)
    const ground = (el) => { for (let p = el.parentElement; p; p = p.parentElement) { const c = rgb(getComputedStyle(p).backgroundColor); if (c.length >= 3 && (c.length < 4 || c[3] > 0.99)) return c } return [255, 255, 255] }
    return parts.map((p) => {
      const el = [...document.querySelectorAll(p.sel)].find((e) => { const r = e.getBoundingClientRect(); return r.width > 0 && r.height > 0 })
      if (!el) return { what: p.what, missing: true }
      const c = rgb(getComputedStyle(el)[p.prop]), g = ground(el)
      const a = lum(c), b = lum(g)
      return { what: p.what, min: p.min, ratio: (Math.max(a, b) + 0.05) / (Math.min(a, b) + 0.05) }
    })
  }, parts)
  const bad = got.filter((r) => r.missing || r.ratio < r.min).map((r) => (r.missing ? `${r.what} is not drawn` : `${r.what} ${r.ratio.toFixed(2)}:1, under ${r.min}:1`))
  console.log(`[stateContrast] ${got.filter((r) => !r.missing).map((r) => `${r.what} ${r.ratio.toFixed(2)}`).join(' · ')}`)
  return bad.length ? 'a state is drawn in rule or too faint (§16.1): ' + bad.join('; ') : true
}

/* TEN / W8 · W7-014 · UI_SYSTEM §4: the gap between two sections is s5 (32px),
 * and a section head that opens its wrapper still follows a block. `headGap(
 * sels, min)` fails the capture when a visible head a selector names has less
 * than `min` px above it, or when none is drawn. The gap is the head's own
 * margin-top: the rule that pulled it to 4px is what this pins. */
export const headGap = (sels, min = 32) => async (page) => page.evaluate(([sels, min]) => {
  const bad = []; let seen = 0
  for (const sel of sels) for (const el of document.querySelectorAll(sel)) {
    const r = el.getBoundingClientRect(); if (!(r.width > 0 && r.height > 0)) continue
    seen++
    const m = parseFloat(getComputedStyle(el).marginTop)
    if (m < min) bad.push(`${sel} ${JSON.stringify((el.textContent || '').replace(/\s+/g, ' ').trim().slice(0, 30))} has ${m}px above it`)
  }
  if (!seen) return 'the state draws none of ' + sels.join(', ')
  return bad.length ? `a section head clings to the block above it (s5 is ${min}px, §4): ` + bad.join('; ') : true
}, [sels, min])

/* TEN / W8 · W7-025 · UI_SYSTEM §12.1 and §14.1: the desk sidebar's season
 * list marks where you are — one row current (`.active`, the 3px tick) and
 * said to a screen reader (`aria-current`), and it is the row of the section
 * in view, not always 'The season'. `deskMenuIs(name)` fails a desk capture
 * when the marked row is not `name`, or when the row is marked by one channel
 * only. Below 960 the sidebar is not drawn and the check passes. */
export const deskMenuIs = (want) => async (page) => page.evaluate((want) => {
  if (innerWidth < 960) return true
  const rows = [...document.querySelectorAll('#deskMenu .navitem')]
  const cur = rows.filter((r) => r.classList.contains('active')), aria = rows.filter((r) => r.getAttribute('aria-current'))
  const names = cur.map((r) => r.textContent.trim().replace(/’/g, "'"))
  if (names.length !== 1 || names[0] !== want) return `the desk menu marks ${JSON.stringify(names)}, expected ${JSON.stringify([want])}`
  if (aria.length !== 1 || aria[0] !== cur[0]) return 'aria-current is not on the marked row alone'
  return true
}, want)
