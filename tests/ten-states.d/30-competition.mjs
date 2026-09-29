/* Cup Season · ten-capture states: COMPETITION (WX lane, helper WX-C2,
 * 2026-09-28).
 *
 *   season/*    the season page (view-hub): its head, the table, the story,
 *               the money (a member and the Pro), the rules
 *   compete/*   the Compete destination, with nothing running and populated
 *   book/*      the Scoreboard and the Book (D381): each synthetic envelope
 *               ADOPTED into the world (rpc/30 adoptBook), opened through the
 *               page's own door, plus the Cup Final race, the failed read and
 *               a cell's receipt
 *   events/*    the event room: a live Ryder, a finished one, an id that does
 *               not resolve, and a read that fails
 *
 * Every state is reached through the page's own controls (the tab bar or the
 * sidebar, the Scoreboard band, the season's jump row, the Book door, the
 * Book's own selects and cells, Compete's peer rows) or its own router
 * (setRoomSeg / switchView('pot') where the desk has no control,
 * window.openEvent for an id nobody can tap). Every check names the surface
 * that must be showing; a fall-through to the Door, Home or a blank pane fails.
 *
 * The answers behind these states: tests/fixtures/ten/rpc/30-competition.mjs. */
import { readFileSync } from 'node:fs'
import { readBook, adoptBook, cupFinalOn, ryderWorld, ids } from '../fixtures/ten/rpc/30-competition.mjs'
import { notMono, noSerifFigure, noRetiredGlyph, readsAsWritten, noRetiredShape, onceInView, armedDelete, capsFromRole, stateContrast, headGap } from '../ten-mono.mjs'

/* local twins of ten-states.mjs `helpers` (importing that module from here
   would be a cycle through its top-level await) */
const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const activeView = (page) => page.evaluate(() => (document.querySelector('.view.active') || {}).id || null)

/* ------------------------------------------------------------ navigation */
/* the destination's real control: the tab below desk width, the sidebar item at it */
async function tapNav(page, v) {
  await page.locator(`.tab[data-v="${v}"]:visible, .navitem[data-v="${v}"]:visible`).first().click({ timeout: 8000 })
  await until(page, (v) => (document.querySelector('.view.active') || {}).id === 'view-' + v, v)
}
/* a list that re-renders under the tap (a second read landing) takes the
   click on a detached node: tap again until the destination answers */
async function tapUntil(page, sel, done, arg, tries = 6) {
  for (let i = 0; i < tries; i++) {
    await page.locator(sel).first().click({ timeout: 4000 }).catch(() => {})
    const ok = await page.waitForFunction(done, arg, { timeout: 1500 }).then(() => true, () => false)
    if (ok) return true
    await page.waitForTimeout(300)
  }
  return page.waitForFunction(done, arg, { timeout: 4000 }).then(() => true)
}
/* Compete, painted: the list has drawn its rows (or its empty root) */
async function toCompete(page) {
  await tapNav(page, 'compete')
  await until(page, () => { const b = document.getElementById('cmpList'); return !!b && !!b.querySelector('[data-cband], .peerrow, .emptyroot') }, null, 10000)
  await page.waitForTimeout(400)
}
/* the season page from Compete's Scoreboard band -- the same arrival Home's
   season item takes (csOpenSeason) */
async function toSeasonViaBand(page) {
  await toCompete(page)
  await tapUntil(page, '#cmpList [data-cband]', () => (document.querySelector('.view.active') || {}).id === 'view-hub')
  await until(page, () => !!(document.getElementById('seasonTitle') || {}).textContent && document.querySelectorAll('#standings tr').length > 0, null, 10000)
  await page.waitForTimeout(500)
}
/* a scroll the page started (setRoomSeg's smooth scrollIntoView) has landed */
async function scrollSettled(page) {
  let last = -1
  for (let i = 0; i < 30; i++) {
    const y = await page.evaluate(() => Math.round(window.scrollY))
    if (y === last) return y
    last = y
    await page.waitForTimeout(150)
  }
  return last
}
const isDesk = (page) => page.evaluate(() => matchMedia('(min-width: 960px)').matches)
/* the season's rooms: the jump row below desk width (MW-04), the sidebar
   list or the router at it -- the same setRoomSeg either way */
async function toRoom(page, room) {
  await toSeasonViaBand(page)
  if (!(await isDesk(page))) {
    await until(page, (r) => !!document.querySelector(`#seasonJump [data-jump="${r}"]`), room)
    await click(page, `#seasonJump [data-jump="${room}"]`)
  } else if (room === 'league') {
    await click(page, '#deskMenu [data-seg="league"]')
  } else if (room === 'pot') {
    await page.evaluate(() => window.switchView('pot'))      /* the router's own "open the season on the pot" */
  } else {
    await page.evaluate((r) => window.setRoomSeg(r), room)   /* the desk has no control for the table; it heads the page */
  }
  await page.waitForTimeout(250)
  await scrollSettled(page)
}
/* an element's top edge is inside the viewport (a fullPage:false capture
   shows the section it claims) */
const inViewport = (sel, what) => async (page) => page.evaluate(({ sel, what }) => {
  const el = document.querySelector(sel); if (!el) return `${what}: ${sel} is missing`
  const r = el.getBoundingClientRect()
  return r.height > 0 && r.top >= -4 && r.top < innerHeight - 60 ? true : `${what} is not in view (top ${Math.round(r.top)} of ${innerHeight})`
}, { sel, what })
const text = (sel) => (page) => page.evaluate((sel) => ((document.querySelector(sel) || {}).innerText || '').replace(/\s+/g, ' ').trim(), sel)
/* innerText carries text-transform, so a name set in caps reads in caps: match case-blind */
const has = (sel, re, what) => async (page) => { const t = await text(sel)(page); return new RegExp(re, 'i').test(t) ? true : `${what}: ${JSON.stringify(t.slice(0, 160))} !~ /${re}/i` }

