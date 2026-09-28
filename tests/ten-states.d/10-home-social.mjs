/* Cup Season · ten-capture states: HOME and GOLFERS (WX lane, helper WX-A,
 * 2026-09-28).
 *
 *   home/hatch-<id>      the fifteen Home-state payloads through the shipped
 *                        `?cs_home_state=<id>` hatch (D259), signed out -- the
 *                        harness serves the synthetic copy of the fixtures
 *   home/dispatch-<id>   the SAME payloads served signed-in through the real
 *                        `home_dispatch` RPC (flags.homeState), so the ME
 *                        strip, the wire and the feed read the world around them
 *   home/member-populated, home/pro, home/member-invited, home/inbox
 *                        the dispatch THIS world's facts produce
 *                        (tests/fixtures/ten/rpc/10-home-social.mjs)
 *   golfers/*            the Golfers list (populated and empty), a person
 *                        page, the head-to-head and the league board
 *
 * Every state is reached through the page's own controls or its own router,
 * and every assertion names the surface that must be showing: the lead's own
 * sentence, a named person, a named record. A fall-through to the Door, to a
 * different Home, or to a blank pane fails. */
import { readFileSync } from 'node:fs'

/* local twins of ten-states.mjs `helpers` (importing that module from here
   would be a cycle through its top-level await) */
const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }

/* ------------------------------------------ the arrangement the web draws */
/* index.html csUsableItems + csItemDoor + csRankDispatch (+ CS_DECK_CAP 4) +
   csWireArrange: the fence, the server's rank, the veto, the cap, the de-dupe */
const DOOR_FREE = new Set(['composer', 'people', 'declare'])
const DOOR_ID = new Set(['plan', 'receipt', 'live', 'season', 'pot', 'invite'])
function arrange(payload) {
  const items = ((payload && payload.items) || [])
    .filter((it) => !String(it.key || '').startsWith('afterplan:') || (it.context && it.context.plan_id))
    .filter((it) => it && it.route && (DOOR_FREE.has(it.route.kind) || (DOOR_ID.has(it.route.kind) && it.route.id)) && String(it.headline || '').trim())
  const ranked = items.length > 0 && items.every((it) => it.rank != null)
  items.sort((a, b) => ranked ? (a.rank - b.rank) || String(a.key).localeCompare(String(b.key)) : 0)
  const li = items.findIndex((it) => it.human_subject)
  const lead = li >= 0 ? items[li] : null
  const deck = items.filter((_, i) => i !== li).slice(0, 4)
  const sig = (it) => String(it.headline || '').trim() + '\u0000' + String(it.league_id || '')
  const seen = new Set(lead ? [sig(lead)] : []), wire = []
  for (const it of deck) { const k = sig(it); if (it.league_id && seen.has(k)) continue; seen.add(k); wire.push(it) }
  return { lead, wire }
}
/* the lead's own sentence is on screen, and the wire carries exactly the rest */
const arrangementCheck = (getExpected) => async (page) => {
  const ex = getExpected()
  if (!ex) return 'no expected arrangement was computed'
  return page.evaluate(({ lead, wireN }) => {
    const L = document.getElementById('homeLead'), D = document.getElementById('homeDeck')
    const lt = L ? L.innerText.replace(/\s+/g, ' ') : ''
    if (lead && !lt.includes(lead)) return `the lead reads ${JSON.stringify(lt.slice(0, 140))}, expected ${JSON.stringify(lead)}`
    if (!lead && lt.trim()) return `a lead rendered where none was expected: ${JSON.stringify(lt.slice(0, 80))}`
    const n = D ? D.querySelectorAll('.cswire, .csedn').length : 0
    if (n !== wireN) return `the wire holds ${n} line(s), expected ${wireN}`
    return true
  }, { lead: ex.lead ? ex.lead.headline : null, wireN: ex.wire.length })
}

/* ---- the Home-state payloads (the synthetic copy the harness serves) ---- */
const FIX = JSON.parse(readFileSync(new URL('../fixtures/ten/home-states.synthetic.json', import.meta.url), 'utf8'))
const fixture = (id) => { const st = FIX.states.find((s) => s.id === id); if (!st) throw new Error('no Home-state fixture ' + id); return st }
const HOME_STATE_IDS = ['brand_new', 'rounds_no_buddies', 'buddies_no_competition', 'event_ahead', 'event_live', 'between_seasons',
  'ceremony_night', 'inactive', 'invited', 'callout_pending', 'preseason', 'round_morning', 'round_evening', 'after_golf', 'after_golf_wire']

