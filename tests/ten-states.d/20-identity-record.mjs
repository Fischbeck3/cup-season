/* Cup Season · ten-capture states: YOU, THE RECORD, RECEIPTS, THE COMPOSER
 * and THE SHARE ARTIFACT (WX lane, 2026-09-28).
 *
 * On the web the golfer's record lives on the You page (view-stats): the
 * credential, Recent rounds, the trophy case, All time, This season. The
 * router id `record` is the PLAY chooser, not history (the 2026-09-27
 * gallery captured it as History by mistake), so no state here lands on it
 * and calls it the record.
 *
 * Every state is reached through the page's own controls; each check names
 * something unique to the surface. The answers behind them are
 * tests/fixtures/ten/rpc/20-identity-record.mjs (and the world). */
import { mkdirSync } from 'node:fs'
import { notMono, noSerifFigure, readsAsWritten, noRetiredGlyph, standsDown } from '../ten-mono.mjs'

const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const ME = 'f1000000-0000-4000-8000-000000000001'

/* the real door to You: the tab below desk width, the sidebar item on the desk */
async function toYou(page) {
  await page.locator('.tab[data-v="stats"]:visible, .navitem[data-v="stats"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-stats')
}
/* the record's own four-way state (F10): loading | failed | empty | some */
const recordState = (want) => async (page) => page.evaluate((want) => {
  const v = document.getElementById('view-stats')
  const got = v && v.dataset.record
  return got === want ? true : `the record reads ${JSON.stringify(got)}, expected ${JSON.stringify(want)}`
}, want)
const youSettled = (want) => async (page) => {
  await toYou(page)
  await until(page, (want) => (document.getElementById('view-stats') || {}).dataset && document.getElementById('view-stats').dataset.record === want, want, 12000)
  await page.waitForTimeout(600)
}
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const text = (sel, re, what) => async (page) => page.evaluate(({ sel, re, what }) => {
  const el = document.querySelector(sel)
  if (!el) return `${what}: ${sel} is missing`
  return new RegExp(re, 'i').test(el.innerText.replace(/\s+/g, ' ')) ? true : `${what}: ${sel} reads ${JSON.stringify(el.innerText.replace(/\s+/g, ' ').slice(0, 120))}`
}, { sel, re, what })

/* TEN / W8 · W7-055 [X10] · the phone-width You has an index under the card: one row of links (44px tall) to the heads that
   are on the page, drawn only when three or more are, and never at the desk, whose two columns hold the page in one screen.
   `want` is the count that must be drawn (0 = the row is absent). The second link's target lands under the sticky bar. */
const youIndex = (want) => async (page) => page.evaluate(async (want) => {
  const box = document.getElementById('youJump')
  const shown = (el) => !!el && el.getBoundingClientRect().width > 0 && el.getBoundingClientRect().height > 0
  if (innerWidth >= 960) return shown(box) ? 'the desk draws the phone-width index' : true
  const btns = box ? [...box.querySelectorAll('button')].filter(shown) : []
  if (!want) return shown(box) ? `the index is drawn with ${btns.length} link(s), and a row of fewer than three is not` : true
  if (!shown(box) || btns.length !== want) return `the index has ${btns.length} visible link(s), expected ${want}`
  const small = btns.filter((b) => b.getBoundingClientRect().height < 44)
  if (small.length) return `an index link is under 44px tall: ${small[0].textContent}`
  /* the second link: a head near the foot cannot reach the top of a page that ends below it */
  const link = btns[1], target = { Courses: '#youCoursesDoor', Rivalries: '#youRivalsHead', Seasons: '#lgRecHead, #youSeasonHead', Trophies: '#youTrophiesHead', 'Recent rounds': '#youRecentHead' }[link.textContent.trim()]
  if (!target) return `an index link has no target: ${link.textContent}`
  link.click(); await new Promise((r) => setTimeout(r, 300))
  const el = [...document.querySelectorAll(target)].find(shown), top = el ? Math.round(el.getBoundingClientRect().top) : null
  window.scrollTo(0, 0)
  return el && top >= 40 && top <= 100 ? true : `the ${link.textContent.trim()} link scrolled its head to ${top}px, not under the sticky bar`
}, want)

/* TEN / W8 · W7-053 [A2-identity-3, B2-identity-4] · a first round: You does not say 'No rounds count yet' under a figure that says the golfer has
   rounds, and says the number is building. `one` (one round posted, no index yet): the strip's label is singular, its scope line says what
   the best and average wait for, and the building clause stands alone under the card. `many` (an established golfer): the plural label, the
   counting scope, and no clause. `none` (an empty record): no scope line and no clause. */
const youBuilding = (kind) => async (page) => page.evaluate((kind) => {
  const shown = (el) => !!el && !el.hidden && el.getBoundingClientRect().width > 0
  const b = document.getElementById('youBuilding'), scope = document.getElementById('clAvgSub'), row = scope && scope.closest('.youscope')
  const label = document.querySelector('#clR').closest('.youfig').querySelector('small').textContent.trim()
  const said = shown(b) ? b.textContent.trim() : ''
  if (kind === 'one') {
    if (/No rounds count yet/.test(row ? row.textContent : '')) return 'You still says "No rounds count yet" under a figure that says the golfer has rounds'
    if (!shown(row) || scope.textContent.trim() !== 'Best and average start once a round is scored in a season.') return `the scope line reads ${JSON.stringify(scope && scope.textContent.trim())}`
    if (label !== 'Round posted') return `the strip's label reads ${JSON.stringify(label)}`
    return said === 'Two more rounds set your number.' ? true : `the building clause under the card reads ${JSON.stringify(said)}`
  }
  if (kind === 'many') return said === '' && label === 'Rounds posted' && shown(row) && !/Best and average start|No rounds count yet/.test(scope.textContent) ? true : `an established golfer's strip: label ${JSON.stringify(label)}, clause ${JSON.stringify(said)}, scope ${JSON.stringify(scope.textContent)}`
  return said === '' && !shown(row) ? true : `an empty record: clause ${JSON.stringify(said)}, scope line drawn: ${shown(row)}`
}, kind)