/* the light printing's flipped tokens, read from the source (packages/tokens/tokens.json) */
const LIGHT_PRINTING = (() => {
  const doc = JSON.parse(readFileSync(new URL('../../packages/tokens/tokens.json', import.meta.url), 'utf8')), out = {}
  for (const g of Object.values(doc.groups)) for (const [n, t] of Object.entries(g.tokens)) if (t.light !== undefined && String(t.light) !== String(t.dark)) out[n] = String(t.light)
  return out
})()
/* ------------------------------------------------------------ the world */
const NG = { league: 'f3000000-0000-4000-8000-000000000001', season: 'f4000000-0000-4000-8000-000000000011' }
/* the Pro's own instructions (D129): a pot seven of eight have paid into was
   announced somewhere; the core world never said how */
const payHowSet = (W) => {
  const ls = W.tables.league_settings.find((s) => s.league_id === NG.league)
  ls.buy_in_note = 'Cash at the first tee, or a transfer to the Pro'
  ls.buy_in_due_on = '2026-10-04'
}
/* The core world's board carries one invented moment, "FIXTURE WRENS TAKE THE
   LEAD IN WEEK 8" (tests/fixtures/ten/world.mjs, post …902). No producer
   writes that sentence (the real moments are clash streaks, D176/#23), and
   since rpc/30 rebuilt the weekly snapshots from the rounds it is false: the
   Javelinas have led since week 2 and lead 171–137. The season's story prints
   every moment, so these captures drop it; the fix belongs in world.mjs. */
const MOMENT_902 = 'f7000000-0000-4000-8000-000000000902'
const dropInventedMoment = (W) => {
  const p = W.tables.posts.find((x) => x.id === MOMENT_902)
  if (p && p.kind === 'moment' && /TAKE THE LEAD IN WEEK 8/.test(p.body)) { W.tables.posts = W.tables.posts.filter((x) => x !== p); W.notes.push('dropped the invented week-8 moment') }
}
const seasonFacts = (page) => page.evaluate(() => ({ title: (document.getElementById('seasonTitle') || {}).textContent || '', league: window.CS && window.CS.league && window.CS.league.id }))
const onNorthGrove = async (page) => { const f = await seasonFacts(page); return f.league === 'f3000000-0000-4000-8000-000000000001' && f.title === 'North Grove (fixture)' ? true : `the season page is ${JSON.stringify(f)}` }

/* ------------------------------------------------------------ season */
/* TEN / W6 · AW2-06 + OB-05 · the season page's words that were set in mono */
/* AW2-04: at the desk the climb draws only its cut, and "What's on it" yields
   to the pot beside it, so the rungs, the seat line and the line card are
   words the phone's shape must draw and the desk's must not */
const SEASON_WORDS = ['#standings th', '#indTable th', '#clashTbl th', { sel: '#climbNote', below: 960 }, '#climb .climb-cut', { sel: '#climb .climb-rung .voice', below: 960 },
  '#scenarioLine', { sel: '#lineSplit', below: 960 }, { sel: '#homeSeason .ontheline .ok', below: 960 }, '#seasonArc .arcrow .aw', '#nextK', '#albumGrid .almonth', '#feedList .datesep',
  '.trip .p span', '.trip .p b', '#potMath', '.potgrid .purse .k', '#hubMembersSub', '#hubDraftSub', '#room-league .check .tt small', '#seasonMore',
  { sel: '#seasonJump button', below: 960 }, { sel: '.tabbar .tab', below: 960 }]
