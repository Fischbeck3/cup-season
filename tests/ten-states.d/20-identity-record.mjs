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

/* ------------------------------------------------------------------ YOU */
const YOU = [
  { family: 'you', id: 'empty', variant: 'brand_new', title: 'You · a new golfer: carded, no rounds',
    drive: youSettled('empty'), expect: { view: 'view-stats', selectors: { '#youCard': 'visible', '#youName': 'text:^Avery Fixture$' } },
    check: all(recordState('empty'), async (page) => page.evaluate(() => document.querySelectorAll('#youRecent [data-rcpt-i]').length === 0 ? true : 'a round row rendered for a golfer with none')) },
  { family: 'you', id: 'one-round', variant: 'one_round', title: 'You · one round posted, the index still building',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youName': 'text:^Avery Fixture$', '#clR': 'text:^1$' } },
    check: all(recordState('some'), async (page) => page.evaluate(() => document.querySelectorAll('#youRecent [data-rcpt-i]').length === 1 ? true : `expected one round row, found ${document.querySelectorAll('#youRecent [data-rcpt-i]').length}`)) },
  { family: 'you', id: 'populated', variant: 'member', title: 'You · a member of two leagues with eight rounds',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youName': 'text:^Avery Fixture$', '#clR': 'text:^8$', '#youRecent [data-rcpt-i]': 'visible' } },
    check: recordState('some') },
  /* the career read fails both ways (the full select and its skew retry):
     the record must say the READ failed, never "no rounds" (F10) */
  { family: 'you', id: 'error', variant: 'member', title: 'You · the rounds read failed',
    /* a refused read (a grant failure answers 42501), not a 5xx: supabase-js
       retries 5xx reads with backoff, a refusal it does not */
    prepare: async (W) => { W.errors.when = [{ table: 'rounds', match: (q) => /profile_id=eq\./.test(q) && /limit=400/.test(q), error: { __error: 'permission denied for table rounds', status: 403, code: '42501' } }] },
    expectConsole: [/status of 403/, /\[career\]|\[loadCareer\]/],
    drive: youSettled('failed'), expect: { view: 'view-stats', selectors: { '#youRecentRetry': 'visible' } },
    check: all(recordState('failed'), text('#youRecent', 'didn.t load', 'the failure line')) },
]

/* ------------------------------------------------------ THE RECORD (photos) */
/* the record section of You, with the round photographs in each state: the
   world gives Avery's latest round a photo (rounds/<me>/<round>.jpg) */
const RECORD = [
  { family: 'record', id: 'populated', variant: 'member', title: 'The record · recent rounds, trophies, all time (a photo on the latest round)',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youRecent': 'visible', '#youRecent [data-rcpt-i]': 'visible' } },
    check: recordState('some') },
  { family: 'record', id: 'photos-none', variant: 'member', world: { photo: 'none' }, title: 'The record · no photographs anywhere',
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youRecent': 'visible' } },
    check: all(recordState('some'), async (page) => page.evaluate(() => document.querySelectorAll('#view-stats img[src*="token=fixture"]').length === 0 ? true : 'a photograph rendered with none on file')) },
  /* every signed URL answers 404: the record must fall back, never show a broken image */
  { family: 'record', id: 'photo-broken', variant: 'member', world: { flags: { brokenPhotos: true } }, title: 'The record · the photograph will not load (404)',
    expectConsole: [/status of 404/],
    drive: youSettled('some'), expect: { view: 'view-stats', selectors: { '#youRecent': 'visible' } },
    check: all(recordState('some'), async (page) => page.evaluate(() => {
      const broken = [...document.querySelectorAll('#view-stats img')].filter((i) => i.complete && i.naturalWidth === 0 && i.offsetParent !== null)
      return broken.length === 0 ? true : `${broken.length} broken image(s) are showing`
    })) },
  /* a credited photograph: Blake's avatar on his credential carries the credit
     line "Blake's round · <day>" (csCredentialHtml). Opened from the board's
     own tour-card door, the in-context peek (data-tc). */
  { family: 'record', id: 'photo-credited', variant: 'member', title: 'A credited photograph · Blake’s card, from the board',
    prepare: async (W) => { const b = W.tables.profiles.find((p) => p.id === W.ids.uid(2)); if (b) b.photo_path = `avatars/${b.id}/fixture.jpg` },
    fullPage: false,
    drive: async (page) => {
      await until(page, () => !!(window.avatarUrl && window.avatarUrl['f1000000-0000-4000-8000-000000000002']), null, 12000)
      await page.evaluate(() => window.openTourCard ? window.openTourCard('f1000000-0000-4000-8000-000000000002') : null)
      await until(page, () => document.getElementById('sheet').classList.contains('open') && !!document.querySelector('#shBody .cred'), null, 10000)
      await page.waitForTimeout(500)
    },
    expect: { view: 'view-home', sheet: true, selectors: { '#shBody .cred .cplate img': 'visible', '#shBody .ccredit': 'text:^Blake.s round' } } },
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
  { family: 'receipt', id: 'round', variant: 'member', fullPage: false, title: 'Round receipt · opened from Recent rounds',
    drive: async (page) => {
      await youSettled('some')(page)
      for (let i = 0; i < 4; i++) {
        await click(page, '#youRecent [data-rcpt-i="0"]').catch(() => {})
        const ok = await page.waitForFunction(() => document.getElementById('sheet').classList.contains('open'), null, { timeout: 2000 }).then(() => true, () => false)
        if (ok) break
      }
      await until(page, () => document.getElementById('sheet').classList.contains('open') && !/LOADING/.test(document.getElementById('shSub').textContent), null, 10000)
      await page.waitForTimeout(700)
    },
    expect: { view: 'view-stats', sheet: true },
    check: async (page) => page.evaluate(() => {
      const t = document.getElementById('shBody').innerText.replace(/\s+/g, ' ')
      return /\b84\b/.test(document.getElementById('sheet').innerText) && /Mesquite Wash/i.test(document.getElementById('sheet').innerText) ? true : 'the receipt does not show the 84 at Mesquite Wash: ' + t.slice(0, 160)
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
    check: async (page) => page.evaluate(() => /\d+\s*(pts|points)/i.test(document.getElementById('sheet').innerText) ? true : 'the squad receipt shows no points figure') },
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
const COMPOSER = [
  { family: 'composer', id: 'first-round', variant: 'brand_new', short: true, title: 'Composer · a first round, no league',
    drive: toComposer, expect: { view: 'view-post', selectors: { '#inGross': 'visible', '#postBtn': 'visible', '#postEyebrow': 'text:index builds' } } },
  { family: 'composer', id: 'member', variant: 'member', short: true, title: 'Composer · a league member (the inherit line holds the last course)',
    drive: toComposer, expect: { view: 'view-post', selectors: { '#inGross': 'visible', '#postBtn': 'visible', '#postEyebrow': 'text:your index 14\\.2' } } },
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
    check: async (page) => page.evaluate(() => window.__tenArtifact ? true : 'the card was not downloaded'),
    ...extra,
  }
}
const SHARE = [
  shareState('recap-no-photo', 'Share · the recap card for a posted 83 (no photo)', {}),
  shareState('recap-photo', 'Share · the recap card carrying the round photograph', {}, { photo: true }),
  shareState('recap-long-course', 'Share · the recap card, the longest course and tee', { course: 'The Championship Course at Whispering Fixture Pines Country Club · Tournament Tips (Championship Black)', rating: '73.4', slope: '138', f9: '44', b9: '45' }),
]

export default [...YOU, ...RECORD, ...RECEIPT, ...COMPOSER, ...SHARE]
