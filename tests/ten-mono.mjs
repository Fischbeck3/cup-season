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