const SEASON = [
  { family: 'season', id: 'narrative', variant: 'member', title: 'The season page, its head: North Grove in week 8 and the story line', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toSeasonViaBand(page); await page.evaluate(() => window.scrollTo(0, 0)); await scrollSettled(page) },
    expect: { view: 'view-hub', selectors: { '#seasonScoreboard': 'visible', '#seasonDateline': 'text:Week 8 of 13', '#seasonLead': 'visible' } },
    check: all(onNorthGrove, inViewport('#seasonScoreboard', 'the season head'),
      has('#seasonLead', 'Fixture (Javelinas|Wrens)', 'the story line'),
      async (page) => page.evaluate(() => window.seasonStory && window.seasonStory.season && window.seasonStory.season.id === 'f4000000-0000-4000-8000-000000000011' ? true : 'season_story did not answer for North Grove')) },
  { family: 'season', id: 'leaderboard', variant: 'member', title: 'The season page, the table: two squads, the clash, every golfer', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: (page) => toRoom(page, 'standings'),
    expect: { view: 'view-hub', selectors: { '#standings': 'visible', '#indTable': 'visible' } },
    check: all(onNorthGrove, inViewport('#standings', 'the standings table'),
      has('#standings', 'Fixture Javelinas[\\s\\S]*171[\\s\\S]*Fixture Wrens[\\s\\S]*137', 'the squad table (v_squad_standings: 171 / 137)'),
      async (page) => page.evaluate(() => document.querySelectorAll('#indTable tr').length >= 8 ? true : 'the every-golfer table has fewer than eight rows'),
      /* TEN / W6 · AW2-06 + OB-05: every label on the season page is agate and
         every phrase agate or body — mono keeps the figures (§1.4). The page
         draws all of these at once, whichever section is in view. */
      notMono(SEASON_WORDS, SEASON_WORDS),
      /* TEN / W6 · AW2-07: the story's figures are runs and "What's on it" is the figure role — never the serif */
      noSerifFigure(['#standingsStory', '#lineAmt'], ['#standingsStory .cfrun', { sel: '#lineAmt', below: 960 }]),
      /* TEN / W6 · AW2-08: no retired glyph on the season page, and its span is an en dash */
      noRetiredGlyph(),
      readsAsWritten([['#hhSpan', ' \u2013 ', true]]),
      /* TEN / W6 · AW2-13: no pill (the jump chips), no spine, no glass */
      noRetiredShape(),
      /* TEN / W6 · AW2-14: the climb's own spark is ink — gold is earned (D359), being you is not. It
         rides the viewer's rung, which the desk no longer draws (AW2-04), so the phone's shape reads it */
      async (page) => page.evaluate(() => { const p = document.querySelector('.climb-spark polyline'); if (!p) return innerWidth >= 960 ? true : 'no climb spark to read'; return /--gold/.test(p.getAttribute('stroke') || '') ? 'the climb spark is gold' : true }),
      /* TEN / W6 · AW2-04 (L-34, D360): the table is the one standings object. At the desk the climb
         card keeps only its cut line and "What's on it" yields to the pot beside it; at every width
         the story says the gap once (the fixture's Wrens trail by 34, the viewer's squad) */
      async (page) => page.evaluate(() => {
        const shown = (el) => { if (!el) return false; const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.visibility !== 'hidden' }
        const story = ((document.getElementById('standingsStory') || {}).innerText || '').replace(/\s+/g, ' ').trim()
        if (story !== 'Fixture Javelinas lead by 34.') return `the story reads ${JSON.stringify(story)}`
        if (innerWidth < 960) return [...document.querySelectorAll('#climb .climb-rung')].some(shown) ? true : 'the phone lost its ladder'
        if ([...document.querySelectorAll('#climb .climb-rung, #climb .climb-ellip')].some(shown)) return 'the desk climb still draws the rungs the table draws'
        const cut = document.querySelector('#climb .climb-cut')
        if (!shown(cut)) return 'the desk climb does not draw its cut line'
        const cutTxt = cut.innerText.replace(/\s+/g, ' ').trim()
        if (cutTxt !== 'TOP SEED · +10 · 34 BACK') return `the cut line reads ${JSON.stringify(cutTxt)}`
        const note = document.getElementById('climbNote')
        if (shown(note) && note.innerText.trim()) return `the desk climb still says the seat line: ${JSON.stringify(note.innerText.trim())}`
        if ([...document.querySelectorAll('#homeSeason .ontheline')].some(shown)) return '"What\'s on it" still prints the pot beside the pot'
        return true
      }),
      onceInView([["the leader's points (171)", '(?<![\\d.,])171(?![\\d.,])', true], ["the second squad's points (137)", '(?<![\\d.,])137(?![\\d.,])', true],
        ['the pot ($600)', '\\$600(?![\\d.,])']], 960),
      /* TEN / W6 · DX2 OB2-02: the seat line and the clinch line take their caps from their roles; the
         strings are typed as said (the seat line is drawn below the desk only, AW2-04) */
      capsFromRole(['#climbNote', '#scenarioLine'], [{ sel: '#climbNote', below: 960 }, '#scenarioLine']),
      /* TEN / W8 · W7-014 [B2-season-6]: the climb's and the standings' heads take the section gap under the block above them */
      headGap(['#climbEyebrow', '#standingsEyebrow'])) },
  /* TEN / W6 · DX2 OB2-02 · the season six days before its first tee, and a
     league in its draw: the two heroes' lines (#khCount, #draftPoolSub).
     DX2's own states (season/kickoff, season/draft-phase): the synthetic
     world's DATA moves (a start date, a phase), then the page's router. */
  { family: 'season', id: 'kickoff', variant: 'member', title: 'The season page six days before the first tee (#kickoffHero)', fullPage: false,
    prepare: async (W) => { const L1 = W.ids.lid(1); for (const s of W.tables.seasons || []) if (s.league_id === L1) { s.starts_on = W.iso(6); s.ends_on = W.iso(6 + 13 * 7 - 1) } },
    drive: async (page) => { await page.evaluate(() => window.switchView('hub')); await until(page, () => { const k = document.getElementById('kickoffHero'); return !!k && k.offsetParent !== null }); await page.waitForTimeout(600) },
    expect: { view: 'view-hub', selectors: { '#kickoffHero': 'visible', '#khCount': 'text:Kicks off in \\d+ days?' } },
    check: capsFromRole(['#khCount'], ['#khCount']) },
  { family: 'season', id: 'draft-phase', variant: 'pro', title: 'The season page of a league in its draw (#homeDraft)', fullPage: false,
    prepare: async (W) => { const L1 = W.ids.lid(1); for (const l of W.tables.leagues || []) if (l.id === L1) l.phase = 'draft' },
    drive: async (page) => { await page.evaluate(() => window.switchView('hub')); await until(page, () => { const d = document.getElementById('homeDraft'); return !!d && d.offsetParent !== null }); await page.waitForTimeout(600) },
    expect: { view: 'view-hub', selectors: { '#homeDraft': 'visible', '#draftPoolSub': 'visible' } },
    check: capsFromRole(['#draftPoolSub'], ['#draftPoolSub']) },
  { family: 'season', id: 'story', variant: 'member', title: 'The season page, the story: the arc of weeks and the archive', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      if (await isDesk(page)) await click(page, '#deskMenu [data-seg="archive"]')
      else { await until(page, () => { const a = document.getElementById('seasonMore'); return !!a && a.offsetParent !== null }); await click(page, '#seasonMore') }
      await page.waitForTimeout(250); await scrollSettled(page)
    },
    expect: { view: 'view-hub', selectors: { '#seasonArc': 'visible', '#seasonStoryHead': 'visible' } },
    check: all(onNorthGrove, inViewport('#seasonArc', "the season's story"),
      /* the one lead change the rebuilt snapshots hold (week 2); the core
         world has no other season-long board history to tell */
      has('#seasonArc', 'Week 2[\\s\\S]*Fixture Javelinas took the lead from Fixture Wrens\\.', 'the arc’s lead change'),
      async (page) => page.evaluate(() => /TAKE THE LEAD IN WEEK 8/i.test(document.getElementById('seasonArc').innerText) ? 'the invented week-8 moment is still on the story' : true)) },
  { family: 'season', id: 'pot', variant: 'member', title: 'The season page, the money: $600 pot, $525 in, how to pay, a member reads the ledger', fullPage: false,
    prepare: async (W) => { dropInventedMoment(W); payHowSet(W) },
    drive: (page) => toRoom(page, 'pot'),
    expect: { view: 'view-hub', selectors: { '#room-pot': 'visible', '#potAmt': 'text:\\$600', '#potK': 'text:^The pot · eight in$', '#potMath': 'text:^\\$75 each · \\$525 collected · 1 still owes$', '#paidCount': 'text:^seven of eight$', '#payHow': 'text:Cash at the first tee' } },
    check: all(onNorthGrove, inViewport('#room-pot', 'the money'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#payers .payer')]
        if (rows.length !== 8) return `${rows.length} payer rows, expected 8`
        if (rows.some((r) => r.tagName === 'BUTTON')) return 'a member sees tappable payer rows'
        if (document.querySelector('#payHow [data-payedit]')) return 'a member sees the Pro’s edit link'
        return rows.filter((r) => r.classList.contains('paid')).length === 7 ? true : 'seven of eight should read paid'
      }),
      /* TEN / W6 · AW2-07: the pot is the board `figure`, never the serif */
      noSerifFigure(['#potAmt', '.trip .p b'], ['#potAmt']),
      /* TEN / W8 · W7-014 [B2-season-6]: 'Season stakes' and 'How to pay' take the section gap */
      headGap(['#room-pot .potgrid > div > .eyebrow:first-child'])) },
  { family: 'season', id: 'pot-pro', variant: 'pro', title: 'The season page, the money, as the Pro: tap a name as money moves', fullPage: false,
    prepare: async (W) => { dropInventedMoment(W); payHowSet(W) },
    drive: (page) => toRoom(page, 'pot'),
    expect: { view: 'view-hub', selectors: { '#room-pot': 'visible', '#potAmt': 'text:\\$600', '#payHow [data-payedit]': 'visible' } },
    check: all(onNorthGrove, inViewport('#room-pot', 'the money'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#payers .payer')]
        if (rows.length !== 8) return `${rows.length} payer rows, expected 8`
        return rows.every((r) => r.tagName === 'BUTTON') ? true : 'the Pro’s payer rows are not controls'
      }),
      /* TEN / W8 · W7-012 [B2-season-13]: the Pro's box carries the word (Paid / Not yet) and the empty box is mut,
         never rule (§16.1); a member's rows already read the word */
      async (page) => page.evaluate(() => {
        const st = [...document.querySelectorAll('#payers .payer .st')].map((e) => e.textContent.trim())
        return st.length === 8 && st.filter((x) => x === 'Paid').length === 7 && st.filter((x) => x === 'Not yet').length === 1 ? true : `the Pro's rows say ${JSON.stringify(st)}`
      }),
      stateContrast([{ sel: '#payers .payer:not(.paid) .tick', prop: 'borderTopColor', min: 3, what: 'the unpaid box' }]),
      headGap(['#room-pot .potgrid > div > .eyebrow:first-child'])) },
  /* TEN / W6 · DX2 OB2-03 · the Pro's "Cancel this season", opened and NOT
     confirmed: North Grove is under way, so it is the consent flow's sheet,
     and its armed control is §7.1's destructive tier */
  { family: 'season', id: 'cancel-confirm', variant: 'pro', fullPage: false, title: 'The season page, as the Pro: Cancel this season, the confirmation (not confirmed)',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => { const a = document.getElementById('hhDelete'); return !!a && a.offsetParent !== null })
      await click(page, '#hhDelete')
      await until(page, () => { const s = document.getElementById('sheet'); return !!s && s.classList.contains('open') && !!document.getElementById('cxGo') })
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-hub', sheet: '^Cancel ', selectors: { '#cxGo': 'visible', '#cxNo2': 'visible' } },
    check: armedDelete('#cxGo') },
  { family: 'season', id: 'rules', variant: 'member', title: 'The season page, the rules in sentences', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: (page) => toRoom(page, 'league'),
    expect: { view: 'view-hub', selectors: { '#rulesHead': 'visible', '#bylawsHub': 'visible', '#hubSeasonRevoke': 'text:^Turn off$' } },
    check: all(onNorthGrove, inViewport('#room-league', 'the rules'),
      async (page) => page.evaluate(() => document.getElementById('bylawsHub').innerText.trim().length > 80 ? true : 'the rules are empty')) },
  /* TEN / W8 · W7-011 [B2-season-12] · the week clock, cropped: the weeks played are ink, the live week brand
     and tall, the weeks ahead mut — never rule (§16.1), so each reads as a state on the page's ground */
  { family: 'season', id: 'month-clock', variant: 'member', title: 'The season page, the week clock (its own crop)', shot: '#monthClock',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toSeasonViaBand(page); await until(page, () => document.querySelectorAll('#monthClock .t.played').length > 0); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#monthClock .t.played': 'visible', '#monthClock .t.now': 'visible' } },
    check: all(onNorthGrove, stateContrast([
      { sel: '#monthClock .t:not(.played):not(.now)', prop: 'backgroundColor', min: 4.5, what: 'the weeks ahead' },
      { sel: '#monthClock .t.played', prop: 'backgroundColor', min: 12, what: 'the weeks played' },
      { sel: '#monthClock .t.now', prop: 'backgroundColor', min: 3, what: 'the live week' }])) },
  /* TEN / W8 · W7-008 [A2-season-1] · the season link's off switch is a word,
     and armed: the first tap says what the next one does and turns nothing off */
  { family: 'season', id: 'link-off', variant: 'member', title: 'The season page, the rules: the season link row at rest ("Link" and "Turn off")', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'league'); await page.locator('#hubSeasonRevoke').scrollIntoViewIfNeeded(); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#hubSeasonRevoke': 'text:^Turn off$' } },
    check: all(onNorthGrove, inViewport('#hubSeasonRevoke', 'the season link row')) },
  { family: 'season', id: 'link-armed', variant: 'member', title: 'The season page, the rules: "Turn off" tapped once (armed, not confirmed)', fullPage: false,
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'league'); await click(page, '#hubSeasonRevoke'); await page.waitForTimeout(300) },
    expect: { view: 'view-hub', selectors: { '#hubSeasonRevoke': 'text:^Sure\\? Turn it off$' } },
    check: all(onNorthGrove, inViewport('#hubSeasonRevoke', 'the season link row'),
      async (page) => page.evaluate(() => {
        const b = document.getElementById('hubSeasonRevoke')
        if (!b.classList.contains('is-armed') || b.dataset.armed !== '1') return 'the first tap did not arm the control'
        return (window.__tenNet || []).some((n) => /revoke_share|create_share/.test(n.url)) ? 'the first tap already turned the link off' : true
      })) },
]

