/* Cup Season · ten-capture states: PLAY, the live round (WX lane, 2026-09-28).
 *
 * Every state is driven through the page's own controls: the Play tab, "Score
 * it live", the course search (the cache read and the `courses` function), the
 * tee list, the roster chips, the game segment, Tee off, the +/- steppers on
 * each player's row, the hole arrows, Finish the round and its Post button.
 * The server half is tests/fixtures/ten/rpc/60-live.mjs. Nothing is written
 * into the page: a score exists because a stepper was tapped.
 *
 * The group is the synthetic cast of North Grove (fixture): Avery Fixture
 * (me), Devon Testwell, Blake Sample, Casey Placeholder. */
import { notMono, readsAsWritten, noRetiredGlyph, noRetiredShape, capsFromRole, destMarked, noHeadingSkips } from '../ten-mono.mjs'

const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const has = (sel, re, what) => async (page) => page.evaluate(({ sel, re, what }) => {
  const el = document.querySelector(sel)
  if (!el) return `${what}: ${sel} is missing`
  const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ')
  return new RegExp(re, 'i').test(t) ? true : `${what}: ${sel} reads ${JSON.stringify(t.slice(0, 160))}`
}, { sel, re, what })

/* TEN / W7-054 [A2-play-4] · the desk sets up on two columns: the group beside the course, Tee off at
   its own width under the first; below 960 course, group, game read down */
const setupColumns = async (page) => page.evaluate(() => {
  const q = (s) => document.querySelector(s), box = (el) => el.getBoundingClientRect()
  const course = q('#playSetup > .card:not(.lrgroup):not(.lrgame)'), group = q('#playSetup > .lrgroup'), game = q('#playSetup > .lrgame'), tee = q('#teeOffBtn')
  if (!course || !group || !game || !tee) return 'the setup lost a card'
  const c = box(course), g = box(group), m = box(game), t = box(tee)
  if (innerWidth >= 960) {
    if (!(g.left >= c.right - 1 && Math.abs(g.top - c.top) < 2)) return 'the group card is not beside the course card'
    if (!(Math.abs(m.left - c.left) < 1 && m.top >= c.bottom - 1)) return 'the game card is not under the course card'
    if (t.width >= c.width - 1 || t.left > c.left + 1) return 'Tee off still spans the column'
    return true
  }
  return c.top < g.top && g.top < m.top ? true : 'below 960 the order is not course, group, game'
})
/* TEN / W7-056 [A2-play-9] · a Next hole under the last golfer's row, on a phone held upright; gone on the
   last hole; it moves exactly as the header's arrow does */
const nextHoleFoot = async (page) => {
  const r = await page.evaluate(() => {
    const b = document.getElementById('holeNextFoot')
    if (!b) return 'no Next hole in the thumb zone'
    const shown = b.offsetParent !== null && !b.hidden
    if (innerWidth >= 740) return shown ? 'the foot’s Next hole shows on a wide screen' : 'wide'
    if (!shown) return 'the foot’s Next hole is hidden on a phone'
    const rows = document.querySelectorAll('#playerRows > *')
    if (rows.length && !(rows[rows.length - 1].compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING)) return 'Next hole is not under the last golfer’s row'
    if (b.getBoundingClientRect().height < 49.5) return 'Next hole is under 50px'
    return state.live.hole
  })
  if (r === 'wide') return true
  if (typeof r !== 'number') return r
  await page.evaluate(() => { window.__nhY = window.scrollY; document.getElementById('holeNextFoot').click() })
  await page.waitForTimeout(250)
  const out = await page.evaluate((h0) => {
    const moved = state.live.hole === h0 + 1
    const last = liveHoles() - 1, keep = state.live.hole
    state.live.hole = last; renderPlay()
    const goneOnLast = document.getElementById('holeNextFoot').hidden
    state.live.hole = h0; renderPlay(); window.scrollTo(0, window.__nhY || 0); if (typeof csLiveSticky === 'function') csLiveSticky()
    return !moved ? 'Next hole did not move one hole' : !goneOnLast ? 'Next hole shows on the last hole' : true
  }, r)
  return out
}
/* TEN / W6 · W7-125 [A2-post-7] · where you are: the composer and live scoring
   are Play's pages, so Play (router id `record`) is the one destination marked,
   in the tab band below desk width and the sidebar on the desk, and it is
   current to a screen reader. Nothing was marked. */