/* the ME strip: #homeMe below desk width, #sideMe in the sidebar at desk width */
const meStripShown = (page) => page.evaluate(() => {
  const vis = (el) => { if (!el) return false; const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.display !== 'none' && cs.visibility !== 'hidden' }
  const el = [document.getElementById('homeMe'), document.getElementById('sideMe')].find(vis)
  return el && el.innerText.trim().length > 0 ? true : 'the ME strip is empty or hidden'
})
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
const homePainted = async (page) => {
  await until(page, () => !!(document.querySelector('#homeLead .csedn') || document.querySelector('#homeDeck .cswire')), null, 10000)
  await page.waitForTimeout(300)
}

/* (a) the hatch, signed out. It lands after load + 1200ms (index.html D259) */
const HOME_HATCH = HOME_STATE_IDS.map((id) => {
  const ex = arrange(fixture(id).payload)
  return {
    family: 'home', id: `hatch-${id}`, variant: 'signed_out', url: `/?cs_home_state=${id}`,
    title: `Home state via the hatch, signed out · ${fixture(id).title}`,
    /* the hatch names the fixture it painted, on purpose */
    expectConsole: [/^\[home-state\] /],
    drive: homePainted,
    expect: { view: 'view-home' },
    check: arrangementCheck(() => ex),
  }
})

/* (b) the same payloads through the real home_dispatch, signed in. The
   account is the one the payload describes where the world has it (a brand-new
   card; rounds and no league), else the member. */
/* League-less accounts are NOT here: the web never asks `home_dispatch` for a
   golfer with no league (loadPulse returns before refreshHomeLead when
   CS.league is null -- the only boot-time caller), so S1/S2 are captured
   below as what that golfer actually sees: the hero card, not the ranked
   lead. A finding for root, recorded in the WX report. */
const DISPATCH_VARIANT = {}
const DISPATCH_IDS = ['preseason', 'event_live', 'invited', 'round_morning', 'round_evening',
  'after_golf', 'after_golf_wire', 'ceremony_night', 'between_seasons', 'inactive']
const HOME_DISPATCH = DISPATCH_IDS.map((id) => {
  const ex = arrange(fixture(id).payload)
  return {
    family: 'home', id: `dispatch-${id}`, variant: DISPATCH_VARIANT[id] || 'member',
    title: `Home state via home_dispatch, signed in · ${fixture(id).title}`,
    world: { flags: { homeState: id } },
    drive: homePainted,
    expect: { view: 'view-home' },
    check: all(arrangementCheck(() => ex), meStripShown),
  }
})

/* (b2) S1 / S2 signed in. Since c72d6a72 the desk asks home_dispatch for a
   league-less golfer too (D234: the phone's lead, one producer), so the LEAD
   owns the first move and the hero stands down behind it (L-34). WX's finding
   E recorded the old path, where the dispatch was never requested. */
const leadShown = (re) => async (page) => page.evaluate((re) => {
  const lead = ((document.getElementById('homeLead') || {}).innerText || '').replace(/\s+/g, ' ')
  const hero = ((document.getElementById('homeHero') || {}).innerText || '').trim()
  if (!window.homeDispatch) return 'the dispatch was never read for a league-less golfer'
  if (!lead.trim()) return 'no lead rendered for a league-less golfer'
  if (hero) return 'the hero did not stand down behind the lead: ' + JSON.stringify(hero.slice(0, 80))
  return new RegExp(re, 'i').test(lead) ? true : 'the lead reads ' + JSON.stringify(lead.slice(0, 120))
}, re)
const HOME_LEAGUELESS = [
  { family: 'home', id: 'league-less-brand_new', variant: 'brand_new', title: 'Home signed in, S1 brand-new (no league): the dispatch lead; the hero stands down',
    drive: async (page) => { await until(page, () => /first round/i.test((document.getElementById('homeLead') || {}).innerText || ''), null, 10000); await page.waitForTimeout(300) },
    expect: { view: 'view-home' }, check: all(leadShown('first round.*add my round'), meStripShown) },
  { family: 'home', id: 'league-less-rounds_no_buddies', variant: 'rounds_no_league', title: 'Home signed in, S2 rounds and no buddies (no league): the dispatch lead; the hero stands down',
    drive: async (page) => { await until(page, () => /nobody has seen it/i.test((document.getElementById('homeLead') || {}).innerText || ''), null, 10000); await page.waitForTimeout(300) },
    expect: { view: 'view-home' }, check: all(leadShown('nobody has seen it.*find golfers'), meStripShown, async (page) => page.evaluate(() => document.querySelectorAll('#homeFeed [data-hfr]').length > 0 ? true : 'my own rounds are not in the feed')) },
]