/* ------------------------------------------------------------ compete */
const COMPETE = [
  { family: 'compete', id: 'empty', variant: 'brand_new', title: 'Compete · nothing running (a brand-new golfer)',
    drive: toCompete,
    expect: { view: 'view-compete', selectors: { '#cmpList .emptyroot h3': 'text:^Nothing running\\.$', '#cmpList [data-erdoor="startSomething"]': 'visible', '#cmpList [data-erdoor="joinWithCode"]': 'visible' } },
    check: async (page) => page.evaluate(() => document.querySelector('#cmpList [data-cband], #cmpList .peerrow') ? 'a season or a moment rendered for a golfer with none' : true) },
  { family: 'compete', id: 'populated', variant: 'member', title: 'Compete · the Scoreboard (North Grove), a second season, the moments, the finished shelf',
    prepare: async (W) => { ryderWorld(W) },
    drive: async (page) => { await toCompete(page); await until(page, () => /North Grove Ryder/.test((document.getElementById('cmpFinished') || {}).innerText || '')) },
    expect: { view: 'view-compete', selectors: { '#cmpList [data-cband] .cband-name': 'text:^North Grove \\(fixture\\)$', '#cmpBookDoor': 'text:Open the Book|Rounds' } },
    /* W5 · the band names the side whose standing it states (137 and 2nd are
       Fixture Wrens', the golfer's squad), and the moments ride the second
       column (#cmpMoments) — beside the seasons on the desk, after them on
       the phone */
    check: all(has('#cmpList [data-cband]', '137[\\s\\S]*Fixture Wrens · 2nd[\\s\\S]*34 back from Fixture Javelinas\\.', 'the band (137 points, Fixture Wrens 2nd, 34 back)'),
      has('#cmpList', 'South Wash Weekday \\(fixture\\)', 'the second season'),
      has('#cmpMoments', 'The North Grove Ryder \\(fixture\\)', 'the live Ryder in the moments'),
      has('#cmpFinished', 'The North Grove Ryder \\(fixture\\)', 'the finished Ryder on the shelf')) },
]