/* TEN / W8 · W7-047 [A2-identity-10] · You's Form head is the page's eyebrow with the window in its label ('Form · last five', Q21), a count slot only
   under five rounds ('One of five'), and every column's day is the month and day ('SEP 27', 'SEP 13 · NINE'), the day form the Recent rounds below print */
const youFormGrammar = (slot) => async (page) => page.evaluate((slot) => {
  const head = document.querySelector('#youForm h2.eyebrow')
  if (!head) return "You's Form head is not the eyebrow"
  const t = head.innerText.replace(/\s+/g, ' ').trim()
  if (t !== (slot ? `FORM · LAST FIVE ${slot}` : 'FORM · LAST FIVE')) return `You's Form head reads ${JSON.stringify(t)}`
  const days = [...document.querySelectorAll('#youForm .dfcol small')].map((e) => e.innerText.trim())
  const bad = days.filter((d) => !/^[A-Z]{3} \d{1,2}( · NINE)?$/.test(d))
  return days.length && !bad.length ? true : `the Form columns mix day forms: ${JSON.stringify(days)}`
}, slot)

/* ------------------------------------------------------------------ YOU */
const YOU = [
  { family: 'you', id: 'empty', variant: 'brand_new', title: 'You · a new golfer: carded, no rounds',
    drive: youSettled('empty'), expect: { view: 'view-stats', selectors: { '#youCard': 'visible', '#youName': 'text:^Avery Fixture$' } },
    check: all(recordState('empty'), async (page) => page.evaluate(() => document.querySelectorAll('#youRecent [data-rcpt-i]').length === 0 ? true : 'a round row rendered for a golfer with none'),
      /* TEN / W8 · W7-009: an empty record says the first round is missing and holds the door, so the sidebar's sentence and door stand down */
      standsDown(['#sideMe .mesay', '#sideMe [data-mego="add_round"]']),
      /* TEN / W8 · W7-055: an empty record has one section, so no index */
      youIndex(0), youBuilding('none'),
      /* the sidebar's foot stays pinned to the column's bottom when its block
         stands down: display:none took #sideMe's margin-top:auto with it (B's
         find on 51211947; W7-030's check, col.bottom − foot.bottom ≤ 48) */
      async (page) => page.evaluate(() => {
        if (innerWidth < 960) return true
        const col = document.querySelector('aside.side'), foot = col && col.querySelector('.foot')
        if (!col || !foot) return 'no sidebar foot at the desk'
        const gap = col.getBoundingClientRect().bottom - foot.getBoundingClientRect().bottom
        return gap <= 48 ? true : `the sidebar's foot floats ${Math.round(gap)}px above the column's bottom`
      })) },
  { family: 'you', id: 'one-round', variant: 'one_round', title: 'You · one round posted, the index still building',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youName': 'text:^Avery Fixture$', '#clR': 'text:^1$' } },
    check: all(recordState('some'), async (page) => page.evaluate(() => document.querySelectorAll('#youRecent [data-rcpt-i]').length === 1 ? true : `expected one round row, found ${document.querySelectorAll('#youRecent [data-rcpt-i]').length}`), youBuilding('one'), youFormGrammar('ONE OF FIVE')) },
  { family: 'you', id: 'populated', variant: 'member', title: 'You · a member of two leagues with eight rounds',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youName': 'text:^Avery Fixture$', '#clR': 'text:^8$', '#youRecent [data-rcpt-i]': 'visible' } },
    /* TEN / W6 · AW2-06: a bag slot's name is a label, never mono */
    check: all(recordState('some'), youIndex(5), youBuilding('many'), youFormGrammar(''), notMono(['.bagrow .bslot'], ['.bagrow .bslot']),
      /* TEN / W6 · AW2-15: a recent round's line is a phrase, in sentence case (§1.3) */
      readsAsWritten([['#youRecent .yrow small', '^[A-Z][a-z]+ \\d+ \u00b7 [^A-Z]*vs your playing HCP', true]]),
      /* TEN / W6 · AW2-08: the bag's move controls are drawn marks, never ↑ ↓ ⇄ ✕ */
      noRetiredGlyph()) },
  /* the career read fails both ways (the full select and its skew retry):
     the record must say the READ failed, never "no rounds" (F10) */
  { family: 'you', id: 'error', variant: 'member', title: 'You · the rounds read failed',
    /* a refused read (a grant failure answers 42501), not a 5xx: supabase-js
       retries 5xx reads with backoff, a refusal it does not */
    prepare: async (W) => { W.errors.when = [{ table: 'rounds', match: (q) => /profile_id=eq\./.test(q) && /limit=400/.test(q), error: { __error: 'permission denied for table rounds', status: 403, code: '42501' } }] },
    expectConsole: [/status of 403/, /\[career\]|\[loadCareer\]/],
    /* W7-101 [A2-identity-12] · the page index stands down on a failed read, so
       "Try again" is not pushed under the tab band at 375x667 */
    drive: youSettled('failed'), expect: { view: 'view-stats', selectors: { '#youRecentRetry': 'visible', '#youJump': 'hidden' } },
    check: all(recordState('failed'), text('#youRecent', 'didn.t load', 'the failure line')) },
]

