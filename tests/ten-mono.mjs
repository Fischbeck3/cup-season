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