/* ------------------------------------------------------------ the Book */
/* the Book dialog, loaded: the read answered and the body replaced the
   loading line (or the error replaced it) */
const bookOpen = (page) => until(page, () => { const d = document.getElementById('seasonBookDialog'); const m = d && d.querySelector('.sb-main'); return !!d && d.open && !!m && !/Loading the whole season/.test(m.textContent) }, null, 10000)
async function bookFromCompete(page) {
  await toCompete(page)
  await until(page, () => !!document.getElementById('cmpBookDoor'))
  await tapUntil(page, '#cmpBookDoor', () => { const d = document.getElementById('seasonBookDialog'); return !!d && d.open })
  await bookOpen(page)
  await page.waitForTimeout(300)
}
async function bookFromSeason(page) {
  await until(page, () => { const d = document.getElementById('seasonBookDoor'); return !!d && !d.hidden && d.offsetParent !== null }, null, 10000)
  await tapUntil(page, '#seasonBookDoor', () => { const d = document.getElementById('seasonBookDialog'); return !!d && d.open })
  await bookOpen(page)
  await page.waitForTimeout(300)
}
/* the Book the page validated is the envelope the world adopted */
const bookIs = (want) => async (page) => page.evaluate((want) => {
  const d = document.getElementById('seasonBookDialog'); if (!d || !d.open) return 'the Book is not open'
  const t = d.innerText.replace(/\s+/g, ' ')
  if (want.title && (d.querySelector('#sb-title') || {}).textContent !== want.title) return `the Book is titled ${JSON.stringify((d.querySelector('#sb-title') || {}).textContent)}`
  if (want.head && !t.includes(want.head)) return `the Book's head does not read ${JSON.stringify(want.head)}`
  if (d.querySelector('.sb-main [role="alert"]') && !want.alert) return 'the Book shows an error: ' + d.querySelector('.sb-main [role="alert"]').textContent
  return true
}, want)
/* the Scoreboard the door sat under says the same standing the Book does */
const bandSays = (re, what) => async (page) => page.evaluate(({ re, what }) => {
  const b = document.querySelector('#cmpList [data-cband]'); if (!b) return 'no Scoreboard band on Compete'
  const t = b.innerText.replace(/\s+/g, ' ')
  return new RegExp(re).test(t) ? true : `the Scoreboard (${what}) reads ${JSON.stringify(t.slice(0, 200))}`
}, { re, what })
const adopt = (name, opts) => async (W) => { adoptBook(W, readBook(name), opts) }
const BOOK_LS = (name) => ({ cs_last_league: readBook(name).league_id })