/* (c) the dispatch this world's own facts produce. The expectation is
   computed from the world's home_dispatch at drive time, so a sibling module
   that adds a plan or an invitation moves the expected wire with it; the
   state's own facts are asserted by name on top. */
let worldExpect = null
const worldDrive = async (page, { world }) => {
  worldExpect = arrange(await world.handlers.home_dispatch({ p_days: 21, p_today: world.today, p_caps: ['afterplan.v1'] }, world))
  await homePainted(page)
}
const onScreen = (re, what) => async (page) => page.evaluate(({ re, what }) => {
  const t = ['homeLead', 'homeDeck'].map((i) => (document.getElementById(i) || {}).innerText || '').join(' ').replace(/\s+/g, ' ')
  return new RegExp(re).test(t) ? true : `${what} is not on Home`
}, { re, what })
const feedHasRounds = async (page) => page.evaluate(() => document.querySelectorAll('#homeFeed [data-hfr]').length > 0 ? true : 'the circle feed drew no rounds')

const HOME_WORLD = [
  /* North Grove week 8 of 13, the Fixture Wrens 2nd of 2 and 34 back; the
     week-8 clash with Devon ("The Fixture Derby"), both in; Kit's buddy
     request; Devon's 76 on the wire */
  { family: 'home', id: 'member-populated', variant: 'member', title: 'Home · a member in week 8 (this world’s own dispatch)',
    drive: worldDrive, expect: { view: 'view-home' },
    check: all(arrangementCheck(() => worldExpect), meStripShown, feedHasRounds,
      onScreen('THE FIXTURE DERBY · THE CLASH · CLOSES IN 5 DAYS', 'the clash eyebrow'), onScreen('You and Devon are both in\\.', 'the clash'),
      onScreen('Kit wants to be golf buddies\\.', 'Kit’s request')) },
  { family: 'home', id: 'pro', variant: 'pro', title: 'Home · the Pro of North Grove',
    drive: worldDrive, expect: { view: 'view-home' },
    check: all(arrangementCheck(() => worldExpect), meStripShown, feedHasRounds, onScreen('You and Devon are both in\\.', 'the clash')) },
  { family: 'home', id: 'member-invited', variant: 'member', title: 'Home · a member with an invitation waiting',
    world: { flags: { inviteEvent: true } }, drive: worldDrive,
    expect: { view: 'view-home', selectors: { '#notifBanner .notifrow': 'visible' } },
    check: all(arrangementCheck(() => worldExpect), onScreen('Harper put you on The Fixture Showdown\\.', 'the invitation')) },
  { family: 'home', id: 'inbox', variant: 'member', title: 'Home · the notifications sheet, from the bell',
    drive: async (page) => {
      await until(page, () => { const b = document.getElementById('hdrBell'); return !!b && !b.hidden && b.getBoundingClientRect().width > 0 })
      await click(page, '#hdrBell')
      await until(page, () => !!document.querySelector('#shBody .cs-inbox-n'))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', sheet: '^Notifications$', selectors: { '#shBody .cs-inbox-n.is-unread': 'visible' } },
    check: async (page) => page.evaluate(() => /Devon commented on your round\./.test(document.getElementById('shBody').innerText) ? true : 'the inbox does not name Devon’s comment') },
]

/* --------------------------------------------------------------- golfers */
const DEVON = 'f1000000-0000-4000-8000-000000000004'
const toGolfers = async (page) => {
  /* the real control: the tab at phone widths, the sidebar item at desk widths */
  await page.locator('.tab[data-v="golfers"]:visible, .navitem[data-v="golfers"]:visible').first().click({ timeout: 8000 })
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-golfers')
}
const toDevon = async (page) => {
  await toGolfers(page)
  await until(page, (id) => !!document.querySelector(`#glfBoard .fbrow[data-person="${id}"]`), DEVON)
  /* the board re-renders when the second read lands; a click on the first
     render's row goes to a detached node, so tap again until the page opens */
  for (let i = 0; i < 5; i++) {
    await page.waitForTimeout(400)
    await click(page, `#glfBoard .fbrow[data-person="${DEVON}"]`).catch(() => {})
    const ok = await page.waitForFunction(() => (document.querySelector('.view.active') || {}).id === 'view-person', null, { timeout: 1500 }).then(() => true, () => false)
    if (ok) break
  }
  await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-person' && !!document.getElementById('perOpenH2H'), null, 10000)
}
const GOLFERS = [
  { family: 'golfers', id: 'list', variant: 'member', title: 'Golfers · the board, a request each way, five buddies',
    drive: async (page) => {
      await toGolfers(page)
      await until(page, () => document.querySelectorAll('#glfBoard .fbrow').length >= 2 && /Buddies/.test((document.getElementById('crBud') || {}).innerText || ''))
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-golfers', selectors: { '#glfBoard .fbrow.mine': 'visible', '#crReq': 'text:Requests · 1', '#crBud': 'text:Buddies · 5' } },
    check: async (page) => page.evaluate(() => {
      const rows = document.querySelectorAll('#glfBoard .fbrow').length
      if (rows !== 6) return `the board has ${rows} rows, expected 6 (me and five buddies)`
      if (!/Kit Specimen/.test(document.getElementById('crReq').innerText)) return 'Kit’s request is not listed'
      return /Finley Stubbs/.test(document.getElementById('crBud').innerText) ? true : 'the request I sent Finley is not listed'
    }) },
  { family: 'golfers', id: 'list-empty', variant: 'brand_new', title: 'Golfers · nobody yet',
    drive: async (page) => { await toGolfers(page); await until(page, () => /No buddies yet/i.test((document.getElementById('glfRoot') || {}).innerText || '')); await page.waitForTimeout(300) },
    expect: { view: 'view-golfers', selectors: { '#glfRoot': 'text:No buddies yet' } },
    check: async (page) => page.evaluate(() => document.querySelectorAll('#glfBoard .fbrow').length === 0 ? true : 'a board rendered for a golfer with no buddies') },
  /* EXPECTED TO FAIL on current source: the tap lands on the person page,
     which reads "Couldn't pull that card" for everyone (the builder .catch
     defect above). Kept as the real tap path so the capture records what a
     golfer gets; it turns green when root applies the one-line fix. */
  { family: 'golfers', id: 'person', variant: 'member', title: 'Golfers · a person page (Devon), opened from the board',
    drive: async (page) => {
      await toDevon(page).catch(() => {})
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-person', selectors: { '#perName': 'text:^Devon Testwell$', '#perAside .cred': 'visible', '#perOpenH2H': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const t = document.getElementById('perAside').innerText.replace(/\s+/g, ' ')
      return /The record between you/i.test(t) && /(You lead|Devon Testwell leads|All square)/.test(t) ? true : `the record is missing: ${t.slice(0, 160)}`
    }) },
  /* The person page's only door to the head-to-head is #perOpenH2H, drawn
     after tour_card lands -- and openPerson never gets that far (see the WX
     report: `sb.rpc(...).catch` is not a function on a PostgREST builder, so
     the Promise.all throws before either read is sent and every person page
     reads "Couldn't pull that card"). The head-to-head itself is reached
     through the page's own bridged router, window.openHeadToHead, so its
     design is on record while the door is broken. */
  { family: 'golfers', id: 'h2h', variant: 'member', title: 'Golfers · the head-to-head with Devon (via window.openHeadToHead; the person-page door is broken)',
    drive: async (page) => {
      await toGolfers(page)
      await page.evaluate((id) => window.openHeadToHead(id, 'Devon Testwell'), DEVON)
      await until(page, () => (document.querySelector('.view.active') || {}).id === 'view-h2h' && !!document.querySelector('#h2hMain .csleaf'), null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-h2h', selectors: { '#h2hName': 'text:^You and Devon Testwell$', '#h2hMain .csleaf tbody tr': 'visible', '#h2hMain .cstape': 'visible' } },
    check: async (page) => page.evaluate(() => /The Fixture Derby/i.test(document.getElementById('view-h2h').innerText) ? true : 'the rivalry name is missing') },
  { family: 'golfers', id: 'board', variant: 'member', title: 'The league board · chat, round posts, kudos, a comment count', fullPage: false,
    drive: async (page) => {
      await page.evaluate(() => window.switchView('board'))
      await until(page, () => document.getElementById('boardFull').classList.contains('open') && /Anyone up for Saguaro Flats/.test((document.getElementById('boardFull') || {}).innerText || ''))
      await page.waitForTimeout(600)
    },
    expect: { selectors: { '#boardFull.open': 'visible', '#bfSub': 'text:NORTH GROVE' } },
    check: async (page) => page.evaluate(() => {
      const t = document.getElementById('boardFull').innerText.replace(/\s+/g, ' ')
      /* a comment lives behind its post's count on the board, not in the row */
      const need = [[/Anyone up for Saguaro Flats on Saturday\?/, 'Casey’s chat'], [/floors close Tuesday/i, 'Blake’s note'], [/\b84\b/, 'my 84']]
      for (const [re, what] of need) if (!re.test(t)) return `${what} is not on the board`
      return true
    }) },
]

export default [...HOME_HATCH, ...HOME_DISPATCH, ...HOME_LEAGUELESS, ...HOME_WORLD, ...GOLFERS]