/* ------------------------------------------------------ THE RECORD (photos) */
/* the record section of You, with the round photographs in each state: the
   world gives Avery's latest round a photo (rounds/<me>/<round>.jpg).
   W1 (2026-09-28): the You page draws no round photograph at all — the record
   opens a round's receipt, and that is where its photograph lives (the album
   is the season's, in the league room). So photos-none and photo-broken were
   byte-identical to populated: they captured a page with no photo slot. They
   now open the latest round's receipt from Recent rounds, the record's own
   door, and capture what that photograph slot does in each state. */
/* the real tap: the first Recent rounds row opens its receipt */
async function openLatestReceipt(page) {
  await youSettled('some')(page)
  for (let i = 0; i < 4; i++) {
    await click(page, '#youRecent [data-rcpt-i="0"]').catch(() => {})
    const ok = await page.waitForFunction(() => document.getElementById('sheet').classList.contains('open'), null, { timeout: 2000 }).then(() => true, () => false)
    if (ok) break
  }
  await until(page, () => document.getElementById('sheet').classList.contains('open') && !/LOADING/.test(document.getElementById('shSub').textContent), null, 10000)
}
const heroState = (want) => async (page) => page.evaluate((want) => {
  const h = document.getElementById('rcptHero')
  if (!h) return 'no receipt moment'
  /* TEN / W6 · §10.3: the photograph is an inset 3:2 plate of its own, after
     the league's verdict; the moment's words keep the card's ground */
  const plate = document.getElementById('rcptPlate'), img = plate && !plate.hidden && plate.querySelector(':scope > img')
  const broken = [...document.querySelectorAll('#sheet img')].filter((i) => i.complete && i.naturalWidth === 0 && i.offsetParent !== null)
  if (broken.length) return `${broken.length} broken image(s) are showing`
  if (want === 'photo') {
    if (!img || h.querySelector('.rm-topo') || h.querySelector('img')) return 'the photograph is not on its own plate'
    const p = plate.getBoundingClientRect(), f = document.getElementById('rcptFigs')
    if (Math.abs(p.width / p.height - 1.5) > 0.02) return `the plate is not 3:2 (${Math.round(p.width)}×${Math.round(p.height)})`
    const above = f && !f.hidden ? f.getBoundingClientRect().bottom : h.getBoundingClientRect().bottom
    if (p.top < above - 0.5) return 'the plate sits above the league verdict'
    const ground = getComputedStyle(h).backgroundColor, probe = document.createElement('i')
    probe.style.color = 'var(--bg1)'; h.appendChild(probe); const bg1 = getComputedStyle(probe).color; probe.remove()
    return ground === bg1 ? true : `the moment is not on the card's ground (${ground}, not ${bg1})`
  }
  return !img && !!h.querySelector('.rm-topo') && !h.classList.contains('has-photo') && !!h.querySelector('.rm-fig')
    ? true : 'the moment did not keep its no-photo face: ' + h.className
}, want)
const RECORD = [
  { family: 'record', id: 'populated', variant: 'member', title: 'The record · recent rounds, trophies, all time (a photo on the latest round)',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youRecent': 'visible', '#youRecent [data-rcpt-i]': 'visible' } },
    check: recordState('some') },
  { family: 'record', id: 'photos-none', variant: 'member', world: { photo: 'none' }, fullPage: false,
    title: 'The record · no photographs anywhere: the latest round’s receipt keeps its moment on the contour',
    drive: async (page) => { await openLatestReceipt(page); await page.waitForTimeout(700) },
    expect: { view: 'view-stats', sheet: true, selectors: { '#rcptHero': 'visible' } },
    check: all(recordState('some'), heroState('none'),
      async (page) => page.evaluate(() => document.querySelectorAll('#sheet img[src*="token=fixture"]').length === 0 ? true : 'a photograph rendered with none on file')) },
  /* every signed URL answers 404: the receipt falls back to its no-photo
     moment, never a broken image on the ceremony ground, and — it is the
     owner's own round, and it carries a photograph — says so once beside
     Replace and Remove: "This round’s photo couldn’t be opened." (S9, the
     phone's RoundCopy.photoUnavailable, verbatim) */
  { family: 'record', id: 'photo-broken', variant: 'member', world: { flags: { brokenPhotos: true } }, fullPage: false,
    title: 'The record · the photograph will not load (404): the receipt falls back to its no-photo moment',
    expectConsole: [/status of 404/],
    drive: async (page) => {
      await openLatestReceipt(page)
      await until(page, () => { const h = document.getElementById('rcptHero'), p = document.getElementById('rcptPlate'); return !!h && (!p || p.hidden) && !!h.querySelector('.rm-topo') }, null, 10000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-stats', sheet: true, selectors: { '#rcptHero': 'visible', '#rcptPhotoGone': 'text:^This round\u2019s photo couldn\u2019t be opened\.$' } },
    check: all(recordState('some'), heroState('none')) },
  /* a credited photograph: Blake's avatar on his credential carries the credit
     line "Blake's round · <day>" (csCredentialHtml). Opened from the board's
     own tour-card door, the in-context peek (data-tc). */
  /* W2 (f46086b4, critique-B P1): a golfer's OWN photograph carries no credit —
     "BLAKE'S ROUND" was a provenance the product made up; §10.1 keeps a credit
     only for a round photograph, from that round. The state keeps its id (the
     gallery's history) and now proves the plate shows and the credit is gone. */
  { family: 'record', id: 'photo-credited', variant: 'member', title: 'A golfer’s own photograph · Blake’s card, from the board, uncredited',
    prepare: async (W) => { const b = W.tables.profiles.find((p) => p.id === W.ids.uid(2)); if (b) b.photo_path = `avatars/${b.id}/fixture.jpg` },
    fullPage: false,
    drive: async (page) => {
      await until(page, () => !!(window.avatarUrl && window.avatarUrl['f1000000-0000-4000-8000-000000000002']), null, 12000)
      await page.evaluate(() => window.openTourCard ? window.openTourCard('f1000000-0000-4000-8000-000000000002') : null)
      await until(page, () => document.getElementById('sheet').classList.contains('open') && !!document.querySelector('#shBody .cred'), null, 10000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-home', sheet: true, selectors: { '#shBody .cred .cplate img': 'visible', '#shBody .ccredit': 'hidden' } } },
  /* a withdrawn photograph: the public link Avery withdrew when the photo
     consent changed answers dead -- the photo is gone with it */
  { family: 'record', id: 'photo-withdrawn', variant: 'signed_out', url: '/?share=fe200000-0000-4000-8000-000000000004',
    title: 'A withdrawn photograph · its public link now reads dead',
    settle: async (page) => { await page.waitForSelector('#shareView', { timeout: 15000 }); await until(page, () => !/Opening the card/.test((document.getElementById('svCard') || {}).textContent || ''), null, 15000); await page.waitForTimeout(400) },
    expect: { overlay: true, selectors: { '#svCard': 'text:This link is dead' } },
    check: async (page) => page.evaluate(() => document.querySelectorAll('#shareView img').length === 0 ? true : 'an image is still on the withdrawn card') },
]

/* ------------------------------------------------------------ RECEIPTS */
const RECEIPT = [
  /* the round receipt, from the first Recent rounds row (the real tap) */
  /* W1 (2026-09-28): the league's verdict (points, league, the month) sits
     directly under the moment now, so this first-screen capture reaches it —
     it used to stop at the photo buttons and the card */
  { family: 'receipt', id: 'round', variant: 'member', fullPage: false, title: 'Round receipt · opened from Recent rounds',
    drive: async (page) => {
      await openLatestReceipt(page)
      await until(page, () => { const f = document.getElementById('rcptFigs'); return !!f && !f.hidden }, null, 10000).catch(() => {})
      await page.waitForTimeout(700)
    },
    expect: { view: 'view-stats', sheet: true, selectors: { '#rcptFigs': 'visible', '#rcptFigs .lens': 'text:Counting #' } },
    check: all(heroState('photo'),
      /* S9 · a picture that is showing says nothing */
      async (page) => page.evaluate(() => { const g = document.getElementById('rcptPhotoGone'); return !g || g.hidden ? true : 'the photo-unavailable line shows over a photo that loaded' }),
      async (page) => page.evaluate(() => {
      const t = document.getElementById('shBody').innerText.replace(/\s+/g, ' ')
      if (!(/\b84\b/.test(document.getElementById('sheet').innerText) && /Mesquite Wash/i.test(document.getElementById('sheet').innerText))) return 'the receipt does not show the 84 at Mesquite Wash: ' + t.slice(0, 160)
      const f = document.getElementById('rcptFigs').getBoundingClientRect()
      if (f.bottom > innerHeight) return 'the league verdict is below the first screen (' + Math.round(f.bottom) + ' > ' + innerHeight + ')'
      if (/\bgross\b/i.test(document.getElementById('shTitle').textContent)) return 'the sheet title repeats the figure: ' + document.getElementById('shTitle').textContent
      return true
    }),
    /* TEN / W6 · AW2-06: a math row's label is body and the words in its value
       are agateS; only the figures keep mono, in the column role (§1.4) */
    notMono(['#rcptBody .mathrow > span', '#rcptBody .mathrow .mw', '#rcptHero .rm-tag'], ['#rcptBody .mathrow > span', '#rcptBody .mathrow .mw', '#rcptHero .rm-tag']),
    /* TEN / W6 · AW2-07: the moment's sentence sets its figure as a run (vsPhraseMarked), never the serif */
    noSerifFigure(['#rcptHero .rm-say'], ['#rcptHero .rm-say .cfrun']),
    noRetiredGlyph()) },
  /* TEN / W8 · W7-034 [B2-history-8] · the receipt's leaf, scrolled to: one label case in it (UI_SYSTEM §1.3). The working's labels
     ('Your index that day', 'Playing HCP') took the sheet subtitle's caps by inheritance and sat beside 'The course' and
     'Points' in sentence case; every label in the leaf is a phrase now. */
  { family: 'receipt', id: 'round-leaf', variant: 'member', fullPage: false, title: 'Round receipt · scrolled to the leaf (the working and the verdict, one label case)',
    drive: async (page) => {
      await openLatestReceipt(page)
      await until(page, () => { const f = document.getElementById('rcptFigs'); return !!f && !f.hidden }, null, 10000).catch(() => {})
      await page.evaluate(() => document.querySelector('.rcpt-leaf').scrollIntoView({ block: 'center' }))
      await page.waitForTimeout(600)
    },
    expect: { view: 'view-stats', sheet: true, selectors: { '.rcpt-leaf': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const labels = [...document.querySelectorAll('.rcpt-leaf .mathrow > span:first-child')].filter((e) => e.getBoundingClientRect().width > 0).map((e) => e.innerText.replace(/\s+/g, ' ').trim())
      if (labels.length < 4) return `the leaf has ${labels.length} labels`
      const shouted = labels.filter((l) => /[A-Za-z]{4,}/.test(l) && l === l.toUpperCase())
      return shouted.length ? `the leaf mixes label cases: ${JSON.stringify(shouted)} in caps beside ${JSON.stringify(labels.filter((l) => !shouted.includes(l)).slice(0, 2))}` : true
    }) },
  /* S9 (W1, 2026-09-28) · the owner's receipt of a round that carries a
     photograph the page cannot open (every signed URL answers 404): the
     moment falls back, and the photo row says it once, beside Replace and
     Remove — "This round’s photo couldn’t be opened." — the phone's
     RoundCopy.photoUnavailable, verbatim. Scrolled to the photo row, which
     sits under the verdict, the receipt and the card. */
  { family: 'receipt', id: 'photo-unavailable', variant: 'member', world: { flags: { brokenPhotos: true } }, fullPage: false,
    title: 'Round receipt · the photograph could not be opened (the owner is told once, beside Replace and Remove)',
    expectConsole: [/status of 404/],
    drive: async (page) => {
      await openLatestReceipt(page)
      await until(page, () => { const g = document.getElementById('rcptPhotoGone'); return !!g && !g.hidden }, null, 10000)
      await page.evaluate(() => document.getElementById('rcptPhotoRow').scrollIntoView({ block: 'center' }))
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-stats', sheet: true, selectors: { '#rcptPhotoGone': 'text:^This round\u2019s photo couldn\u2019t be opened\.$', '#rcptPhotoBtn': 'visible', '#rcptPhotoClear': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const g = document.getElementById('rcptPhotoGone').getBoundingClientRect()
      if (g.top < 0 || g.bottom > innerHeight) return 'the line is not on screen'
      const f = getComputedStyle(document.getElementById('rcptPhotoGone')).fontFamily
      return /mono/i.test(f) ? 'the line is set in mono: ' + f : true
    }) },
  /* the points receipt (§16): the squad row on the season's own standings
     opens the squad math */
  { family: 'receipt', id: 'points', variant: 'member', fullPage: false, title: 'Points receipt · the squad math, from the standings row',
    drive: async (page) => {
      await page.evaluate(() => window.switchView('hub'))
      await until(page, () => !!document.querySelector('#view-hub [data-squad]'), null, 12000)
      await page.waitForTimeout(500)
      for (let i = 0; i < 4; i++) {
        await page.locator('#view-hub [data-squad]').first().click({ timeout: 5000 }).catch(() => {})
        const ok = await page.waitForFunction(() => document.getElementById('sheet').classList.contains('open'), null, { timeout: 2000 }).then(() => true, () => false)
        if (ok) break
      }
      await page.waitForTimeout(700)
    },
    expect: { view: 'view-hub', sheet: 'Fixture (Wrens|Javelinas)' },
    check: all(async (page) => page.evaluate(() => /\d+\s*(pts|points)/i.test(document.getElementById('sheet').innerText) ? true : 'the squad receipt shows no points figure'),
      /* TEN / W6 · AW2-06: the squad math's labels are body, never mono */
      notMono(['#shBody .mathrow > span'], ['#shBody .mathrow > span']),
      /* TEN / W8 · W7-031 [B2-history-3]: the first row is points, not a count of rounds, and every term of the foot's formula
         (rounds that count + bonuses & penalties) is on the sheet: with an empty ledger the second is a row at 0 */
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#shBody .mathrow')].map((r) => [r.children[0].textContent.trim(), r.children[1].textContent.trim()])
        if (rows.length < 3) return `the squad math has ${rows.length} rows`
        if (rows[0][0] !== 'Points from rounds that count') return `the first row is ${JSON.stringify(rows[0][0])}`
        if (rows[rows.length - 1][0] !== 'Total') return 'the last row is not the Total'
        const middle = rows.slice(1, -1)
        if (!middle.length) return 'nothing stands between the rounds and the Total, though the foot names bonuses & penalties'
        return true
      })) },
]

/* ------------------------------------------------------------ COMPOSER */
/* the real door: the Play tab (router id `record`), then "Add a round you played" */
async function toComposer(page) {
  await page.locator('.tab[data-v="record"]:visible, .navitem[data-v="record"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-record')
  await click(page, '#view-record [data-go="post"]')
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-post')
  await page.waitForTimeout(700)
}
/* fill the card through the real inputs: course, rating, slope, date, the
   two nines. The inherit line may already hold the last course. */
async function fillCard(page, { course = 'Saguaro Flats Municipal (fixture) · Blue', rating = '70.1', slope = '121', f9 = '42', b9 = '41', date = '2026-09-27' } = {}) {
  const folded = await page.evaluate(() => { const f = document.getElementById('postCardFold'); return !f || f.offsetParent === null || getComputedStyle(f).display === 'none' })
  if (folded) await click(page, '#postInherit').catch(() => {})
  await page.fill('#inCourse', course)
  await page.fill('#inRating', rating)
  await page.fill('#inSlope', slope)
  await page.fill('#inDate', date).catch(() => {})
  await page.fill('#inF9', f9)
  await page.fill('#inB9', b9)
  await page.locator('#inB9').press('Tab').catch(() => {})
  await page.waitForTimeout(400)
}
/* TEN / W6 · noCourse, read the way noRating is: blocked on the course, no
   preview, focus on the course field (marked and described), the ruling's
   words under it and on screen */
const NO_COURSE = 'Add the course you played \u2014 its tee sets the rating and slope.'
const courseBlocked = async (page) => page.evaluate((words) => {
  if (state.postBlocked !== 'course') return 'the card is not blocked on its course: ' + state.postBlocked
  if (document.getElementById('calcPts').textContent.trim() !== '\u2013') return 'a card with no course previewed points'
  const a = document.activeElement
  if (!a || a.id !== 'inCourse') return 'focus is not on the course field: ' + (a && (a.id || a.tagName))
  if (a.offsetParent === null) return 'the course field is folded away'
  if (a.getAttribute('aria-invalid') !== 'true' || a.getAttribute('aria-describedby') !== 'postCourseErr') return 'the course field is not marked and described'
  const e = document.getElementById('postCourseErr')
  if (e.textContent !== words) return 'the words are not the ruling\u2019s: ' + JSON.stringify(e.textContent)
  const w = e.getBoundingClientRect()
  return w.top >= 0 && w.bottom <= innerHeight ? true : 'the words are off screen from the field they name'
}, NO_COURSE)
const COMPOSER = [
  { family: 'composer', id: 'first-round', variant: 'brand_new', short: true, title: 'Composer · a first round, no league',
    drive: toComposer, expect: { view: 'view-post', selectors: { '#inGross': 'visible', '#postBtn': 'visible', '#postEyebrow': 'text:index builds' } } },
  /* TEN / W6 · critique A2 (P1), then root's noCourse ruling (2026-09-29): a
     first round's gross, then Add my round, with no course yet. The guidance
     never points at a folded field and never leaves on a toast: the fold
     opens, the course field takes focus (marked), and the ruling's sentence
     stands right under it (#postCourseErr, which describes the field). The
     order is noCard → noCourse → noRating, as PostCalc.Blocked has it. */
  { family: 'composer', id: 'first-round-blocked', variant: 'brand_new', title: 'Composer · a first round’s gross and Add my round, with no course yet (the fold opens on the course)',
    drive: async (page) => {
      await toComposer(page)
      await page.locator('#inGross').fill('88')
      await page.waitForTimeout(300)
      await click(page, '#postBtn')
      await until(page, () => { const e = document.getElementById('postCourseErr'); return !!e && !e.hidden }, null, 6000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-post', selectors: { '#postCardFold': 'visible', '#postCourseErr': 'text:^Add the course you played — its tee sets the rating and slope\\.$', '#postRateErr': 'hidden' } },
    check: courseBlocked },
  /* the same card on an empty MEMBER composer: no course picked, none typed */
  { family: 'composer', id: 'member-no-course', variant: 'member', title: 'Composer · a member’s gross and Add my round, with no course (noCourse)',
    drive: async (page) => {
      await toComposer(page)
      await page.locator('#inGross').fill('84')
      await page.waitForTimeout(300)
      await click(page, '#postBtn')
      await until(page, () => { const e = document.getElementById('postCourseErr'); return !!e && !e.hidden }, null, 6000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-post', selectors: { '#postCardFold': 'visible', '#postCourseErr': 'text:^Add the course you played — its tee sets the rating and slope\\.$' } },
    check: courseBlocked },
  /* a tee picked from the course search: the course, the rating and the slope
     arrive together, so nothing blocks and the preview scores the card */
  { family: 'composer', id: 'tee-picked', variant: 'member', title: 'Composer · a gross and a tee picked from the course search (no block)',
    drive: async (page) => {
      await toComposer(page)
      await page.locator('#inGross').fill('84')
      await page.evaluate(() => { if (typeof togglePostFold === 'function') togglePostFold(true) })
      await page.locator('#inCourse').click()
      await page.locator('#inCourse').fill('Saguaro')
      await until(page, () => [...document.querySelectorAll('.coursedd [data-ci]')].some((b) => b.textContent.includes('Saguaro Flats')), null, 10000)
      await page.locator('.coursedd [data-ci]', { hasText: 'Saguaro Flats' }).first().click()
      await until(page, () => document.querySelectorAll('.coursedd [data-ti]').length > 0)
      await page.locator('.coursedd [data-ti]', { hasText: 'Blue' }).first().click()
      await until(page, () => document.getElementById('inRating').value !== '' && document.getElementById('inSlope').value !== '')
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-post', selectors: { '#postCardFold': 'visible', '#postCourseErr': 'hidden' } },
    check: async (page) => page.evaluate(() => {
      const pts = document.getElementById('calcPts').textContent.trim()
      return state.postBlocked === null && pts !== '–' && pts !== '' ? true : 'a picked tee still blocks the card: ' + JSON.stringify({ blocked: state.postBlocked, pts })
    }) },
  /* TEN / W6 · root's ruling (the phone's IOS-030 guard): a hand-typed course
     with the rating in and the slope EMPTY previews nothing — it previewed
     points at a standard 113 the record never stores — and Post marks the
     slope, the field the words name */
  { family: 'composer', id: 'rating-no-slope', variant: 'brand_new', title: 'Composer · a hand-typed course with the rating in and the slope empty (noRating: no preview; Post marks the slope)',
    drive: async (page) => {
      await toComposer(page)
      await page.locator('#inGross').fill('88')
      await page.evaluate(() => { if (typeof togglePostFold === 'function') togglePostFold(true) })
      /* a course the catalogue lacks, typed by hand: past noCourse to noRating */
      await page.locator('#inCourse').fill('Fixture Muni (typed)')
      await page.keyboard.press('Escape').catch(() => {})
      await page.locator('#inRating').fill('70.1')
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-post', selectors: { '#postCardFold': 'visible', '#calcMsg': 'text:Pick a tee — or type the rating and slope — to see the points\\.' } },
    check: async (page) => {
      const preview = await page.evaluate(() => ({ pts: document.getElementById('calcPts').textContent.trim(), blocked: state.postBlocked }))
      if (preview.pts !== '–' || preview.blocked !== 'rating') return 'an empty slope previewed points: ' + JSON.stringify(preview)
      await click(page, '#postBtn')
      await until(page, () => { const e = document.getElementById('postRateErr'); return !!e && !e.hidden }, null, 6000)
      return page.evaluate(() => {
        const a = document.activeElement
        return a && a.id === 'inSlope' && a.getAttribute('aria-invalid') === 'true' && a.getAttribute('aria-describedby') === 'postRateErr' ? true : 'Post did not mark the slope: ' + (a && a.id)
      })
    } },
  { family: 'composer', id: 'member', variant: 'member', short: true, title: 'Composer · a league member (the inherit line holds the last course)',
    drive: toComposer, expect: { view: 'view-post', selectors: { '#inGross': 'visible', '#postBtn': 'visible', '#postEyebrow': 'text:your index 14\\.2' } },
    /* TEN / W6 · AW2-17: the primary's type is the token's own (bg0 on act), never a typed hex */
    check: async (page) => page.evaluate(() => {
      const i = document.createElement('i'); i.style.color = 'var(--bg0)'; document.body.appendChild(i); const bg0 = getComputedStyle(i).color; i.remove()
      const c = getComputedStyle(document.getElementById('postBtn')).color
      return c === bg0 ? true : `Add my round's type is ${c}, not --bg0 ${bg0}`
    }) },
  { family: 'composer', id: 'filled', variant: 'member', title: 'Composer · a full card entered, before Post',
    drive: async (page) => { await toComposer(page); await fillCard(page) },
    expect: { view: 'view-post', selectors: { '#postBtn': 'visible' } },
    check: async (page) => page.evaluate(() => document.getElementById('inF9').value === '42' && document.getElementById('inB9').value === '41' ? true : 'the card did not take the nines') },
  /* the server refuses the card: the golfer is told nothing posted and the
     card stays on the form.
     W1 (2026-09-28): the refusal is no longer a 2.4 s toast. It stays inline
     above the button (#postErr, role=alert), the button is described by it,
     and focus stays on the button (it used to fall to <body>). The state waits
     for that line instead of the toast. */
  { family: 'composer', id: 'post-failed', variant: 'member', title: 'Composer · the post is refused by the server',
    world: { errors: { rpc: { post_round_once: { __error: 'fixture: the server refused this card', status: 400, code: 'P0001' } } } },
    expectConsole: [/status of 400/, /\[cs\] error:.*refused/i],
    drive: async (page) => {
      await toComposer(page); await fillCard(page)
      await click(page, '#postBtn')
      await until(page, () => { const e = document.getElementById('postErr'); return !!e && !e.hidden && /nothing was posted/i.test(e.textContent || '') }, null, 10000)
      await page.waitForTimeout(250)
    },
    expect: { view: 'view-post', selectors: { '#postErr': 'text:nothing was posted' } },
    check: async (page) => page.evaluate(() => {
      if (document.getElementById('inF9').value !== '42') return 'the card was cleared after a refused post'
      const b = document.getElementById('postBtn')
      if (document.activeElement !== b) return 'focus left the button: ' + (document.activeElement && (document.activeElement.id || document.activeElement.tagName))
      if (b.getAttribute('aria-describedby') !== 'postErr') return 'the button is not described by the refusal'
      if (/press Post again/i.test(document.getElementById('postErr').textContent)) return 'the refusal names a button that is not there'
      return true
    }) },
]

/* ------------------------------------------------------- SHARE ARTIFACT */
/* post a real card, land on the finish ceremony, press Share: the product
   draws the recap card and, with no share sheet in a browser tab, DOWNLOADS
   it -- that PNG is the artifact. The harness saves it beside the capture. */
/* the photo variant draws a synthetic "FIXTURE PHOTO" in the page and hands
   it to the composer's own file input -- never a real photograph */
function shareState(id, title, card, extra = {}) {
  return {
    family: 'share', id, variant: 'member', fullPage: false, title,
    drive: async (page, ctx) => {
      await toComposer(page)
      if (extra.photo) {
        await page.setInputFiles('#postPhotoFile', { name: 'fixture-photo.png', mimeType: 'image/png', buffer: await page.evaluate(() => new Promise((res) => {
          const c = document.createElement('canvas'); c.width = 1200; c.height = 800; const g = c.getContext('2d')
          const gr = g.createLinearGradient(0, 0, 1200, 800); gr.addColorStop(0, '#4f6b3a'); gr.addColorStop(1, '#23321c'); g.fillStyle = gr; g.fillRect(0, 0, 1200, 800)
          g.strokeStyle = 'rgba(255,255,255,.2)'; g.lineWidth = 3; for (let i = 0; i < 8; i++) { g.beginPath(); g.ellipse(760, 330, 80 + i * 70, 50 + i * 44, 0, 0, Math.PI * 2); g.stroke() }
          g.fillStyle = 'rgba(255,255,255,.55)'; g.font = '44px Helvetica'; g.fillText('FIXTURE PHOTO', 60, 740)
          c.toBlob((b) => b.arrayBuffer().then((ab) => res(Array.from(new Uint8Array(ab)))), 'image/png')
        })).then((a) => Buffer.from(a)) })
        await until(page, () => { const i = document.getElementById('postPhotoImg'); return !!i && i.offsetParent !== null && (i.src || i.style.backgroundImage) }, null, 8000).catch(() => {})
      }
      await fillCard(page, card)
      await click(page, '#postBtn')
      await until(page, () => document.getElementById('finish').classList.contains('open'), null, 12000)
      await page.waitForTimeout(600)
      const dir = `${ctx.out}/artifacts`
      mkdirSync(dir, { recursive: true })
      const [dl] = await Promise.all([page.waitForEvent('download', { timeout: 15000 }), click(page, '#finShare')])
      const file = `${dir}/share--${id}--${ctx.vp.width}x${ctx.vp.height}--${ctx.theme}.png`
      await dl.saveAs(file)
      ctx.artifacts.push(file)
      await page.evaluate((f) => { window.__tenArtifact = f }, file)
      await page.waitForTimeout(300)
    },
    /* the ceremony is a full-screen dialog over Home (the post returns there) */
    expect: { view: 'view-home', selectors: { '#finish.open': 'visible', '#finShare': 'visible' } },
    /* TEN / W6 · D380: the ceremony's one Share sends the card AND the round's
       link, and says so under its own button (a toast or a sheet would paint
       beneath the curtain). The card-only path says "Card downloaded" and never
       "link", so a status line naming the link is the proof the link left. */
    check: async (page) => {
      /* the epilogue renders behind the curtain once the post settles */
      await until(page, () => !!document.getElementById('epiRevokeWrap'), null, 10000).catch(() => {})
      return page.evaluate(() => {
        if (!window.__tenArtifact) return 'the card was not downloaded'
        const said = (document.getElementById('finStatus')?.textContent || '').trim()
        if (!/link/i.test(said)) return 'the ceremony shared no link (D380): ' + JSON.stringify(said)
        /* TEN / W7-006 [B2-share-1] · ONE Share per posted round: the epilogue
           behind the curtain offers no second Share and no second, ticked
           photo question; and the ceremony's switch says what a yes
           publishes, directly under it, in the ceremony's quiet voice */
        if (!document.getElementById('epiRevokeWrap')) return 'the epilogue never rendered behind the ceremony'
        if (document.getElementById('epiShare') || document.getElementById('epiPhotoOk')) return 'the epilogue offers a second Share (and photo question) behind the ceremony'
        const po = document.getElementById('finPhoto'), ff = document.getElementById('finFine')
        if (!ff) return 'the ceremony draws no fine print'
        if (po && !po.hidden) {
          if (ff.hidden || ff.textContent !== window.CS_SHARE_PHOTO_FINE) return 'the photo switch prints no fine print: ' + JSON.stringify(ff.hidden ? null : ff.textContent)
          if (po.nextElementSibling !== ff || po.getAttribute('aria-describedby') !== 'finFine') return 'the fine print is not directly under, and describing, the switch'
          const probe = document.createElement('span'); probe.style.color = 'var(--ceremony-mut)'; ff.parentElement.appendChild(probe)
          const mut = getComputedStyle(probe).color; probe.remove()
          if (getComputedStyle(ff).color !== mut) return 'the fine print is not ceremony-mut: ' + getComputedStyle(ff).color
        } else if (!ff.hidden) return 'fine print with no switch to explain'
        return true
      }).then(async (r) => {
        if (r !== true) return r
        /* TEN / W7-140 [A2-share-5] · a tap on the ceremony's empty field leaves
           it open: its exits are "Back to the board" and Escape, as it draws them */
        const hit = await page.evaluate(() => (document.elementFromPoint(6, 6) || {}).id)
        if (hit !== 'finish') return `the backdrop probe did not land on the ceremony's field: ${hit}`
        await page.mouse.click(6, 6)
        await page.waitForTimeout(300)
        return page.evaluate(() => document.getElementById('finish').classList.contains('open') ? true : 'a tap on the empty field ended the ceremony')
      })
    },
    ...extra,
  }
}
const SHARE = [
  shareState('recap-no-photo', 'Share · the recap card for a posted 83 (no photo)', {}),
  shareState('recap-photo', 'Share · the recap card carrying the round photograph', {}, { photo: true }),
  shareState('recap-long-course', 'Share · the recap card, the longest course and tee', { course: 'The Championship Course at Whispering Fixture Pines Country Club · Tournament Tips (Championship Black)', rating: '73.4', slope: '138', f9: '44', b9: '45' }),
]

export default [...YOU, ...RECORD, ...RECEIPT, ...COMPOSER, ...SHARE]