const BOOK = [
  { family: 'book', id: 'upcoming', variant: 'rounds_no_league', title: 'The Book before the first tee (The Autumn Fixture Cup, week 0 of 15), from the Scoreboard', fullPage: false,
    prepare: adopt('upcoming'), localStorage: BOOK_LS('upcoming'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-main': 'text:No standing yet\\. Weeks begin at first tee\\.' } },
    check: all(bookIs({ title: 'The Book', head: 'The Autumn Fixture Cup · Season 1 · Oct 5 – Jan 17, 2027' }),
      bandSays('The first tee is Mon Oct 5', 'upcoming'),
      async (page) => page.evaluate(() => document.querySelector('#seasonBookDialog .sb-matrix') ? 'a matrix rendered before the first tee' : true)) },
  { family: 'book', id: 'squads', variant: 'rounds_no_league', title: 'The Book, four squads in week 13 (North Grove, the squads envelope), from the Scoreboard', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-matrix': 'visible', '#seasonBookDialog #sb-group': 'visible', '#seasonBookDialog .sb-matrix th.sb-current': 'text:W13' } },
    check: all(bookIs({ title: 'The Book', head: 'North Grove (fixture) · Season 1 · Jul 6 – Oct 18, 2026' }),
      bandSays('326[\\s\\S]*3rd', 'squads: 3rd, 326 points'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr')]
        if (rows.length !== 4) return `${rows.length} squad rows, expected 4`
        const names = rows.map((r) => r.querySelector('th').innerText.split('\n')[0].trim())
        if (names.join('|') !== 'Fixture Quail|Fixture Wrens|Fixture Javelinas|Fixture Gilas') return 'squad order ' + names.join('|')
        return document.querySelectorAll('#seasonBookDialog .sb-adjustment').length >= 3 ? true : 'the adjustments in the totals are missing'
      })) },
  /* EXPECTED TO FAIL on current source. The Scoreboard names a season's state
     in one of three words (F11: Upcoming · Live · Final). Seven days before
     this season's first tee its row facts already say "No standing yet. First
     tee is ahead." -- and the band beside them says LIVE, on the live ember.
     csCompeteList (index.html:19787) calls a season Upcoming only when
     home_dispatch's `season.week_no === 0`, and native_home never sends 0 (it
     clamps to week 1 and says `days_to_first_tee` instead -- book-home's own
     record of the server: week_no 1, days_to_first_tee 11); its fallback reads
     `lg.season.status`, which loadMemberships (index.html:27537) never
     selects, so every season in phase `season` is Live from the lock on. */
  { family: 'book', id: 'scoreboard-upcoming', variant: 'rounds_no_league', title: 'The Scoreboard seven days before the first tee (The Autumn Fixture Cup): the state word',
    prepare: adopt('upcoming'), localStorage: BOOK_LS('upcoming'),
    drive: toCompete,
    expect: { view: 'view-compete', selectors: { '#cmpList [data-cband] .cband-name': 'text:^The Autumn Fixture Cup$', '#cmpBookDoor': 'visible' } },
    /* W5 · the upcoming band says WHEN — the first tee's day from the payload
       (it said "No standing yet. First tee is ahead.", "not yet" twice) */
    check: all(bandSays('The first tee is Mon Oct 5', 'upcoming facts'),
      async (page) => page.evaluate(() => {
        const b = document.querySelector('#cmpList [data-cband]'), w = (b.querySelector('.cband-state') || {}).textContent
        return w === 'Upcoming' && b.dataset.live !== 'true' ? true : `the band says ${JSON.stringify(w)} (data-live=${b.dataset.live}) for a season whose first tee is 2026-10-05 -- the Compete row's state tests season.week_no===0 (csCompeteRows), and native_home sends week_no 1 with days_to_first_tee for an upcoming season`
      })) },
  /* the Cup Final: the tick flipped the season on ends_on − 27 and seeded the
     top two; the season page leads with the race (cup_final_race) and the
     Book, opened from the season page's own door, is drawn as the race of the
     golfers (the squads' race cannot plot: one late squad correction sits
     outside the season weeks, and the Book says so rather than drop it) */
  { family: 'book', id: 'race', variant: 'rounds_no_league', title: 'The Book in the Cup Final: the race of the golfers, from the season page (cup_final_race behind)', fullPage: false,
    prepare: async (W) => { adoptBook(W, readBook('squads')); cupFinalOn(W, readBook('squads').season_id) }, localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await toSeasonViaBand(page)
      await until(page, () => { const w = document.getElementById('cupRaceWrap'); return !!w && w.style.display !== 'none' && document.querySelectorAll('#cupRace tr').length >= 2 }, null, 10000)
      await bookFromSeason(page)
      /* W5 · the Book's controls are segments (one component, UI_SYSTEM
         §7.2), not native selects: each is chosen by its button */
      await click(page, '#seasonBookDialog #sb-group [data-v="golfer"]')
      await until(page, () => !!document.querySelector('#seasonBookDialog #sb-mode'))
      await click(page, '#seasonBookDialog #sb-mode [data-v="Race"]')
      await until(page, () => !!document.querySelector('#seasonBookDialog svg.sb-race'))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-hub', selectors: { '#seasonBookDialog svg.sb-race': 'visible', '#seasonBookDialog #sb-follow': 'visible' } },
    check: all(bookIs({ title: 'The Book' }),
      has('#cupRace', 'Fixture Quail[\\s\\S]*Fixture Wrens|Fixture Wrens[\\s\\S]*Fixture Quail', 'the Cup Final race behind the Book'),
      async (page) => page.evaluate(() => {
        const svg = document.querySelector('#seasonBookDialog svg.sb-race')
        if (svg.querySelectorAll('.sb-race-path').length !== 3) return `${svg.querySelectorAll('.sb-race-path').length} race lines, expected 3`
        if (!svg.querySelector('.sb-current-line')) return 'no current-week line in the Cup Final'
        return window.CS && window.CS.season && window.CS.season.status === 'cup_final' ? true : 'the season is not in its Cup Final'
      })) },
  { family: 'book', id: 'tie', variant: 'rounds_no_league', title: 'Rounds & points, two golfers level at the top (The Saturday Fixture Cup), from the Scoreboard', fullPage: false,
    prepare: adopt('tie'), localStorage: BOOK_LS('tie'),
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-totals': 'visible' } },
    check: all(bookIs({ title: 'Rounds & points', head: 'The Saturday Fixture Cup · Season 1' }),
      bandSays('1st · Tied[\\s\\S]*The lead is shared\\.', 'tie'),
      async (page) => page.evaluate(() => {
        const rows = [...document.querySelectorAll('#seasonBookDialog .sb-totals button')].map((b) => b.innerText.replace(/\s+/g, ' ').trim())
        if (rows.length !== 2) return `${rows.length} totals, expected 2`
        return rows.every((r) => /1st · Tied/.test(r) && /41 pts/.test(r)) ? true : 'the totals read ' + JSON.stringify(rows)
      })) },
  /* a finished season has no Scoreboard band (it waits on Compete's finished
     shelf); its Book opens from the season page */
  { family: 'book', id: 'finished', variant: 'rounds_no_league', title: 'The Book of a complete season (The Summer Fixture Cup), from the finished shelf and the season page', fullPage: false,
    /* the one-time ceremony (openSeasonCeremony) was seen the night the season closed */
    prepare: adopt('finished'), localStorage: { ...BOOK_LS('finished'), ['cs_cer_' + readBook('finished').season_id]: '1' },
    drive: async (page) => {
      await toCompete(page)
      const L = readBook('finished').league_id
      await tapUntil(page, `#cmpFinished [data-peer="league:${L}"]`, () => (document.querySelector('.view.active') || {}).id === 'view-hub')
      await bookFromSeason(page)
    },
    expect: { view: 'view-hub', selectors: { '#seasonBookDialog .sb-matrix': 'visible' } },
    check: all(bookIs({ title: 'The Book', head: 'This record uses the league’s current scoring rules; a locked historical rule snapshot is not available.' }),
      async (page) => page.evaluate(() => {
        const rows = document.querySelectorAll('#seasonBookDialog .sb-matrix tbody tr').length
        if (rows !== 16) return `${rows} golfer rows, expected 16`
        return document.querySelector('#seasonBookDialog .sb-matrix th.sb-current') ? 'a complete season marks a current week' : true
      })) },
  { family: 'book', id: 'error', variant: 'rounds_no_league', title: 'The Book when its read fails: the error and Try again', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    world: { errors: { rpc: { season_book: { __error: 'fixture: the Book read failed', status: 503, code: 'XX000' } } } },
    expectConsole: [/status of 503/],
    drive: bookFromCompete,
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-main [role="alert"]': 'text:^The Book did not load\\. Try again\\.$', '#seasonBookDialog #sb-retry': 'visible' } },
    check: async (page) => page.evaluate(() => (window.__tenNet || []).some((e) => /\/rpc\/season_book/.test(e.url) && e.status === 503) ? true : 'season_book was not read (or did not fail)') },
  /* a real cell: my squad's week 12, the week before the capture's */
  { family: 'book', id: 'cell-receipt', variant: 'rounds_no_league', title: 'The Book, a cell’s receipt: Fixture Javelinas in week 12', fullPage: false,
    prepare: adopt('squads'), localStorage: BOOK_LS('squads'),
    drive: async (page) => {
      await bookFromCompete(page)
      const row = await page.evaluate(() => {
        const th = [...document.querySelectorAll('#seasonBookDialog .sb-matrix tbody th button')].find((b) => /^Fixture Javelinas/.test(b.innerText.trim()))
        return th ? th.dataset.bookRow : null
      })
      if (row == null) throw new Error('no Fixture Javelinas row in the Book')
      await click(page, `#seasonBookDialog .sb-matrix td button[data-book-row="${row}"][data-book-week="12"]`)
      await until(page, () => /Fixture Javelinas · Week 12/.test((document.querySelector('#seasonBookDialog .sb-receipts h2') || {}).textContent || ''))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-compete', selectors: { '#seasonBookDialog .sb-receipts h2': 'text:^Fixture Javelinas · Week 12$', '#seasonBookDialog .sb-receipts .sb-total': 'visible' } },
    check: async (page) => {
      const b = readBook('squads')
      const row = b.rows.find((r) => r.id === 'squad:c50b0000-0000-4000-8000-000000000300')
      const es = row.entries.filter((e) => e.week === 12)
      const want = { n: es.length, total: es.reduce((s, e) => s + e.contribution, 0) }
      return page.evaluate((want) => {
        const box = document.querySelector('#seasonBookDialog .sb-receipts')
        const n = box.querySelectorAll('.sb-entry').length
        const total = parseInt(box.querySelector('.sb-total').textContent, 10)
        if (n !== want.n) return `${n} receipt entries, the envelope holds ${want.n}`
        if (total !== want.total) return `the receipt totals ${total}, the envelope ${want.total}`
        const r = box.getBoundingClientRect()
        return r.top < innerHeight - 40 && r.bottom > 40 ? true : 'the receipt is scrolled out of view'
      }, want)
    } },
]

/* ------------------------------------------------------------ events */
const E_LIVE = ids.event(12), E_DONE = ids.event(11), E_GHOST = ids.event(999)
async function eventFromCompete(page, sel, id) {
  await toCompete(page)
  await until(page, (sel) => !!document.querySelector(sel), sel)
  await tapUntil(page, sel, (id) => (document.querySelector('.view.active') || {}).id === 'view-event' && !!window.CS_EVENT && (window.CS_EVENT.event === null || ['failed', 'unavailable'].includes(window.CS_EVENT.state) || (window.CS_EVENT.event || {}).id === id), id)
  await until(page, () => (document.getElementById('eventBody') || {}).innerText.trim().length > 0)
  await page.waitForTimeout(400)
}
const EVENTS = [
  /* W5 (4a703402) moved Compete's moments into their own column, #cmpMoments;
     the events states tap the row where it now lives */
  { family: 'events', id: 'live', variant: 'member', title: 'The event room · a live Ryder, week 3 of 3, from Compete’s moments',
    prepare: async (W) => { ryderWorld(W) },
    drive: (page) => eventFromCompete(page, `#cmpMoments [data-peer="event:${E_LIVE}"]`, E_LIVE),
    /* W2 2026-09-28 · the side scores ride the plate now (owner H: the score
       was under the fold at 375), so the rail below it is gone; and the
       series line says the holder once — "hold the Ryder 1–0 · Fixture Hawks
       hold it" was one fact twice (owner C, category C, critique-B P3). */
    expect: { view: 'view-event', selectors: { '#eventBody h1': 'text:^The North Grove Ryder \\(fixture\\)$', '#eventBody .evbrow': 'text:Live · week 3 of 3 · 2 days left', '#eventBody .evside .fig': 'visible' } },
    check: all(has('#eventBody .evclinch', 'First to 6½\\. Fixture Hawks need 1, Fixture Bobcats need 4\\.', 'the clinch line'),
      has('#eventBody', 'Still to post: [^.]*Emery[^.]*Harper|Still to post: [^.]*Harper[^.]*Emery', 'the open week’s still-to-post line'),
      has('#eventBody', 'The 2nd Ryder · Fixture Hawks hold it, 1–0', 'the series line (event_lineage)'),
      has('#eventBody', 'Fixture Hawks lead 5½–2½ after week 2\\.', 'the board’s week-2 line'),
      async (page) => page.evaluate(() => Object.keys((window.CS_EVENT || {}).targets || {}).length === 4 ? true : 'event_session_targets did not reach the four open duels')) },
  { family: 'events', id: 'finished', variant: 'member', title: 'The event room · a finished Ryder (Fixture Hawks 7–5), from Compete’s finished shelf',
    prepare: async (W) => { ryderWorld(W) },
    drive: (page) => eventFromCompete(page, `#cmpFinished [data-peer="event:${E_DONE}"]`, E_DONE),
    expect: { view: 'view-event', selectors: { '#eventBody h1': 'text:^The North Grove Ryder \\(fixture\\)$', '#eventBody .evbrow': 'text:^Final · ' } },
    check: all(has('#eventBody .evclinch', '^Final\\. Fixture Hawks took it 7–5\\.$', 'the result line'),
      has('#eventBody', 'Fixture Hawks take The North Grove Ryder \\(fixture\\) 7–5\\. Devon is MVP at 3-0-0\\.', 'the settlement post'),
      async (page) => page.evaluate(() => [...document.querySelectorAll('#eventBody button')].some((b) => /Run it back/.test(b.textContent)) ? true : 'no Run it back')) },
  /* an id nobody holds -- the stale link, the event scrapped while the list
     was open -- through the page's own router */
  /* S8 (root f6d30196 / d86b15ad): the room's own recovery plate. A read
     that comes back with no row is `unavailable` (no retry: removed, or not
     on the roster); a read that fails is `failed` (Try again). */
  { family: 'events', id: 'unavailable', variant: 'member', title: 'The event room · an event id that does not resolve (the recovery plate: not open to you)',
    expectConsole: [/status of 406/],
    drive: async (page) => {
      await page.evaluate((id) => window.openEvent(id), E_GHOST)
      await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-event' && !!window.CS_EVENT && (window.CS_EVENT.state === 'unavailable' || window.CS_EVENT.event === null), null, 10000)
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-event', minText: 10, selectors: { '#evrecHead': 'text:Not open to you', '[data-go-compete]': 'visible', '#evRetry': 'hidden' } },
    check: async (page) => page.evaluate((id) => (window.__tenNet || []).some((e) => e.url.includes('/rest/v1/events') && e.url.includes(id) && (e.status === 406 || e.status === 200)) ? true : 'the event read did not come back empty', E_GHOST) },
  { family: 'events', id: 'failed-read', variant: 'member', title: 'The event room · the event read fails, from Compete (the recovery plate: didn’t load, Try again)',
    prepare: async (W) => {
      ryderWorld(W)
      W.errors.when = [...(W.errors.when || []), { table: 'events', match: (q) => q.includes('id=eq.' + E_LIVE), error: { __error: 'fixture: the event read failed', status: 503 } }]
    },
    expectConsole: [/status of 503/, /\[event\]/, /^\[cs\] error:\s+fixture: the event read failed/],
    drive: async (page) => {
      await eventFromCompete(page, `#cmpMoments [data-peer="event:${E_LIVE}"]`, E_LIVE).catch(() => {})
      await until(page, () => !!window.CS_EVENT && window.CS_EVENT.state === 'failed' && !!document.getElementById('evRetry'), null, 15000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-event', minText: 10, selectors: { '#evrecHead': 'text:Didn.t load', '#evRetry': 'visible', '[data-go-compete]': 'visible' } },
    check: async (page) => page.evaluate((id) => (window.__tenNet || []).some((e) => e.url.includes('/rest/v1/events') && e.url.includes(id) && e.status === 503) ? true : 'the event read did not fail', E_LIVE) },
]

/* ------------------------------------------------------------ print */
/* TEN / W8 · W7-013 [B2-season-14] · the season page AS PRINTED. A probe, run with `--only print --widths 816`: print
   media at a paper's width (816 CSS px is Letter at 96dpi), because a sheet is laid out at the page's width and not the
   window's. From the dark or the light default the sheet prints the light printing: every token the light theme
   flips (held to tokens.json, so a drifted print block fails here), the main text darker than the secondary text, and
   both at AA on the paper. */
const PRINT = [
  { family: 'print', id: 'season', variant: 'member', probe: true, title: 'The season page as printed (print media, paper width), from the dark or the light default',
    prepare: async (W) => dropInventedMoment(W),
    drive: async (page) => { await toRoom(page, 'standings'); await page.emulateMedia({ media: 'print' }); await page.waitForTimeout(500) },
    expect: { view: 'view-hub' },
    check: all(onNorthGrove, async (page) => page.evaluate((want) => {
      const cs = getComputedStyle(document.documentElement)
      const bad = Object.entries(want).filter(([n, v]) => cs.getPropertyValue('--' + n).trim().toLowerCase() !== v.toLowerCase()).map(([n, v]) => `--${n} is ${cs.getPropertyValue('--' + n).trim()}, the light printing is ${v}`)
      return bad.length ? `the sheet does not print the light printing (${bad.length} of ${Object.keys(want).length} tokens): ` + bad.slice(0, 3).join('; ') : true
    }, LIGHT_PRINTING),
    stateContrast([{ sel: '#standingsStory', prop: 'color', min: 4.5, what: 'the story (ink) on the paper' },
      { sel: '#standings th', prop: 'color', min: 4.5, what: 'a column head (mut) on the paper' }]),
    async (page) => page.evaluate(() => {
      const l = (c) => { const v = (c.match(/[\d.]+/g) || []).slice(0, 3).map(Number).map((x) => { x /= 255; return x <= 0.03928 ? x / 12.92 : ((x + 0.055) / 1.055) ** 2.4 }); return 0.2126 * v[0] + 0.7152 * v[1] + 0.0722 * v[2] }
      const ink = l(getComputedStyle(document.querySelector('#standingsStory')).color), mut = l(getComputedStyle(document.querySelector('#standings th')).color)
      return ink < mut ? true : 'the main text prints lighter than the secondary text'
    })) },
]

export default [...SEASON, ...COMPETE, ...BOOK, ...EVENTS, ...PRINT]