const playIsWhereYouAre = async (page) => page.evaluate(() => {
  const shown = (el) => el.offsetParent !== null && getComputedStyle(el).visibility !== 'hidden'
  const marked = [...document.querySelectorAll('.tab, .navitem')].filter((t) => shown(t) && t.classList.contains('active'))
  if (marked.length !== 1) return 'destinations marked: ' + JSON.stringify(marked.map((t) => t.dataset.v))
  if (marked[0].dataset.v !== 'record') return 'the marked destination is ' + marked[0].dataset.v + ', not Play'
  return marked[0].getAttribute('aria-current') === 'page' ? true : 'Play is marked but not current to a screen reader'
})
/* TEN / W6 · W7-096 · gold is earned (D359): no live state wears it. The mid-round leader chip is ink-outlined with an ink name, and a
   finished card's status line is ink (inert where neither is drawn) */
const noLiveGold = async (page) => page.evaluate(() => {
  const probe = (v) => { const i = document.createElement('i'); i.style.color = `var(${v})`; document.body.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
  const gold = probe('--gold'), ink = probe('--ink')
  const lead = [...document.querySelectorAll('.scoreboard .sbchip.lead')].find((c) => c.getBoundingClientRect().height > 0)
  if (lead) {
    if (getComputedStyle(lead).borderTopColor === gold || getComputedStyle(lead.querySelector('b')).color === gold) return 'the live leader chip wears gold'
    if (getComputedStyle(lead).borderTopColor !== ink) return 'the live leader chip is not ink-outlined: ' + getComputedStyle(lead).borderTopColor
  }
  const fs = document.getElementById('finishStatus')
  if (fs && fs.getBoundingClientRect().height > 0 && getComputedStyle(fs).color === gold) return 'the finish line turns gold'
  return true
})
/* TEN / W6 · W7-092 · below 640px every one of the five games is on screen with no scroll: the phone's wrapping chip flow */
const gamesOnScreen = async (page) => page.evaluate(() => {
  if (innerWidth > 640) return true
  const seg = document.getElementById('gameSeg'), bs = [...seg.querySelectorAll('button')]
  if (bs.length !== 5) return `the picker has ${bs.length} games`
  if (seg.scrollWidth > seg.clientWidth + 1) return 'the game picker still scrolls sideways'
  const off = bs.find((b) => { const r = b.getBoundingClientRect(); return r.left < 0 || r.right > innerWidth + 0.5 || r.height < 43.5 })
  return off ? `"${off.textContent.trim()}" is not whole on screen at 44` : true
})
/* TEN / W6 · W7-102 · a golfer's row total is that gross against par, labelled: 'E' at level (never '+0'), and '20 gross · thru 5' under it */
const rowTotals = async (page) => page.evaluate(() => {
  const tots = [...document.querySelectorAll('#playerRows .tot')].filter((t) => t.getBoundingClientRect().height > 0 && t.querySelector('b'))
  if (!tots.length) return 'no scored row total is drawn'
  for (const t of tots) {
    const b = t.querySelector('b').textContent.trim(), rest = t.textContent.replace(t.querySelector('b').textContent, '').trim()
    if (b === '+0' || !/^(E|[+\u2212]\d+)$/.test(b)) return 'a row total reads ' + JSON.stringify(b)
    if (!/^\d+ gross · thru \d+$/.test(rest)) return 'a row total’s small line reads ' + JSON.stringify(rest)
  }
  return true
})
/* TEN / W6 · W7-103 · on the desk a dot means only 'level' (the strip's): THE CARD draws a hole not played as the en dash */
const deskCardDash = async (page) => page.evaluate(() => {
  if (innerWidth < 960) return true
  const cells = [...document.querySelectorAll('#deskCard td')].filter((c) => c.getBoundingClientRect().height > 0)
  if (!cells.length) return 'THE CARD is not drawn on the desk'
  if (cells.some((c) => c.textContent.trim() === '\u00b7')) return 'THE CARD draws a dot for a hole not played'
  return cells.some((c) => c.textContent.trim() === '\u2013') ? true : 'THE CARD shows no unplayed hole, so its dash cannot be read'
})
/* TEN / W7-128 [B2-play-7] · the stepper's names say what a tap does: an empty seat's first tap enters par,
   so both buttons say so; a scored seat's say one stroke fewer and one more. The empty seat is an em dash
   in mut on a 2px line (the phone's) */
const stepperNamed = async (page) => page.evaluate(() => {
  const steps = [...document.querySelectorAll('#playerRows .lrow .step')]
  if (!steps.length) return 'no steppers'
  const probe = (el, v) => { const i = document.createElement('i'); i.style.color = `var(${v})`; el.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
  for (const st of steps) {
    const sv = st.querySelector('.sv'), [minus, plus] = st.querySelectorAll('button'), v = sv.textContent.trim()
    const a = [minus.getAttribute('aria-label'), plus.getAttribute('aria-label')]
    if (!/^\d+$/.test(v)) {
      if (v !== '\u2014') return `an empty seat reads ${JSON.stringify(v)}, not an em dash`
      if (!a.every((l) => /^Enter par \(\d\) for .+, hole \d+$/.test(l))) return 'an empty seat’s buttons are named ' + JSON.stringify(a)
      const cs = getComputedStyle(sv)
      if (cs.color !== probe(sv.parentElement, '--mut')) return 'the empty seat is not mut'
      if (cs.borderBottomWidth !== '2px' || cs.borderBottomColor !== probe(sv.parentElement, '--rule')) return 'the empty seat has no 2px rule line'
    } else if (!/^One stroke fewer for /.test(a[0]) || !/^One more stroke for /.test(a[1])) return 'a scored seat’s buttons are named ' + JSON.stringify(a)
  }
  return true
})
/* TEN / W7-122 [B2-play-5] · a settlement is a sentence about who pays whom (LiveCopy.settleRows), never a
   typed arrow (§5.2, LINT-13) */
const settlePays = async (page) => page.evaluate(() => {
  const rows = [...document.querySelectorAll('#settle .srow span')].map((s) => s.textContent.trim())
  if (!rows.length) return 'the settlement has no rows'
  const arrow = rows.filter((t) => /[\u2190-\u21ff]|->|<-/.test(t))
  if (arrow.length) return 'the settlement types an arrow: ' + JSON.stringify(arrow)
  const pays = rows.filter((t) => /\bpays\b/i.test(t))
  return pays.length ? true : 'no settlement row says who pays whom: ' + JSON.stringify(rows)
})
/* the real door: the Play tab (router id `record`), then Score it live */
async function toSetup(page) {
  await page.locator('.tab[data-v="record"]:visible, .navitem[data-v="record"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-record')
  await click(page, '#optLive')
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-play' && getComputedStyle(document.getElementById('playSetup')).display !== 'none')
  await page.waitForTimeout(500)
}
/* the course search: the page's own dropdown, a course, then its tee */
async function pickCourse(page, query, course, tee) {
  await page.locator('#lrCourse').click()
  await page.locator('#lrCourse').fill(query)
  await until(page, (course) => [...document.querySelectorAll('.coursedd [data-ci]')].some((b) => b.textContent.includes(course)), course, 10000)
  await page.locator('.coursedd [data-ci]', { hasText: course }).first().click()
  await until(page, () => document.querySelectorAll('.coursedd [data-ti]').length > 0)
  await page.locator('.coursedd [data-ti]', { hasText: tee }).first().click()
  await until(page, () => document.getElementById('lrRate').value !== '' && document.getElementById('lrSlope').value !== '')
  await page.waitForTimeout(600)   /* the tee's holes load behind the pick (pars + SI) */
}
async function addGolfers(page, names) {
  for (const n of names) {
    await page.locator('#rosterChips .selchip', { hasText: n }).first().click({ timeout: 8000 })
    await page.waitForTimeout(150)
  }
}
async function teeOff(page) {
  await click(page, '#teeOffBtn')
  /* `state` is a classic-script top-level binding (not on window): read it by name */
  await until(page, () => getComputedStyle(document.getElementById('playLive')).display !== 'none' && typeof state !== 'undefined' && !!(state.live && state.live.lr), null, 10000)
  await page.waitForTimeout(600)
}
/* score `holes` holes through the steppers: the first tap writes par, the
   pattern then adds or takes strokes, so the card is a real card */
const PATTERN = [[0, 1, 0, 1], [1, 0, 0, 2], [0, 0, -1, 0], [1, 1, 0, 0], [0, 2, 1, 0], [-1, 0, 0, 1], [0, 1, 1, 0], [1, 0, 0, 0], [0, 0, 1, 1]]
async function scoreHoles(page, holes, players) {
  for (let h = 0; h < holes; h++) {
    for (let pi = 0; pi < players; pi++) {
      await click(page, `#playerRows [data-pi="${pi}"][data-d="1"]`)
      const extra = PATTERN[h % PATTERN.length][pi % 4]
      for (let k = 0; k < Math.abs(extra); k++) await click(page, `#playerRows [data-pi="${pi}"][data-d="${extra > 0 ? 1 : -1}"]`)
    }
    if (h < holes - 1) { await click(page, '#holeNext'); await until(page, (n) => /HOLE\s+/.test(document.getElementById('holeNum').textContent) && document.getElementById('holeNum').textContent.trim() === 'HOLE ' + n, h + 2) }
  }
  await page.waitForTimeout(500)
}
/* a toast from an earlier tap (tee-off's "On the tee…") is not the state:
   let it leave before the capture (the page clears it after 2.4 s) */
const toastGone = (page) => page.waitForFunction(() => !document.getElementById('toast').classList.contains('show'), null, { timeout: 6000 }).catch(() => {})
const liveFacts = (page) => page.evaluate(() => {
  const L = typeof state !== 'undefined' ? state.live : null
  return { lr: L && L.lr, active: !!(L && L.active), game: L && L.game, holes: L && L.holes, queued: window.liveSync ? window.liveSync.queued() : null,
    scored: L ? L.scores.map((row) => row.filter((v) => v != null).length) : null }
})
const scoredCheck = (want) => async (page) => {
  const f = await liveFacts(page)
  if (!f.lr || !f.active) return 'no live round is running'
  return f.scored && f.scored.every((n) => n === want) ? true : `scored ${JSON.stringify(f.scored)}, expected ${want} each`
}

/* the F08 fields keep their names once filled */
const teeFieldsNamed = async (page) => page.evaluate(() => {
  const named = ['lrTee', 'lrRate', 'lrSlope'].map((id) => { const i = document.getElementById(id); const l = i && i.labels && i.labels[0]; return [id, l ? l.textContent.trim() : null, i ? i.value : null] })
  const bad = named.filter(([, l, v]) => !l || !v)
  return bad.length ? 'unnamed or empty tee fields: ' + JSON.stringify(bad) : true
})

export default [
  { family: 'play', id: 'setup-empty', variant: 'member', title: 'Live setup · before a course is picked',
    drive: toSetup,
    expect: { view: 'view-play', selectors: { '#playSetup': 'visible', '#playLive': 'hidden', '#teeOffBtn': 'visible', '#lrCourse': 'visible' } },
    check: all(destMarked('record'), gamesOnScreen,   /* TEN / W8 · W7-108: the live setup is a room of PLAY, so PLAY stays marked; W7-092: every game on screen below 640 */
      /* TEN / W7-116 [A2-play-8] · your scorecard, the course's pars, and 'tap + to start at par' (TERMINOLOGY :88, :153) */
      has('#gameNote', '^Stroke play \u2014 your scorecard, your pace\\.', 'the game note'),
      has('#cardNote', '^Standard par 72\\. Tap \\+ to start each hole at par', 'the pars note'),
      async (page) => page.evaluate(() => {
      /* TEN / W6 · AW2-14: Play's "Score it live" door is an action — its word and dot are act, never ember */
      const tok = (v) => { const i = document.createElement('i'); i.style.color = `var(${v})`; document.body.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
      const w = document.querySelector('#optLive .liveword'), d = document.querySelector('#optLive .livedot')
      if (!w || !d) return 'the live door has no word and dot'
      return getComputedStyle(w).color === tok('--act') && getComputedStyle(d).backgroundColor === tok('--act') ? true : 'the live door is not act: ' + getComputedStyle(w).color
    }), async (page) => page.evaluate(() => {
      const v = ['lrCourse', 'lrTee', 'lrRate', 'lrSlope'].map((id) => document.getElementById(id).value)
      return v.every((x) => x === '') ? true : 'the setup carries values before a course is picked: ' + JSON.stringify(v)
    })) },

  { family: 'play', id: 'setup-filled', variant: 'member', title: 'Live setup · Saguaro Flats, Blue, 70.1/121, a group of three',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell', 'Blake Sample'])
      /* the tee pick scrolled the list into view and toasted: settle both */
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-play', selectors: { '#playSetup': 'visible', '#selCount': 'text:^3$', '#teeOffBtn': 'visible' } },
    check: all(teeFieldsNamed,
      has('#cardNote', '^Pars loaded: 18-hole pars and stroke index from the course\\.$', 'the pars note'),   /* TEN / W7-116 */
      async (page) => page.evaluate(() => {
        const [c, t, r, s] = ['lrCourse', 'lrTee', 'lrRate', 'lrSlope'].map((id) => document.getElementById(id).value)
        return /Saguaro Flats/.test(c) && t === 'Blue' && r === '70.1' && s === '121' ? true : `the fields read ${JSON.stringify([c, t, r, s])}`
      }),
      has('#fourSlots', 'Devon Testwell[\\s\\S]*Blake Sample|Blake Sample[\\s\\S]*Devon Testwell', 'the group'),
      /* TEN / W7-127: the course's pars loaded, so the pars button checks them, never asks for them */
      async (page) => page.evaluate(() => {
        const n = (document.getElementById('cardNote') || {}).textContent || '', b = document.getElementById('editCard').textContent.trim()
        if (!/^Pars loaded/.test(n)) return 'the card did not load its pars here, so the button cannot be read: ' + JSON.stringify(n.slice(0, 60))   /* W7-116 renamed the note */
        return b === 'Check the pars' ? true : 'the pars button still asks for work already done: ' + JSON.stringify(b)
      }),
      /* TEN / W7-054 [A2-play-4]: the desk sets up on two columns; below 960 course, group, game read down */
      setupColumns) },

  /* TEN / W8 · W7-069 [X13] · the court: four golfers on Match Play turn the slots into two team zones, each labelled by a heading that follows the page's outline (an h2 under the h1, not an h5) */
  { family: 'play', id: 'setup-court', variant: 'member', title: 'Live setup · Match Play with four golfers: the court (two team zones)',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell', 'Blake Sample', 'Casey Placeholder'])
      await click(page, '#gameSeg [data-g="match"]')
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-play', selectors: { '#fourSlots .crtzone': 'visible' } },
    check: all(noHeadingSkips('#fourSlots'),
      async (page) => page.evaluate(() => document.querySelectorAll('#fourSlots .crtzone > h2').length === 2 ? true : 'the court has no two labelled zones')) },

  /* five holes in, on the sixth tee; scrolled so the scoreboard sticks */
  { family: 'play', id: 'scoring', variant: 'member', fullPage: false, title: 'Live round · just score, three golfers, through five, the scoreboard stuck (phone widths; the desk fits one screen)',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell', 'Blake Sample'])
      await teeOff(page)
      await scoreHoles(page, 5, 3)
      await click(page, '#holeNext')
      await until(page, () => document.getElementById('holeNum').textContent.trim() === 'HOLE 6')
      await toastGone(page)
      await page.locator('#playerRows').scrollIntoViewIfNeeded()
      await page.evaluate(() => window.scrollBy(0, 120))
      await until(page, () => document.getElementById('scoreBoard').classList.contains('stuck'), null, 5000).catch(() => {})
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-play', selectors: { '#playLive': 'visible', '#holeNum': 'text:^HOLE 6$' } },
    check: all(scoredCheck(5), playIsWhereYouAre, noLiveGold, rowTotals, deskCardDash, stepperNamed, async (page) => { const f = await liveFacts(page); return f.queued === 0 ? true : `${f.queued} score(s) still queued with the server answering` },
      /* the board sticks only where the page scrolls: on the desk the whole
         round fits the first screen, so there is nothing to stick over */
      async (page) => page.evaluate(() => {
        const scrolls = document.documentElement.scrollHeight > innerHeight + 40
        const stuck = document.getElementById('scoreBoard').classList.contains('stuck')
        return !scrolls || stuck ? true : 'the page scrolls but the scoreboard did not stick'
      })) },

  /* TEN / W7-119 [A2-play-11] · D368's web half: my birdie on the sixth, committed by leaving the hole, is said
     once beside the header ('BIRDIE on 6', one 2px ember stroke, never over Next hole) and tallied under the
     strip; going back and leaving again with the same score does not replay it */
  { family: 'play', id: 'moment', variant: 'member', fullPage: false, title: 'Live round · a birdie on the sixth, said once as the golfer leaves the hole',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell', 'Blake Sample'])
      await teeOff(page)
      await scoreHoles(page, 6, 3)
      await toastGone(page)
      await click(page, '#holeNext')
      await until(page, () => document.getElementById('holeNum').textContent.trim() === 'HOLE 7')
      /* as the scoring state rests: the rows in view, the scoreboard stuck (at 375 a page resting at its
         top never settles for the screenshot) */
      await page.locator('#holeDots').scrollIntoViewIfNeeded()
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-play', selectors: { '#playLive': 'visible', '#holeNum': 'text:^HOLE 7$' } },
    check: async (page) => {
      const r = await page.evaluate(() => {
        const m = document.getElementById('holeMoment'), t = document.getElementById('holeTally'), nx = document.getElementById('holeNext')
        if (!m || m.hidden) return 'no moment beside the header after a birdie'
        if (!/^birdie\s*on 6$/i.test(m.textContent.replace(/\s+/g, ' ').trim())) return 'the moment reads ' + JSON.stringify(m.textContent)
        const probe = document.createElement('i'); probe.style.color = 'var(--brand)'; m.appendChild(probe); const ember = getComputedStyle(probe).color; probe.remove()
        const st = getComputedStyle(m)
        if (st.borderLeftWidth !== '2px' || st.borderLeftColor !== ember) return 'the moment has no 2px ember stroke'
        const a = m.getBoundingClientRect(), b = nx.getBoundingClientRect()
        if (a.left < b.right && a.right > b.left && a.top < b.bottom && a.bottom > b.top) return 'the moment covers Next hole'
        if (!t || t.hidden || !/^1 birdie$/i.test(t.textContent.trim())) return 'the tally reads ' + JSON.stringify(t && t.textContent)
        return true
      })
      if (r !== true) return r
      /* back to the sixth and off it again, the score unchanged: no replay; then restore the capture's hole */
      await click(page, '#holePrev'); await click(page, '#holeNext')
      await page.waitForTimeout(150)
      const again = await page.evaluate(() => document.getElementById('holeMoment').hidden)
      await page.evaluate(() => { csMomentPaint('birdie', 6) })
      return again ? true : 'leaving the sixth again replayed the birdie'
    } },

  /* the same round with the score writes failing: the scores stay on this
     phone, queued, and the line under the scoreboard says so.
     W1 (2026-09-28): the line says it in words now — "6 scores saved on this
     phone; they send when you have signal." — where it said "6 QUEUED", so the
     state waits for and expects that sentence. */
  { family: 'play', id: 'sync-pending', variant: 'member', title: 'Live round · the score writes are not landing (queued on this phone)',
    prepare: async (W) => { W.errors.rpc.live_set_score = { __abort: 'internetdisconnected' } },
    expectConsole: [/net::ERR_INTERNET_DISCONNECTED|Failed to load resource/],
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell'])
      await teeOff(page)
      await scoreHoles(page, 3, 2)
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await until(page, () => /saved on this phone/.test((document.getElementById('sbSub') || {}).textContent || ''), null, 8000)
      await page.waitForTimeout(300)
    },
    /* TEN / W6 · and WHEN, in the phone's words (LiveCopy.closesText): the
       round just teed off, so it closes in 23h; past its window the line
       drops "they send when you have signal", which is no longer true */
    expect: { view: 'view-play', selectors: { '#playLive': 'visible', '#sbSub': 'text:saved on this phone; they send when you have signal · closes in 2[34]h' } },
    check: all(scoredCheck(3), async (page) => { const f = await liveFacts(page); return f.queued > 0 ? true : 'nothing is queued' },
      async (page) => page.evaluate(() => {
        const L = state.live, was = L.startedAt, el = document.getElementById('sbSub')
        L.startedAt = Date.now() - 25 * 3600000; window.liveSyncBadge()
        const past = el.textContent
        L.startedAt = was; window.liveSyncBadge()
        return /saved on this phone · past its window$/.test(past) && !/when you have signal/.test(past) ? true : `past its window the line says ${JSON.stringify(past)}`
      })) },

  /* TEN / W6 · critique A2 (P1): "Change setup" mid-round set the round inactive,
     so nothing led back and Tee off built a new round with blank scores. The
     round is held now: the same live round, its scores and its channel; the
     setup offers "Back to the round". The check goes back and returns, and
     the capture is the held setup.
     TEN / W7-003 [X02] · the held setup offered a course, tee, rating, slope,
     holes and pars the server never receives (finish_live_round posts on the
     tee-off snapshot). Each is disabled while held, shown mut at full
     strength, the line says why and names the way to change them, and the way
     back lifts the locks. */
  { family: 'play', id: 'setup-held', variant: 'member', fullPage: false, title: 'Live round · Change setup mid-round: the round is held, and the way back returns to it',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Saguaro', 'Saguaro Flats', 'Blue')
      await addGolfers(page, ['Devon Testwell'])
      await teeOff(page)
      await scoreHoles(page, 3, 2)
      await toastGone(page)
      await page.evaluate(() => { window.__heldBefore = { lr: state.live.lr, scores: JSON.stringify(state.live.scores) } })
      await click(page, '#backToSetup')
      await until(page, () => { const h = document.getElementById('lrHeld'); return !!h && !h.hidden }, null, 6000)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-play', selectors: { '#lrHeld': 'text:Your round is still on, and its 3 holes scored stay with it', '#lrBackToRound': 'visible', '#teeOffBtn': 'hidden', '#playSetup .lrgroup': 'hidden', '#playSetup .lrgame': 'hidden' } },
    check: all(async (page) => page.evaluate(() => {
      const setupEls = () => ['lrCourse', 'lrTee', 'lrRate', 'lrSlope', 'editCard'].map(id => document.getElementById(id)).concat([...document.querySelectorAll('#lrHoles button')])
      const open = setupEls().filter(el => !el || !el.disabled).map(el => el ? (el.id || el.textContent.trim()) : 'missing')
      if (open.length) return 'the held setup still offers an edit the server never receives: ' + open.join(', ')
      const line = document.getElementById('lrHeld').textContent
      if (!/ The course, tee and holes were set at tee-off\. To change them, scrap this round and tee off again\.$/.test(line) || /Change the course/.test(line)) return 'the held line does not say why the setup is locked: ' + JSON.stringify(line)
      const card = document.querySelector('#playSetup .card'), probe = document.createElement('span')
      probe.style.color = 'var(--mut)'; card.appendChild(probe); const mut = getComputedStyle(probe).color; probe.remove()
      for (const id of ['lrCourse', 'lrRate']) {
        const st = getComputedStyle(document.getElementById(id))
        if (st.color !== mut || st.webkitTextFillColor !== mut || st.opacity !== '1') return `#${id}'s locked value is not mut at full strength: ${st.color} / ${st.webkitTextFillColor} / opacity ${st.opacity}`
      }
      /* W7-003 (the remainder, D's delta) · the card note is setup guidance
         ("pick your course above and the real pars load" when no card was
         loaded this session); beside a locked course it stands down */
      const cn = document.getElementById('cardNote')
      if (cn && getComputedStyle(cn).display !== 'none') return 'the card note still gives setup guidance beside the locked course: ' + JSON.stringify(cn.textContent.trim().slice(0, 80))
      return true
    }), async (page) => {
      const held = await page.evaluate(() => ({ active: state.live.active, lr: state.live.lr, same: state.live.lr === window.__heldBefore.lr && JSON.stringify(state.live.scores) === window.__heldBefore.scores }))
      if (!held.active || !held.same) return 'the round was not held: ' + JSON.stringify(held)
      await click(page, '#lrBackToRound')
      await until(page, () => document.getElementById('playLive').offsetParent !== null, null, 6000)
      const back = await page.evaluate(() => ({ live: document.getElementById('playLive').offsetParent !== null, same: state.live.lr === window.__heldBefore.lr && JSON.stringify(state.live.scores) === window.__heldBefore.scores,
        unlocked: ['lrCourse', 'lrTee', 'lrRate', 'lrSlope', 'editCard'].every(id => !document.getElementById(id).disabled) && [...document.querySelectorAll('#lrHoles button')].every(b => !b.disabled)
          && document.getElementById('cardNote').style.display !== 'none' }))
      await click(page, '#backToSetup')   /* the capture is the held setup */
      await until(page, () => { const h = document.getElementById('lrHeld'); return !!h && !h.hidden }, null, 6000)
      await page.evaluate(() => window.scrollTo(0, 0))
      return back.live && back.same && back.unlocked ? true : 'the way back did not return to the same round, unlocked: ' + JSON.stringify(back)
    },
    /* TEN / W6 · AW2-06: the back link and the tab labels are labels — agate,
       never mono (§1.4) */
    notMono(['#view-play .backlink', '.tabbar .tab'], ['#view-play .backlink', { sel: '.tabbar .tab', below: 960 }]),
    /* TEN / W6 · AW2-08: the back link's arrow is the drawn chevron */
    noRetiredGlyph(),
    noRetiredShape()) },

  /* a Match Play single, $5 a side, through four */
  { family: 'play', id: 'match-scoring', variant: 'member', title: 'Live round · Match Play singles with Devon, $5, through four',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Mesquite', 'Mesquite Wash', 'Black')
      await addGolfers(page, ['Devon Testwell'])
      await click(page, '#gameSeg [data-g="match"]')
      await page.locator('#lrStake').fill('5')
      await teeOff(page)
      await scoreHoles(page, 4, 2)
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(300)
    },
    /* AW2-16 · the match state is said once, by the scoreboard hero; the card
       keeps the terms (who, strokes, stake) and its status line stays hidden */
    expect: { view: 'view-play', selectors: { '#matchCard': 'visible', '#matchStatus': 'hidden', '#sbHero': 'visible' } },
    check: all(scoredCheck(4), stepperNamed, async (page) => { const f = await liveFacts(page); return f.game === 'match' ? true : 'the game is ' + f.game },
      has('#matchMeta', 'THRU 4', 'the match line'),
      /* TEN / W6 · AW2-15: the side games' gloss is a phrase, in sentence case (§1.3) */
      readsAsWritten([['p.eb-gloss.sg-head', 'Tracked live, settled between friends']]),
      /* TEN / W6 · AW2-08: the hole arrows are the drawn chevron */
      noRetiredGlyph(),
      async (page) => {
        const t = await page.evaluate(() => [document.getElementById('sbHero')?.textContent || '', document.getElementById('matchStatus')?.textContent || ''])
        return t[0] && t[0] === t[1] && /\b(up|square|win)\b/i.test(t[0]) ? true : 'the hero does not carry the match state: ' + JSON.stringify(t)
      },
      /* TEN / W6 · OB2-02 (root's §1.3 ruling): the card's meta line and the scoreboard hero are typed as said, their caps the roles' */
      capsFromRole(['#matchMeta', '#sbHero'], ['#matchMeta', '#sbHero']),
      /* TEN / W7-056 [A2-play-9]: a Next hole in the thumb zone, under the last golfer's row (this state rests at the page top,
         so the check's click and its restore leave the capture as it was) */
      nextHoleFoot) },

  /* Skins, three golfers, through five */
  { family: 'play', id: 'skins-scoring', variant: 'member', title: 'Live round · Skins, three golfers, $2 a skin, through five',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Sandbox', 'Sandbox Fixture Links', 'Gold')
      await addGolfers(page, ['Devon Testwell', 'Casey Placeholder'])
      await click(page, '#gameSeg [data-g="skins"]')
      await page.locator('#lrStake').fill('2')
      await teeOff(page)
      await scoreHoles(page, 5, 3)
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-play', selectors: { '#skinsCard': 'visible', '#skinsStatus': 'visible' } },
    check: all(settlePays,   /* TEN / W7-122: who pays whom, in words */
      scoredCheck(5), async (page) => { const f = await liveFacts(page); return f.game === 'skins' ? true : 'the game is ' + f.game },
      /* TEN / W6 · DX2 OB2-02: the meta line's caps are its role's, not typed into the string */
      capsFromRole(['#skinsMeta', '#skinsStatus', '#skinsTally .wt span', '#sbHero'], ['#skinsMeta', '#skinsStatus', '#skinsTally .wt span', '#sbHero'])) },

  /* TEN / W6 · OB2-02 (root's §1.3 ruling) · Wolf, four golfers, through three: the card's state line ("Devon is the wolf"), its
     tee order, the partner buttons and the tally are typed as said, and the roles set their caps */
  { family: 'play', id: 'wolf-scoring', variant: 'member', title: 'Live round · Wolf, four golfers, through three',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Mesquite', 'Mesquite Wash', 'Black')
      await addGolfers(page, ['Devon Testwell', 'Blake Sample', 'Casey Placeholder'])
      await click(page, '#gameSeg [data-g="wolf"]')
      await teeOff(page)
      await scoreHoles(page, 3, 4)
      await toastGone(page)
      await page.evaluate(() => window.scrollTo(0, 0))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-play', selectors: { '#wolfCard': 'visible', '#wolfWho': 'text:is the wolf' } },
    check: all(scoredCheck(3),
      capsFromRole(['#wolfWho', '#wolfMeta', '#wolfBtns button', '#wolfTally .wt span', '#sbHero'], ['#wolfWho', '#wolfMeta', '#wolfBtns button', '#wolfTally .wt span', '#sbHero'])) },

  /* the nine is scored through the last hole; Finish opens the one-finish
     sheet for the group (opened, not yet posted) */
  { family: 'play', id: 'finish-confirm', variant: 'member', fullPage: false, title: 'Live round · the last hole in, Finish the round (the group’s one finish)',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Dry Creek', 'Dry Creek Nine', 'Forward')
      await addGolfers(page, ['Devon Testwell'])
      await teeOff(page)
      await scoreHoles(page, 9, 2)
      await toastGone(page)
      await click(page, '#finishBtn')
      await until(page, () => document.getElementById('sheet').classList.contains('open') && /Finish the round/.test(document.getElementById('shTitle').textContent))
      await page.waitForTimeout(400)
    },
    /* TEN / W7-116 [A2-play-8] · what posts is rounds and what is complete is a scorecard: a card is the golfer (T-01) */
    expect: { view: 'view-play', sheet: '^Finish the round$', selectors: { '#lrPost': 'text:^Post 2 rounds to the season$', '#lrCasual': 'text:^This one was casual — post nothing$' } },
    check: all(async (page) => { const f = await liveFacts(page); return f.holes === 9 ? true : `the round is ${f.holes} holes, expected the nine` },
      noLiveGold,   /* TEN / W6 · W7-096 */
      has('#shBody', 'Complete scorecards post to the season[\\s\\S]*A partial scorecard is skipped, not lost', 'the finish sheet\u2019s fine print')) },

  /* Post: finish_live_round answers, the settlement sheet (the ceremony) */
  { family: 'play', id: 'finish', variant: 'member', fullPage: false, title: 'Live round · posted: the round’s settlement (two rounds to the season)',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Dry Creek', 'Dry Creek Nine', 'Forward')
      await addGolfers(page, ['Devon Testwell'])
      await teeOff(page)
      await scoreHoles(page, 9, 2)
      await click(page, '#finishBtn')
      await until(page, () => document.getElementById('sheet').classList.contains('open') && !!document.getElementById('lrPost'))
      await click(page, '#lrPost')
      await until(page, () => document.getElementById('sheet').classList.contains('open') && /Round posted/i.test(document.getElementById('shTitle').textContent), null, 10000)
      await page.waitForTimeout(700)
    },
    expect: { view: 'view-play', sheet: 'Round posted', selectors: { '#sheet.room-dusk': 'visible', '#lrMine': 'text:Round posted', '#lrViewRound': 'visible' } },
    check: all(has('#shSub', '2 ROUNDS TO THE SEASON', 'the round count'),   /* TEN / W7-116 */
      async (page) => { const f = await liveFacts(page); return !f.active ? true : 'the round is still live after the finish' }) },
]
