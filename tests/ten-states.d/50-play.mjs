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
import { notMono, readsAsWritten, noRetiredGlyph, noRetiredShape, capsFromRole } from '../ten-mono.mjs'

const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const has = (sel, re, what) => async (page) => page.evaluate(({ sel, re, what }) => {
  const el = document.querySelector(sel)
  if (!el) return `${what}: ${sel} is missing`
  const t = (el.innerText || el.textContent || '').replace(/\s+/g, ' ')
  return new RegExp(re, 'i').test(t) ? true : `${what}: ${sel} reads ${JSON.stringify(t.slice(0, 160))}`
}, { sel, re, what })

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
    check: all(async (page) => page.evaluate(() => {
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
      async (page) => page.evaluate(() => {
        const [c, t, r, s] = ['lrCourse', 'lrTee', 'lrRate', 'lrSlope'].map((id) => document.getElementById(id).value)
        return /Saguaro Flats/.test(c) && t === 'Blue' && r === '70.1' && s === '121' ? true : `the fields read ${JSON.stringify([c, t, r, s])}`
      }),
      has('#fourSlots', 'Devon Testwell[\\s\\S]*Blake Sample|Blake Sample[\\s\\S]*Devon Testwell', 'the group')) },

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
    check: all(scoredCheck(5), async (page) => { const f = await liveFacts(page); return f.queued === 0 ? true : `${f.queued} score(s) still queued with the server answering` },
      /* the board sticks only where the page scrolls: on the desk the whole
         round fits the first screen, so there is nothing to stick over */
      async (page) => page.evaluate(() => {
        const scrolls = document.documentElement.scrollHeight > innerHeight + 40
        const stuck = document.getElementById('scoreBoard').classList.contains('stuck')
        return !scrolls || stuck ? true : 'the page scrolls but the scoreboard did not stick'
      })) },

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
     setup keeps what changes in place and offers "Back to the round". The
     check goes back and returns, and the capture is the held setup. */
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
    check: all(async (page) => {
      const held = await page.evaluate(() => ({ active: state.live.active, lr: state.live.lr, same: state.live.lr === window.__heldBefore.lr && JSON.stringify(state.live.scores) === window.__heldBefore.scores }))
      if (!held.active || !held.same) return 'the round was not held: ' + JSON.stringify(held)
      await click(page, '#lrBackToRound')
      await until(page, () => document.getElementById('playLive').offsetParent !== null, null, 6000)
      const back = await page.evaluate(() => ({ live: document.getElementById('playLive').offsetParent !== null, same: state.live.lr === window.__heldBefore.lr && JSON.stringify(state.live.scores) === window.__heldBefore.scores }))
      await click(page, '#backToSetup')   /* the capture is the held setup */
      await until(page, () => { const h = document.getElementById('lrHeld'); return !!h && !h.hidden }, null, 6000)
      await page.evaluate(() => window.scrollTo(0, 0))
      return back.live && back.same ? true : 'the way back did not return to the same round: ' + JSON.stringify(back)
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
    check: all(scoredCheck(4), async (page) => { const f = await liveFacts(page); return f.game === 'match' ? true : 'the game is ' + f.game },
      has('#matchMeta', 'THRU 4', 'the match line'),
      /* TEN / W6 · AW2-15: the side games' gloss is a phrase, in sentence case (§1.3) */
      readsAsWritten([['p.eb-gloss.sg-head', 'Tracked live, settled between friends']]),
      /* TEN / W6 · AW2-08: the hole arrows are the drawn chevron */
      noRetiredGlyph(),
      async (page) => {
        const t = await page.evaluate(() => [document.getElementById('sbHero')?.textContent || '', document.getElementById('matchStatus')?.textContent || ''])
        return t[0] && t[0] === t[1] && /UP|SQUARE|WIN/.test(t[0]) ? true : 'the hero does not carry the match state: ' + JSON.stringify(t)
      }) },

  /* Skins, three golfers, through five */
  { family: 'play', id: 'skins-scoring', variant: 'member', title: 'Live round · Skins, three golfers, $2 a skin, through five',
    drive: async (page) => {
      await toSetup(page)
      await pickCourse(page, 'Papago', 'Papago Fixture Links', 'Gold')
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
    check: all(scoredCheck(5), async (page) => { const f = await liveFacts(page); return f.game === 'skins' ? true : 'the game is ' + f.game },
      /* TEN / W6 · DX2 OB2-02: the meta line's caps are its role's, not typed into the string */
      capsFromRole(['#skinsMeta'], ['#skinsMeta'])) },

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
    expect: { view: 'view-play', sheet: '^Finish the round$', selectors: { '#lrPost': 'text:^Post 2 cards to the season$', '#lrCasual': 'visible' } },
    check: async (page) => { const f = await liveFacts(page); return f.holes === 9 ? true : `the round is ${f.holes} holes, expected the nine` } },

  /* Post: finish_live_round answers, the settlement sheet (the ceremony) */
  { family: 'play', id: 'finish', variant: 'member', fullPage: false, title: 'Live round · posted: the round’s settlement (two cards to the season)',
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
    check: all(has('#shSub', '2 CARDS TO THE SEASON', 'the card count'),
      async (page) => { const f = await liveFacts(page); return !f.active ? true : 'the round is still live after the finish' }) },
]
