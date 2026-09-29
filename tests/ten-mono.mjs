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
