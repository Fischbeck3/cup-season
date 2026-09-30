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
import { notMono, readsAsWritten, noRetiredGlyph, noRetiredShape, bandContrast, standsDown, destMarked, medallionOnPhotoOnly } from '../ten-mono.mjs'

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

/* TEN / W7-011 [B2-home-2] · the strip's LAST stands down while the wire
   carries the viewer's own newest round anywhere, not only as its first row
   (a buddy's round posted since put LAST back beside the same card). Inert
   when that round is not in the wire. */
const lastOnce = (page) => page.evaluate(() => {
  const last = window.career && (window.career.recent || [])[0]
  if (!last || !(window.homeFeedRows || []).some((r) => r && r.is_me && r.round_id === last.id)) return true
  const seen = (el) => { const b = el.getBoundingClientRect(); return b.width > 0 && b.height > 0 && getComputedStyle(el).visibility !== 'hidden' }
  const row = [...document.querySelectorAll('#sideMe [data-mego="my_last_round"], #homeMe [data-mego="my_last_round"]')].filter(seen)
  return row.length ? 'the strip prints LAST beside the wire’s card for the same round' : true
})
/* TEN / W7-037 [A2-home-2] · the viewer's own next round is printed once:
   when a lead or deck `plan:` item is the strip's own NEXT round (the phone's
   HomeDispatch.columnFacts), the desk's strip has no NEXT row and the phone's
   Up next chip stands down. The state must actually carry that plan item, so
   the check cannot pass on a world that never exercises it. */
const nextOnce = async (page) => page.evaluate(() => {
  const nx = (typeof csMeStrip === 'function' ? csMeStrip().slots || [] : []).find((s) => s.fact === 'my_next_round' && !s.ph)
  const plans = [...document.querySelectorAll('#homeLead [data-dgo^="plan:"], #homeDeck [data-dgo^="plan:"]')].map((e) => e.getAttribute('data-dgo').slice(5))
  if (!nx || !plans.includes(String(nx.id))) return 'this state has no deck plan line for the strip’s own next round, so it proves nothing'
  const seen = (el) => { const b = el.getBoundingClientRect(); return b.width > 0 && b.height > 0 && getComputedStyle(el).visibility !== 'hidden' }
  const row = [...document.querySelectorAll('#sideMe [data-mego="my_next_round"], #homeMe [data-mego="my_next_round"]')].filter(seen)
  if (row.length) return 'the strip prints NEXT beside the deck’s plan line for the same round'
  const chip = [...document.querySelectorAll('#homeUpNext *')].filter((el) => seen(el) && /^Next round/i.test((el.textContent || '').trim()))
  return chip.length ? 'the Up next chip prints the round the deck already carries' : true
})
/* the ME strip: #homeMe below desk width, #sideMe in the sidebar at desk width */
const meStripShown = (page) => page.evaluate(() => {
  const vis = (el) => { if (!el) return false; const r = el.getBoundingClientRect(), cs = getComputedStyle(el); return r.width > 0 && r.height > 0 && cs.display !== 'none' && cs.visibility !== 'hidden' }
  const el = [document.getElementById('homeMe'), document.getElementById('sideMe')].find(vis)
  return el && el.innerText.trim().length > 0 ? true : 'the ME strip is empty or hidden'
})
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
/* TEN / W6 (root, 2026-09-28) · a BRAND-NEW golfer's strip holds only
   placeholders — `— BUILDING`, `NO ROUNDS YET`, `PLAN ONE`. The phone stands
   it down (MeStripCopy's `allEmpty`, HomeFacts' placeholder filter: native
   parity; the lead already says the first round is missing) and the desk's
   sidebar prints ONE sentence with ONE door. `meStripShown` pinned the old
   three-placeholder strip at every width. */
/* TEN / W7-030 [A2-home-3] · on the desk, Home's lead is the first round and
   its "Add my round", so the sidebar's empty block (the sentence and its own
   "Add my round") stands down while that lead is on the page: one door in the
   window. The block is still drawn, and speaks again on every other view. */
const meStripBrandNew = async (page) => {
  const r = await page.evaluate(() => {
    const home = document.getElementById('homeMe'), side = document.getElementById('sideMe')
    if (innerWidth < 960) return !(home && home.innerText.trim()) ? true : 'the phone strip did not stand down: ' + JSON.stringify(home.innerText.trim().slice(0, 80))
    const seen = (el) => { const b = el.getBoundingClientRect(); return b.width > 0 && b.height > 0 && b.bottom > 0 && b.top < innerHeight && getComputedStyle(el).visibility !== 'hidden' }
    const doors = [...document.querySelectorAll('a, button')].filter((el) => /^Add my round$/i.test(el.textContent.trim()) && seen(el))
    if (doors.length !== 1) return `${doors.length} "Add my round" doors in one window: ` + doors.map((d) => d.closest('[id]')?.id || d.tagName).join(', ')
    const say = side && side.querySelector('.mesay'), door = side && side.querySelector('.medoors')
    const held = ((say && say.textContent) || '') + ' ' + ((door && door.textContent) || '')
    if (!/Your number builds itself from three posted rounds\./.test(held) || !/Add my round/i.test(held)) return 'the desk strip does not hold the sentence and its door: ' + JSON.stringify(held.trim().slice(0, 140))
    if (/BUILDING|NO ROUNDS YET|PLAN ONE/.test(side.textContent)) return 'the desk strip shows placeholders'
    if (seen(say) || seen(door)) return 'the sidebar says the first round is missing beside the lead that says it'
    if (side.getBoundingClientRect().height >= 1 || parseFloat(getComputedStyle(side).borderTopWidth) > 0) return 'the emptied block still stands in the sidebar: a rule over an empty band'
    const foot = document.querySelector('.side .foot'), col = foot && foot.parentElement
    if (!foot || col.getBoundingClientRect().bottom - foot.getBoundingClientRect().bottom > 48) return 'the sidebar\'s foot left the bottom of the column'
    if (!document.getElementById('sideWho') || !seen(document.getElementById('sideWho'))) return 'the sidebar lost the golfer'
    return 'desk'
  })
  if (r !== 'desk') return r
  /* on another desk view the sentence and its door speak again */
  await page.evaluate(() => window.switchView('golfers'))
  await page.waitForTimeout(400)
  const back = await page.evaluate(() => { const say = document.querySelector('#sideMe .mesay'); return !!say && getComputedStyle(say).display !== 'none' })
  await page.evaluate(() => window.switchView('home'))
  await page.waitForTimeout(400)
  return back ? true : 'the sidebar\'s sentence stayed down off Home'
}
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
/* TEN / W6 · W7-095 · 'Later' and 'Didn’t play' wear §7.1's in-content rule: 2px of mut, not a 1px rule-coloured hairline (inert where no answer is drawn) */
const answersRule = async (page) => page.evaluate(() => {
  const bs = [...document.querySelectorAll('.csans-b')].filter((b) => b.getBoundingClientRect().height > 0)
  if (!bs.length) return true
  const i = document.createElement('i'); i.style.color = 'var(--mut)'; document.body.appendChild(i); const mut = getComputedStyle(i).color; i.remove()
  const bad = bs.find((b) => { const cs = getComputedStyle(b); return cs.borderBottomWidth !== '2px' || cs.borderBottomColor !== mut })
  return bad ? `an answer's rule is ${getComputedStyle(bad).borderBottomWidth} ${getComputedStyle(bad).borderBottomColor}, not 2px of mut` : true
})
/* TEN / W6 · W7-094 · on Home a buddy request's Accept and Decline are tertiary in-content links, never two filled .mini buttons
   beside the lead's door (inert where Home draws no request) */
const requestsQuiet = async (page) => page.evaluate(() => {
  const bs = [...document.querySelectorAll('#homeRequests .hreq-acts button')].filter((b) => b.getBoundingClientRect().height > 0)
  if (!bs.length) return true
  if (bs.some((b) => b.classList.contains('mini'))) return 'Home draws the request’s answers as filled .mini buttons'
  const bad = bs.find((b) => { const cs = getComputedStyle(b); return !/underline/.test(cs.textDecorationLine) || parseFloat(cs.textDecorationThickness) !== 2 || cs.backgroundColor !== 'rgba(0, 0, 0, 0)' })
  return bad ? 'a request answer is not the in-content link: ' + bad.textContent.trim() : true
})
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
    check: all(arrangementCheck(() => ex), meStripShown, lastOnce, answersRule, requestsQuiet),
  }
})

/* TEN / W8 · W7-077 [A2-home-16] · 'Didn’t play' is a terminal answer (D345), so its first tap only ASKS ('Sure? Nothing posts for that day', neg) and sends nothing; 'Later' stays one tap and the row keeps its two answers */
HOME_DISPATCH.push({
  family: 'home', id: 'dispatch-after_golf-armed', variant: 'member',
  title: 'Home · after golf: Didn’t play tapped once (armed, not answered)',
  world: { flags: { homeState: 'after_golf' } },
  drive: async (page) => { await homePainted(page); await page.locator('[data-ans="didnt_play"]').first().scrollIntoViewIfNeeded(); await click(page, '[data-ans="didnt_play"]'); await page.waitForTimeout(400) },
  expect: { view: 'view-home', selectors: { '[data-ans="didnt_play"]': 'text:^Sure\\? Nothing posts for that day$' } },
  check: all(async (page) => page.evaluate(() => {
    const b = document.querySelector('[data-ans="didnt_play"]'), later = document.querySelector('[data-ans="later"]')
    if (!b.classList.contains('is-armed')) return 'the first tap did not arm Didn\u2019t play'
    if (!later || later.classList.contains('is-armed') || later.textContent.trim() !== 'Later') return 'Later is not the plain one-tap answer'
    const neg = (() => { const i = document.createElement('i'); i.style.color = 'var(--neg)'; document.body.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c })()
    if (getComputedStyle(b).color !== neg) return `the armed answer is ${getComputedStyle(b).color}, not neg`
    return (window.__tenNet || []).some((e) => /answer_plan_followup/.test(e.url)) ? 'the first tap sent the answer' : true
  })),
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
/* TEN / W6 · W7-073 · the empty wire is ONE sentence with its door inside it ("No rounds from your buddies yet. Post one, or add
   some buddies."), the door §2.5's in-content link: ink on a 2px mut rule, a hit box of 44 */
const wireEmptyOneLine = async (page) => page.evaluate(() => {
  const p = document.querySelector('#homeFeed .wire-empty')
  if (!p || p.getBoundingClientRect().height === 0) return 'the empty wire is not drawn'
  const a = p.querySelector('a[data-gopeople], a[data-wiretable]')
  if (!a) return 'the wire’s door is not inside its sentence'
  const t = p.textContent.replace(/\s+/g, ' ').trim()
  if (!/^No rounds from your buddies yet\. (Post one, or add some buddies\.|See who’s in .+\.)$/.test(t)) return 'the sentence reads ' + JSON.stringify(t)
  const cs = getComputedStyle(a)
  if (!/underline/.test(cs.textDecorationLine) || parseFloat(cs.textDecorationThickness) !== 2) return 'the door is not the in-content link'
  return a.getBoundingClientRect().height >= 40 ? true : `the door's hit box is ${Math.round(a.getBoundingClientRect().height)}px tall`
})
/* TEN / W6 · W7-074 · the lead's eyebrow breaks on its · separators, never inside a clause ('CLOSES IN' / '5 DAYS') */
const eyebrowClauses = async (page) => page.evaluate(() => {
  const eb = document.querySelector('#homeLead .csedn .eb > span:not(.dot):not(.cstate)')
  if (!eb) return 'the lead draws no eyebrow'
  const words = []
  const w = document.createTreeWalker(eb, NodeFilter.SHOW_TEXT)
  for (let n = w.nextNode(); n; n = w.nextNode()) {
    const re = /\S+/g; let m
    while ((m = re.exec(n.textContent))) { const r = document.createRange(); r.setStart(n, m.index); r.setEnd(n, m.index + m[0].length); const b = r.getClientRects()[0]; if (b) words.push({ t: m[0], top: Math.round(b.top) }) }
  }
  for (let i = 1; i < words.length; i++) {
    if (words[i].top > words[i - 1].top + 2 && words[i - 1].t !== '\u00b7' && words[i].t !== '\u00b7') return `the eyebrow breaks inside a clause: "${words[i - 1].t}" / "${words[i].t}"`
  }
  return true
})
/* TEN / W6 · W7-080 · a brand-new golfer's first-round door is the page's one primary and no promo stands beside it */
const brandNewPrimary = async (page) => page.evaluate(() => {
  const go = document.querySelector('#homeLead [data-dgo^="first_round"]')
  if (!go) return 'the lead has no first-round door'
  if (!go.classList.contains('btn')) return 'the first-round door is not the primary: ' + go.className
  const occ = document.querySelector('#homeOccasion .hocc')
  return occ && occ.getBoundingClientRect().height > 0 ? 'a promo stands beside a brand-new golfer’s first round' : true
})
/* TEN / W6 · W7-080 · a calendar promo's door is the in-content link, ink on a 2px mut rule, never the action colour */
const promoQuiet = async (page) => page.evaluate(() => {
  const a = document.querySelector('#homeOccasion .hocc .ho-act')
  if (!a) return 'no promo drawn here, so its door cannot be read'
  const probe = (v) => { const i = document.createElement('i'); i.style.color = `var(${v})`; document.body.appendChild(i); const c = getComputedStyle(i).color; i.remove(); return c }
  const cs = getComputedStyle(a), sp = getComputedStyle(a.querySelector('span'))
  if (cs.color === probe('--act')) return 'the promo’s door wears the action colour'
  if (cs.color !== probe('--ink')) return 'the promo’s door is not ink: ' + cs.color
  return /underline/.test(sp.textDecorationLine) && parseFloat(sp.textDecorationThickness) === 2 ? true : 'the promo’s door has no 2px rule'
})
/* TEN / W6 · W7-081 · the month is a fact, not a chip: no "Month closes" in Up next, and ONE quiet month line under the season row
   in the strip on screen, in SeasonFacts.monthRow's words ("Best 4 a month count · 5/2 toward the minimum · 1 day left in September") */
const monthFact = async (page) => page.evaluate(() => {
  const up = (document.getElementById('homeUpNext') || {}).innerText || ''
  if (/month closes/i.test(up)) return 'the "Month closes" chip is still drawn'
  const lines = [...document.querySelectorAll('#sideMe .memonth, #homeMe .memonth')].filter((p) => p.getBoundingClientRect().height > 0)
  if (lines.length !== 1) return `${lines.length} month line(s) on screen, expected one`
  const t = lines[0].textContent.trim()
  return /^(Best \d+ a month count|Every round counts) · (.+ · )?(\d+ days? left in|last day of) [A-Z][a-z]+$/.test(t) ? true : 'the month line reads ' + JSON.stringify(t)
})
/* TEN / W6 · AW2-01 · Home opens once: by the time it is on screen the cold open's hold has let go (no data-held, no
   aria-busy), and no lead slot is still keeping room for a lead that already answered. The jump itself is measured by the
   CLS probe (layout-shift entries through a cold signed-in boot, 375 and 1280, CPU 1x and 4x), not by a still frame. */
const homeShownOnce = async (page) => page.evaluate(() => {
  const v = document.getElementById('view-home')
  if (!v) return 'no Home view'
  if (v.hasAttribute('data-held') || v.getAttribute('aria-busy') === 'true') return 'Home is still held after the boot settled'
  if (v.getBoundingClientRect().height === 0) return 'Home has no height on screen'
  const lead = document.getElementById('homeLead')
  return lead && lead.hasAttribute('data-coming') ? 'the lead slot still keeps room for a lead that already answered' : true
})
/* TEN / W6 · W7-083 · a wire card is no role="button" around four buttons: it is a plain block whose one receipt control is a real
   button, named with the printed story, beside the face, applause, course and comment buttons */
const cardsNotButtons = async (page) => page.evaluate(() => {
  const cards = [...document.querySelectorAll('#homeFeed .hfcard')].filter((c) => c.getBoundingClientRect().height > 0)
  if (!cards.length) return 'the wire draws no round card'
  for (const c of cards) {
    if (c.getAttribute('role') === 'button' || c.hasAttribute('tabindex')) return 'a round card is still a role="button" wrapper'
    const r = c.querySelectorAll('button[data-rcptbtn]')
    if (r.length !== 1) return `a round card has ${r.length} receipt buttons`
    const story = (c.querySelector('.hfr-story') || {}).textContent
    if (story && !r[0].getAttribute('aria-label').includes(story.trim())) return 'the receipt button is not named with the printed story'
  }
  return true
})
const HOME_LEAGUELESS = [
  { family: 'home', id: 'league-less-brand_new', variant: 'brand_new', title: 'Home signed in, S1 brand-new (no league): the dispatch lead; the hero stands down',
    drive: async (page) => { await until(page, () => /first round/i.test((document.getElementById('homeLead') || {}).innerText || ''), null, 10000); await page.waitForTimeout(300) },
    expect: { view: 'view-home' }, check: all(leadShown('first round.*add my round'), meStripBrandNew, wireEmptyOneLine, brandNewPrimary) },
  { family: 'home', id: 'league-less-rounds_no_buddies', variant: 'rounds_no_league', title: 'Home signed in, S2 rounds and no buddies (no league): the dispatch lead; the hero stands down',
    drive: async (page) => { await until(page, () => /nobody has seen it/i.test((document.getElementById('homeLead') || {}).innerText || ''), null, 10000); await page.waitForTimeout(300) },
    expect: { view: 'view-home' }, check: all(leadShown('nobody has seen it.*find golfers'), meStripShown,
      /* TEN / W8 · W7-076 [A2-home-15]: the rail's door names the verb every other surface prints: 'Plan a round', not 'Plan one' */
      async (page) => page.evaluate(() => { if (innerWidth < 960) return true; const a = document.querySelector('#sideMe [data-mego="plan_one"]'); return a && a.textContent.trim() === 'Plan a round' ? true : `the rail's plan door reads ${JSON.stringify(a && a.textContent)}` }), async (page) => page.evaluate(() => document.querySelectorAll('#homeFeed [data-hfr]').length > 0 ? true : 'my own rounds are not in the feed')) },
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
/* TEN / W8 · W7-087 [A2-home-14, B2-home-13] · a wire row about something ahead wears a clock ('2 days', 'Tomorrow'), and never repeats its own weekday as its marker: 'Wed · You have a round on Wednesday.' */
const wireStamps = async (page) => page.evaluate(() => {
  const lines = [...document.querySelectorAll('.cswire')].filter((l) => l.getBoundingClientRect().width > 0)
  if (!lines.length) return 'the wire draws no lines'
  const days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
  for (const l of lines) {
    const mk = l.querySelector('.mk').textContent.trim(), ln = l.querySelector('.ln').textContent
    if (!/^(Today|Tomorrow|\d+ days|[A-Z][a-z]{2}( \d{1,2})?)$/.test(mk)) return `a wire marker reads ${JSON.stringify(mk)}`
    for (const d of days) if (new RegExp(`\\b${d}\\b`).test(ln) && mk.toLowerCase() === d.slice(0, 3).toLowerCase()) return `a wire line repeats its own weekday as its marker: ${JSON.stringify(mk + ' \u00b7 ' + ln.trim().slice(0, 60))}`
  }
  return true
})
/* TEN / W8 · W7-105 [B2-home-18] · the sidebar's five destinations run the tab bar's order (D222, the phone's NavSlot): Home, Compete, Play, Golfers, You; at the desk width, where it is drawn */
const sidebarOrder = async (page) => page.evaluate(() => {
  const side = [...document.querySelectorAll('aside.side .navitem[data-v]:not(.sub)')].filter((b) => b.getBoundingClientRect().width > 0).map((b) => b.dataset.v)
  if (!side.length) return true
  return side.slice(0, 5).join(',') === 'home,compete,record,golfers,stats' ? true : `the sidebar runs ${side.slice(0, 5).join(', ')}, not Home, Compete, Play, Golfers, You`
})
/* TEN / W8 · W7-075 [A2-home-13, B2-home-12] · one day, one format: every round on Home's wire prints its day as HomeWireCopy.dayMarker does (Today, a weekday inside six days, else 'Sep 25'), on the record's
   line and on the photo plate alike; a stamped card said 'FRI' over an unstamped card that said 'SEP 25' for the same Friday */
const dayMarkers = async (page) => page.evaluate(() => {
  const rows = window.homeFeedRows || [], cards = [...document.querySelectorAll('[data-hfr]')]
  let checked = 0
  for (const c of cards) {
    const r = rows[+c.dataset.hfr]; if (!r || !r.played_on) continue
    const el = c.querySelector('.hfr-day, .hsday'); if (!el) continue
    checked++
    const want = window.csDayMarker(r.played_on)
    if (el.textContent.trim().toLowerCase() !== want.toLowerCase()) return `a round of ${r.played_on} prints its day as ${JSON.stringify(el.textContent.trim())}, not the marker ${JSON.stringify(want)}`
  }
  return checked ? true : 'no round card on Home carries a day'
})
const feedHasRounds = async (page) => page.evaluate(() => document.querySelectorAll('#homeFeed [data-hfr]').length > 0 ? true : 'the circle feed drew no rounds')

/* TEN / W7-050 [A2-home-11] · what is read and tabbed to is what is seen:
   below 960 the Home blocks' DOM order is their painted order (no CSS
   `order` over the desk's DOM). On the desk, ↓ moves from a deck line to the
   next slat (UI_SYSTEM §14.4). */
const readingOrder = async (page) => {
  const r = await page.evaluate(() => {
    if (innerWidth >= 960) return 'desk'
    const ids = ['#homeLead', '#homeRequests', '#homeMe', '#homeDeck', '#homeHero', '#homeHub > .deskwire', '#homeUpNext', '#homeTiles', '#homeOccasion', '#homeStart', '#homePulse']
    const els = ids.map((s) => document.querySelector(s)).filter((el) => el && el.getBoundingClientRect().height > 0)
    if (els.length < 3) return 'Home drew too few blocks to read an order'
    const dom = els.slice().sort((a, b) => (a.compareDocumentPosition(b) & Node.DOCUMENT_POSITION_FOLLOWING ? -1 : 1))
    const seen = els.slice().sort((a, b) => a.getBoundingClientRect().top - b.getBoundingClientRect().top)
    const name = (el) => el.id || el.className
    return dom.every((el, i) => el === seen[i]) ? true
      : 'the reading order is not the painted order: DOM ' + dom.map(name).join(' > ') + ' | seen ' + seen.map(name).join(' > ')
  })
  if (r !== 'desk') return r
  const lines = await page.evaluate(() => [...document.querySelectorAll('#homeDeck .cswire, #homeFeed [data-rcptbtn]')].filter((el) => el.offsetParent !== null).length)
  if (lines < 2) return true
  await page.evaluate(() => { const f = [...document.querySelectorAll('#homeDeck .cswire, #homeFeed [data-rcptbtn]')].find((el) => el.offsetParent !== null); f.focus(); window.__slat0 = f })
  await page.keyboard.press('ArrowDown')
  const moved = await page.evaluate(() => { const a = document.activeElement; const ok = a && a !== window.__slat0 && a.matches('.cswire, [data-rcptbtn]'); if (document.activeElement && document.activeElement.blur) document.activeElement.blur(); return ok })
  return moved ? true : '↓ on a deck line does not move to the next slat'
}
/* TEN / W7-051 [B2-home-3] · a course's circle is printed once per wire, on its newest round */
const circleOnce = async (page) => page.evaluate(() => {
  const ids = [...document.querySelectorAll('#homeFeed .hfr-course[data-hfcourse]')].map((b) => b.dataset.hfcourse)
  if (!ids.length) return 'no course circle in this wire'
  const dup = ids.find((id, i) => ids.indexOf(id) !== i)
  return dup ? 'one course’s circle prints twice in the wire: ' + dup : true
})
const HOME_WORLD = [
  /* North Grove week 8 of 13, the Fixture Wrens 2nd of 2 and 34 back; the
     week-8 clash with Devon ("The Fixture Derby"), both in; Kit's buddy
     request; Devon's 76 on the wire */
  { family: 'home', id: 'member-populated', variant: 'member', title: 'Home · a member in week 8 (this world’s own dispatch)',
    drive: worldDrive, expect: { view: 'view-home' },
    check: all(arrangementCheck(() => worldExpect), meStripShown, feedHasRounds, dayMarkers, sidebarOrder, wireStamps, nextOnce, readingOrder, circleOnce, eyebrowClauses, promoQuiet, monthFact, cardsNotButtons, homeShownOnce,
      onScreen('THE FIXTURE DERBY · THE CLASH · CLOSES IN 5 DAYS', 'the clash eyebrow'), onScreen('You and Devon are both in\\.', 'the clash'),
      onScreen('Kit wants to be golf buddies\\.', 'Kit’s request')) },
  { family: 'home', id: 'pro', variant: 'pro', title: 'Home · the Pro of North Grove',
    drive: worldDrive, expect: { view: 'view-home' },
    check: all(arrangementCheck(() => worldExpect), meStripShown, feedHasRounds, onScreen('You and Devon are both in\\.', 'the clash')) },
  { family: 'home', id: 'member-invited', variant: 'member', title: 'Home · a member with an invitation waiting',
    world: { flags: { inviteEvent: true } }, drive: worldDrive,
    /* TEN (W3, 2026-09-28) · one owner per fact, the phone's rule: an
       invitation the served dispatch carries is ITS item (here a wire line
       with "See the terms"), so the in-place banner stands down for it —
       the banner and the line printed the same invitation twice. The banner
       still draws any invitation the dispatch does not carry. */
    expect: { view: 'view-home', selectors: { '#homeDeck [data-dgo^="invite:"]': 'visible' } },
    check: all(arrangementCheck(() => worldExpect), onScreen('Harper put you on The Fixture Showdown\\.', 'the invitation'),
      async (page) => page.evaluate(() => document.querySelector('#notifBanner .notifrow') ? 'the invitation is drawn twice (banner and wire)' : true)) },
  { family: 'home', id: 'inbox', variant: 'member', title: 'Home · the notifications sheet, from the bell',
    drive: async (page) => {
      await until(page, () => { const b = document.getElementById('hdrBell'); return !!b && !b.hidden && b.getBoundingClientRect().width > 0 })
      await click(page, '#hdrBell')
      await until(page, () => !!document.querySelector('#shBody .cs-inbox-n'))
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', sheet: '^Notifications$', selectors: { '#shBody .cs-inbox-n.is-unread': 'visible' } },
    /* TEN / W8 · W7-117 [B2-home-17] · the inbox line names the CLUB as stored ('Mesquite Wash Golf Club (fixture)'), not the whole 'club — course' label with the layout repeating the club (the phone's glance rule) */
    check: async (page) => page.evaluate(() => {
      if (!/Devon commented on your round\./.test(document.getElementById('shBody').innerText)) return 'the inbox does not name Devon’s comment'
      const metas = [...document.querySelectorAll('#shBody .cs-inbox-n .cs-agate-s')].map((e) => e.textContent.trim()).filter((t) => t)
      const whole = metas.find((t) => / \u2014 /.test(t))
      if (whole) return `an inbox line prints the whole course label: ${JSON.stringify(whole)}`
      return metas.some((t) => /Mesquite Wash Golf Club \(fixture\)/.test(t)) ? true : `no inbox line names the club: ${JSON.stringify(metas)}`
    }) },
  /* TEN / W7-036 [A2-home-10] · HOME_STATE_MATRIX S18 (UI_SYSTEM §13.3): a
     failed dispatch read keeps what is on the screen and says so. */
  /* (a) nothing was ever read: the lead slot says S18's sentence with Try
     again, the season hero stays down (the strip owns the standing), and Try
     again really reads again */
  { family: 'home', id: 'dispatch-failed', variant: 'member', title: 'Home · the dispatch read fails and nothing was read before: S18’s sentence, Try again',
    world: { errors: { rpc: { home_dispatch: { __error: 'fixture: the desk could not be reached', status: 503, code: 'XX000' } } } },
    expectConsole: [/status of 503/],
    drive: async (page) => {
      await until(page, () => !!document.querySelector('#homeLead .homefail'), null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', selectors: { '#homeLead .homefail [data-hretry]': 'visible' } },
    check: async (page) => {
      const r = await page.evaluate(() => {
        const lead = document.querySelector('#homeLead .homefail')
        const said = (lead.innerText || '').replace(/\s+/g, ' ').trim()
        if (!/^Cup Season can’t reach the desk right now\. Nothing here is missing — it just hasn’t arrived\. Try again$/i.test(said)) return 'the lead slot does not say S18’s sentence: ' + JSON.stringify(said)
        if ((document.getElementById('homeHero') || {}).innerHTML) return 'the season hero drew beside the failure (the standing twice)'
        return (window.__tenNet || []).filter((e) => /\/rpc\/home_dispatch/.test(e.url)).length
      })
      if (typeof r !== 'number') return r
      await click(page, '#homeLead [data-hretry]')
      await until(page, (n) => (window.__tenNet || []).filter((e) => /\/rpc\/home_dispatch/.test(e.url)).length > n, r, 8000).catch(() => {})
      await until(page, () => !!document.querySelector('#homeLead .homefail [data-hretry]:not([disabled])'), null, 8000).catch(() => {})
      return page.evaluate((n) => {
        const reads = (window.__tenNet || []).filter((e) => /\/rpc\/home_dispatch/.test(e.url)).length
        if (reads <= n) return 'Try again did not read the desk again'
        return document.querySelector('#homeLead .homefail [data-hretry]') ? true : 'after Try again the lead slot lost its sentence'
      }, r)
    } },
  /* (b) a good read, then a refresh that fails: the kept lead stays, every
     door live, under "As of <day time> · couldn’t refresh" in the agate role */
  { family: 'home', id: 'dispatch-stale', variant: 'member', title: 'Home · a refresh fails after a good read: the lead is kept, AS OF … · COULDN’T REFRESH',
    expectConsole: [/status of 503/],
    drive: async (page, ctx) => {
      await homePainted(page)
      const lead = await page.evaluate(() => (document.querySelector('#homeLead .csedn .hl') || {}).textContent || '')
      await page.evaluate((t) => { window.__keptLead = t }, lead)
      ctx.world.handlers.home_dispatch = () => ({ __error: 'fixture: the refresh failed', status: 503, code: 'XX000' })
      await page.evaluate(() => window.refreshHomeLead())
      await until(page, () => !!document.querySelector('#homeLead .homestale'), null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', selectors: { '#homeLead .homestale': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const st = document.querySelector('#homeLead .homestale')
      const t = st.textContent.trim()
      if (!/^As of (Sun|Mon|Tue|Wed|Thu|Fri|Sat) \d{1,2}:\d{2} (AM|PM) · couldn’t refresh$/.test(t)) return 'the stale line reads ' + JSON.stringify(t)
      if (getComputedStyle(st).textTransform !== 'uppercase') return 'the stale line is not the agate role (its caps are typed, or missing)'
      const hl = (document.querySelector('#homeLead .csedn .hl') || {}).textContent || ''
      if (!window.__keptLead || hl !== window.__keptLead) return 'the lead was not kept: ' + JSON.stringify({ before: window.__keptLead, after: hl })
      const act = document.querySelector('#homeLead .csedn .act')
      if (act && act.disabled) return 'a door on the kept lead is disabled'
      if (st.compareDocumentPosition(document.querySelector('#homeLead .csedn')) & Node.DOCUMENT_POSITION_PRECEDING) return 'the stale line is not above the lead'
      return true
    }) },
  /* TEN / W7-038 [A2-home-9] · UI_SYSTEM §13.3, D220: a failed circle read is
     never an empty wire. */
  /* (a) nothing was ever read and the wire has nothing to show (the circle's
     read and the league's moments both fail): the shared failed root, with Try
     again that reads again, and never "No rounds from your buddies yet". With
     moments in hand, the wire draws them (the phone's rule: failed AND empty) */
  { family: 'home', id: 'feed-failed', variant: 'member', title: 'Home · the wire’s reads fail with nothing read before: the failed root, Try again',
    world: { errors: { rpc: { home_feed: { __error: 'fixture: the circle could not be read', status: 503, code: 'XX000' } },
      /* a 500, not a 503: the client library retries a GET on 503 with a
         backoff, so a 503 here keeps the wire in its skeleton for 15s+ */
      table: { posts: { __error: 'fixture: the moments could not be read', status: 500 } } } },
    expectConsole: [/status of 50[03]/],
    drive: async (page) => {
      await until(page, () => !!document.querySelector('#homeFeed .emptyroot [data-erdoor="retry"]'), null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', selectors: { '#homeFeed .emptyroot [data-erdoor="retry"]': 'visible' } },
    check: async (page) => {
      const n = await page.evaluate(() => {
        const t = (document.getElementById('homeFeed').innerText || '').replace(/\s+/g, ' ')
        if (/No rounds from your buddies yet/i.test(t)) return 'a failed read says the wire is empty'
        if (!/Couldn’t load this\./.test(t) || !/That is us, not you/.test(t)) return 'the failed root does not speak: ' + JSON.stringify(t.slice(0, 160))
        return (window.__tenNet || []).filter((e) => /\/rpc\/home_feed/.test(e.url)).length
      })
      if (typeof n !== 'number') return n
      await click(page, '#homeFeed [data-erdoor="retry"]')
      await until(page, (k) => (window.__tenNet || []).filter((e) => /\/rpc\/home_feed/.test(e.url)).length > k, n, 8000).catch(() => {})
      return page.evaluate((k) => (window.__tenNet || []).filter((e) => /\/rpc\/home_feed/.test(e.url)).length > k ? true : 'Try again did not read the circle again', n)
    } },
  /* (b) a good read, then a refresh that fails: the rows stay, every door
     live, under "As of <day time> · couldn’t refresh" in the agate role */
  { family: 'home', id: 'feed-stale', variant: 'member', title: 'Home · a circle refresh fails after a good read: the rows stay, AS OF … · COULDN’T REFRESH',
    expectConsole: [/status of 503/],
    drive: async (page, ctx) => {
      await homePainted(page)
      await until(page, () => document.querySelectorAll('#homeFeed [data-hfr]').length > 0, null, 10000)
      await page.evaluate(() => { window.__keptRows = document.querySelectorAll('#homeFeed [data-hfr]').length })
      ctx.world.handlers.home_feed = () => ({ __error: 'fixture: the refresh failed', status: 503, code: 'XX000' })
      await page.evaluate(() => window.loadHome())
      await until(page, () => !!document.querySelector('#homeFeed .homestale'), null, 10000)
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-home', selectors: { '#homeFeed .homestale': 'visible' } },
    check: async (page) => page.evaluate(() => {
      const st = document.querySelector('#homeFeed .homestale'), t = st.textContent.trim()
      if (!/^As of (Sun|Mon|Tue|Wed|Thu|Fri|Sat) \d{1,2}:\d{2} (AM|PM) · couldn’t refresh$/.test(t)) return 'the stale line reads ' + JSON.stringify(t)
      if (getComputedStyle(st).textTransform !== 'uppercase') return 'the stale line is not the agate role'
      const rows = document.querySelectorAll('#homeFeed [data-hfr]').length
      if (rows !== window.__keptRows) return `the rows were not kept: ${window.__keptRows} before, ${rows} after`
      if (/No rounds from your buddies yet/i.test(document.getElementById('homeFeed').innerText)) return 'a failed refresh says the wire is empty'
      const first = document.querySelector('#homeFeed [data-hfr]')
      return st.compareDocumentPosition(first) & Node.DOCUMENT_POSITION_FOLLOWING ? true : 'the stale line is not above the rows'
    }) },
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
/* TEN / W8 · W7-100 [A2-golfers-8] · the meeting tape's end dates stand under their own end squares and the label column (YOURS / THEIRS) has nothing beneath it: 'SEP 21' stacked under 'THEIRS'
   at the right edge, so the Sep 21 square (which is yours) read as theirs */
const tapeDates = async (page) => page.evaluate(() => {
  const tape = document.querySelector('.cstape'); if (!tape) return 'no meeting tape on the page'
  const ticks = [...tape.querySelectorAll('.ticks i')], dates = [...tape.querySelectorAll('.tapedates span')], rows = tape.querySelector('.rows')
  if (!dates.length) return 'the tape prints no end dates'
  if (dates.length !== 2) return `the tape prints ${dates.length} end dates`
  const first = ticks[0].getBoundingClientRect(), last = ticks[ticks.length - 1].getBoundingClientRect(), a = dates[0].getBoundingClientRect(), z = dates[1].getBoundingClientRect()
  if (Math.abs(a.left - first.left) > 2) return `the first date starts ${Math.round(a.left - first.left)}px from the first square`
  if (Math.abs(z.right - last.right) > 2) return `the last date ends ${Math.round(z.right - last.right)}px from the last square`
  if (rows) { const r = rows.getBoundingClientRect(); if (z.right > r.left + 0.5) return 'the last date runs under the label column' }
  return true
})
/* TEN / W7-044 [B2-golfers-3] · one golfer, one disc: the board and the
   buddies list draw the same (pigment, glyph) pair, face() for both. The state
   must show at least one golfer in both, or it proves nothing. */
const oneDisc = async (page) => page.evaluate(() => {
  const discOf = (el) => el && el.querySelector('.fc')
  const board = new Map([...document.querySelectorAll('.fbrow[data-person]')].map((r) => [r.dataset.person, discOf(r)]))
  const list = new Map([...document.querySelectorAll('.prow .pmk[data-tc]')].map((m) => [m.dataset.tc, m.querySelector('.fc') || m]))
  const both = [...board.keys()].filter((id) => list.has(id) && board.get(id) && list.get(id))
  if (!both.length) return 'no golfer is on both the board and the buddies list in this state'
  const probe = document.createElement('span'); probe.style.background = 'var(--bg2)'; document.body.appendChild(probe)
  const plain = getComputedStyle(probe).backgroundColor; probe.remove()
  for (const id of both) {
    const a = board.get(id), b = list.get(id)
    if (a.querySelector('img.face') || b.querySelector('img.face')) continue
    const ba = getComputedStyle(a).backgroundColor, bb = getComputedStyle(b).backgroundColor
    if (ba !== bb) return `one golfer, two discs: ${ba} on the board, ${bb} in the list`
    if (bb === plain) return 'the list’s disc is plain, not the golfer’s pigment'
  }
  return true
})
/* TEN / W7-045 [A2-golfers-7] · the person page's ONE primary is the way to
   play, in the aside under the record; "See the whole record" is a tier-3
   link, never the heavier door */
const playPrimary = async (page) => page.evaluate(() => {
  const seen = (el) => { const b = el.getBoundingClientRect(); return b.width > 0 && b.height > 0 && getComputedStyle(el).visibility !== 'hidden' }
  const plays = [...document.querySelectorAll('#perMain [data-playwith], #perAside [data-playwith]')].filter(seen)
  if (plays.length !== 1) return `${plays.length} play doors on the page, expected one`
  const play = plays[0]
  if (!play.closest('#perAside')) return 'the play door is not in the aside, under the record'
  if (!play.classList.contains('btn') || play.classList.contains('dark')) return 'the play door is not the page’s primary'
  const others = [...document.querySelectorAll('#perMain .btn, #perAside .btn')].filter((b) => seen(b) && b !== play && !b.classList.contains('dark'))
  if (others.length) return 'another primary competes with the play door: ' + others.map((b) => b.id || b.textContent.trim()).join(', ')
  const rec = document.getElementById('perOpenH2H')
  if (rec && (rec.tagName !== 'A' || rec.classList.contains('btn') || !rec.closest('.hstart'))) return '“See the whole record” still outweighs the act'
  return /they’re in it from the start\./.test(play.parentElement.textContent) ? true : 'the play door lost its line'
})
/* TEN / W7-046 [A2-golfers-9] · a golfer reports what another golfer wrote:
   never the viewer's own post, never a server-written moment or standings
   line; and moderation stays reachable on another golfer's post */
const reportOthers = async (page) => page.evaluate(() => {
  const me = window.CS && window.CS.user && window.CS.user.id
  const rc = window.roundCache || {}
  const mine = (f) => (f.pid ? f.pid === me : !!(f.roundpost && rc[f.rid] && rc[f.rid].profile_id === me))
  const btns = [...document.querySelectorAll('button[data-report]')].filter((b) => b.offsetParent !== null)
  for (const b of btns) {
    const f = feed[+b.dataset.report]
    if (!f) continue
    if ((f.msg || f.roundpost) && mine(f)) return 'Report on the viewer’s own post: ' + JSON.stringify(String(f.txt || f.who).slice(0, 60))
    if (f.moment) return 'Report on a server-written moment: ' + JSON.stringify(String(f.txt).slice(0, 60))
    if (f.sys && !f.srid) return 'Report on a server-written line: ' + JSON.stringify(String(f.txt).slice(0, 60))
  }
  const others = feed.filter((f) => f && f.post_id && (f.msg || f.roundpost) && !mine(f))
  if (others.length && !btns.length) return 'no Report anywhere: moderation is unreachable'
  return true
})
/* TEN / W7-048 [B2-golfers-13] · one course name, printed one way: the club,
   and the layout only where the club does not already say it; never the tee */
const oneCourseName = async (page) => page.evaluate(() => {
  const bare = (x) => String(x || '').toLowerCase().replace(/[^\p{L}\p{N}]+/gu, ' ').trim()
  const names = [...document.querySelectorAll('#perMain .dtab tr td:first-child')].map((td) => td.textContent.trim()).filter(Boolean)
  if (!names.length) return 'the person page lists no courses'
  for (const n of names) {
    const [club, layout] = n.split(' — ')
    if (layout && bare(club).includes(bare(layout))) return 'a course prints its name twice: ' + JSON.stringify(n)
    if (/ · /.test(n)) return 'a course prints its tee: ' + JSON.stringify(n)
  }
  return true
})
/* TEN / W8 · W7-084 [A2-golfers-10, B2-golfers-8]: the board says a squad in WORDS. The 3.5px squad-colour stripe down a post's edge (a spine, §0.3, and colour
   alone, §16.4) is gone from every post, round or chat; a round names its golfer's squad in its agate line beside the season table's swatch; a chat line
   names nothing; a golfer with no squad (a solo season) gets no swatch and no name, and the fallback colour that painted a squad who did not exist is gone.
   `solo` is the control: the same board in a league that has no squads. */
const SWATCH = { 'Fixture Wrens': 'var(--sq0)', 'Fixture Javelinas': 'var(--sq1)' }
const squadInWords = (solo) => async (page) => page.evaluate(({ solo, SWATCH }) => {
  const list = document.getElementById('feedListFull')
  if (!list) return 'the board has no list'
  const bars = list.querySelectorAll('.round .bar, .msgrow .bar')
  if (bars.length) return `${bars.length} post(s) still draw the squad stripe down their edge`
  const rounds = [...list.querySelectorAll('.fcard .round')]
  if (!rounds.length) return 'no round card on the board to read'
  if (list.querySelectorAll('.msgrow .sw').length) return 'a chat line carries a squad swatch (a chat line names nothing)'
  for (const r of rounds) {
    const l2 = r.querySelector('.l2'), sw = l2 && l2.querySelector('.sw')
    if (solo) {
      if (sw) return 'a solo season\'s round draws a swatch for a squad that does not exist'
      if (/[·\s]$/.test(l2.textContent.trim())) return `a solo round's agate line ends on a separator: ${JSON.stringify(l2.textContent.trim().slice(-20))}`
      continue
    }
    const said = /Fixture (Wrens|Javelinas)/.exec(l2 ? l2.textContent : '')
    if (!said) return `a round names no squad in its agate line: ${JSON.stringify(l2 && l2.textContent.trim())}`
    if (!sw) return `${said[0]} is named with no swatch beside it`
    if (sw.getBoundingClientRect().width < 3 || sw.getBoundingClientRect().height < 10) return `the swatch beside ${said[0]} has no box (${sw.getBoundingClientRect().width}x${sw.getBoundingClientRect().height})`
    if (sw.style.background.replace(/\s+/g, '') !== SWATCH[said[0]].replace(/\s+/g, '')) return `${said[0]} wears ${sw.style.background}, not ${SWATCH[said[0]]}`
    if (!sw.nextSibling || sw.nextSibling.textContent.trim() !== said[0]) return 'the squad\'s name is not beside its swatch'
    const rg = document.createRange(); rg.selectNodeContents(sw.nextSibling)
    const nr = rg.getClientRects()[0], sr = sw.getBoundingClientRect()
    if (nr && Math.abs((sr.top + sr.height / 2) - (nr.top + nr.height / 2)) > 8) return `${said[0]}\'s swatch is a line away from its name`
  }
  return true
}, { solo, SWATCH })
const SOLO_LEAGUE = 'f3000000-0000-4000-8000-000000000002'   /* South Wash Weekday (fixture): a solo season, no squads */
const GOLFERS = [
  { family: 'golfers', id: 'list', variant: 'member', title: 'Golfers · the board, a request each way, five buddies',
    drive: async (page) => {
      await toGolfers(page)
      /* TEN (W3) · case-blind: the head renders "BUDDIES · 5" (innerText follows
         the caps role) and the rows no longer repeat a mixed-case "Buddies" tag */
      await until(page, () => document.querySelectorAll('#glfBoard .fbrow').length >= 2 && /Buddies/i.test((document.getElementById('crBud') || {}).innerText || ''))
      await page.waitForTimeout(400)
    },
    /* TEN (W3, 2026-09-28) · one request block: the head block
       (#peopleRequests, D177) owns Kit's request, and the REQUESTS section
       under the search lists only what it does not — it drew Kit twice, with
       two Accepts */
    expect: { view: 'view-golfers', selectors: { '#glfBoard .fbrow.mine': 'visible', '#peopleRequests': 'text:Kit Specimen', '#crBud': 'text:Buddies · 5' } },
    check: all(
      async (page) => page.evaluate(() => document.querySelector('#glfShareDisclosure')?.textContent === window.CS_PERSON_SHARE_DISCLOSURE && !!window.CS_PERSON_SHARE_DISCLOSURE ? true : 'card link disclosure missing'),
      /* TEN / W8 · W7-023 [B2-desk-9]: from 1100 up the ranking's rows sit inside one reading measure (760), not the whole track */
      async (page) => page.evaluate(() => {
        if (innerWidth < 1100) return true
        const w = Math.max(...[...document.querySelectorAll('#glfBoard .fbrow')].map((r) => r.getBoundingClientRect().width))
        return w <= 762 ? true : `a ranking row is ${Math.round(w)}px wide, past the 760px reading measure`
      }),
      async (page) => page.evaluate(() => {
      const rows = document.querySelectorAll('#glfBoard .fbrow').length
      if (rows !== 6) return `the board has ${rows} rows, expected 6 (me and five buddies)`
      if (!/Kit Specimen/.test(document.getElementById('peopleRequests').innerText)) return 'Kit’s request is not listed'
      if (/Kit Specimen/.test(document.getElementById('crReq').innerText)) return 'Kit’s request is drawn twice'
      return /Finley Stubbs/.test(document.getElementById('crBud').innerText) ? true : 'the request I sent Finley is not listed'
    }),
    /* TEN / W6 · AW2-15: the form lens's note is a phrase, in sentence case (§1.3) */
    readsAsWritten([['.fbnote', 'Vs playing HCP \u00b7 plus is better']]),
    /* TEN / W7-044 [B2-golfers-3]: one golfer, one disc, on the board and in the buddies list */
    oneDisc) },
  { family: 'golfers', id: 'list-empty', variant: 'brand_new', title: 'Golfers · nobody yet',
    drive: async (page) => { await toGolfers(page); await until(page, () => /No buddies yet/i.test((document.getElementById('glfRoot') || {}).innerText || '')); await page.waitForTimeout(300) },
    expect: { view: 'view-golfers', selectors: { '#glfRoot': 'text:No buddies yet' } },
    check: all(async (page) => page.evaluate(() => document.querySelectorAll('#glfBoard .fbrow').length === 0 ? true : 'a board rendered for a golfer with no buddies'),
      async (page) => page.evaluate(() => { const notes = [...document.querySelectorAll('#view-golfers .fine')].filter(e => e.getBoundingClientRect().height > 0 && e.textContent === window.CS_PERSON_SHARE_DISCLOSURE); return notes.length === 1 ? true : 'empty-root card link disclosures: ' + notes.length }),
      /* TEN / W6 · N4-063 (TERMINOLOGY §1 row 7): the sub is the lead, and the definition is said once, under it,
         word for word the phone's GolfersRoot.buddyDefinition, in the body role (sans, never mono or serif) */
      async (page) => page.evaluate(() => {
        const root = document.getElementById('glfRoot'), sub = root && root.querySelector('.emptyroot .sub'), def = root && root.querySelector('.emptyroot .def')
        if (!sub || sub.textContent !== 'Add the people you actually play with.') return `the sub reads ${JSON.stringify(sub && sub.textContent)}`
        if (!def || def.textContent !== 'Buddies see each other\u2019s rounds, and either of you can pull the other into a season.') return `the definition reads ${JSON.stringify(def && def.textContent)}`
        if (sub.compareDocumentPosition(def) !== Node.DOCUMENT_POSITION_FOLLOWING) return 'the definition is not under the sub'
        const f = getComputedStyle(def).fontFamily.split(',')[0]
        if (/mono|serif|new york|georgia/i.test(f) && !/sans/i.test(f)) return `the definition is set in ${f}`
        return (root.innerText.match(/see each other/gi) || []).length === 1 ? true : 'the definition is said more than once'
      }),
      /* TEN / W8 · W7-085 [A2-golfers-12]: the empty root has ONE act, the link, as the primary; 'Find golfers' was a second door to the search field under it, which is the find door;
         and nothing on the page types an arrow */
      async (page) => page.evaluate(() => {
        const root = document.getElementById('glfRoot'), doors = [...root.querySelectorAll('.doors button')], field = document.getElementById('crFind')
        if (doors.map((d) => d.textContent.trim()).join('|') !== 'Text someone a link') return `the root's doors read ${JSON.stringify(doors.map((d) => d.textContent.trim()))}, expected the link alone`
        if (!doors[0].classList.contains('btn')) return 'the link is not the primary'
        const r = field && field.getBoundingClientRect(), d = doors[0].getBoundingClientRect()
        if (!r || !(r.width > 0)) return 'the search field is not drawn under the root'
        if (r.top < d.bottom - 1) return 'the search field is not under the root\u2019s act'
        const t = document.getElementById('view-golfers').innerText
        return /[\u2192\u203a]/.test(t) ? 'the page types an arrow' : true
      })) },
  /* EXPECTED TO FAIL on current source: the tap lands on the person page,
     which reads "Couldn't pull that card" for everyone (the builder .catch
     defect above). Kept as the real tap path so the capture records what a
     golfer gets; it turns green when root applies the one-line fix. */
  /* TEN / W8 · W7-091 [A2-golfers-4] · the report sheet: before a reason is picked its Send is the DISABLED primary (bg1 fill, mut label, never the act fill); the reasons are a named group of
     toggle chips; the picked one is the chip's selected state (ink fill, aria-pressed), and only one is; then Send is the live primary. The state reads the pre-pick paint in its drive and pins
     the picked state on the capture */
  { family: 'golfers', id: 'report-sheet', variant: 'member', fullPage: false, title: 'Golfers · a report sheet with a reason picked (Send goes live)',
    drive: async (page) => {
      await toDevon(page)
      await page.waitForTimeout(300)
      await click(page, '#view-person [data-safety]')
      await until(page, () => document.getElementById('sheet').classList.contains('open') && !!document.getElementById('sfReasons'), null, 10000)
      await page.waitForTimeout(300)
      await page.evaluate(() => {
        const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
        const b = document.getElementById('sfSend'), cs = getComputedStyle(b), g = document.getElementById('sfReasons')
        window.__tenPre = (!b.disabled ? 'Send is live before a reason is picked' : cs.backgroundColor !== probe('--bg1') || cs.color !== probe('--mut')
          ? `the disabled Send is ${cs.backgroundColor} on ${cs.color}, not bg1 with a mut label`
          : g.getAttribute('role') !== 'group' || g.getAttribute('aria-label') !== 'Reason' ? 'the reasons are not a named group'
          : [...g.querySelectorAll('button')].some((x) => x.getAttribute('aria-pressed') !== 'false' || x.classList.contains('sel')) ? 'a reason is marked before one is picked' : true)
      })
      await page.locator('#sfReasons [data-sfr]').nth(1).click({ timeout: 8000 })
      await page.waitForTimeout(400)
    },
    expect: { view: 'view-person', sheet: true, selectors: { '#sfSend': 'text:^Send this report$' } },
    check: async (page) => page.evaluate(() => {
      if (window.__tenPre !== true) return window.__tenPre
      const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
      const chips = [...document.querySelectorAll('#sfReasons [data-sfr]')], on = chips.filter((x) => x.getAttribute('aria-pressed') === 'true')
      if (on.length !== 1 || on[0].dataset.sfr !== '1') return `${on.length} reason(s) pressed, expected the second alone`
      if (!on[0].classList.contains('sel') || getComputedStyle(on[0]).backgroundColor !== probe('--ink')) return `the picked reason is ${getComputedStyle(on[0]).backgroundColor}, not the chip's ink selected fill`
      if (chips.some((x) => x !== on[0] && (x.classList.contains('sel') || x.getAttribute('aria-pressed') !== 'false'))) return 'another reason is still marked'
      const b = document.getElementById('sfSend')
      return !b.disabled && getComputedStyle(b).backgroundColor === probe('--act') ? true : `Send is ${b.disabled ? 'disabled' : getComputedStyle(b).backgroundColor}, not the live action fill`
    }) },
  { family: 'golfers', id: 'person', variant: 'member', title: 'Golfers · a person page (Devon), opened from the board',
    drive: async (page) => {
      await toDevon(page).catch(() => {})
      await page.waitForTimeout(300)
    },
    expect: { view: 'view-person', selectors: { '#perName': 'text:^Devon Testwell$', '#perAside .cred': 'visible', '#perOpenH2H': 'visible' } },
    check: all(destMarked('golfers'),   /* TEN / W8 · W7-108: a golfer's page is a room of GOLFERS, so GOLFERS stays marked */
      async (page) => page.evaluate(() => {
      /* the verdict is the head's sentence at the desk (W7-010 stands the aside's headline down there) and the aside's headline on the phone */
      const aside = document.getElementById('perAside').innerText.replace(/\s+/g, ' ')
      const t = document.getElementById('view-person').innerText.replace(/\s+/g, ' ')
      /* X36 (1) · the sum names its facet, "across every meeting", and nothing claims to be "the" record */
      if (/the (whole )?record/i.test(aside)) return 'the aside still claims to be the record: ' + aside.slice(0, 160)
      return /Between you/i.test(aside) && /(You lead|Devon Testwell leads|All square)[^.]*across every meeting\./.test(t) && /See every meeting/.test(aside) ? true : `the record is missing or unnamed: ${t.slice(0, 160)}`
    }),
    /* TEN / W6 · AW2-06: the back link is agate and the record's labels body — never mono */
    notMono(['#view-person .backlink', '#perAside .mathrow > span'], ['#view-person .backlink', '#perAside .mathrow > span']),
    noRetiredGlyph(),
    /* TEN / W8 · W7-010: at the desk the head says the record in prose and the season row as a figure, so the aside's bold headline stands down */
    standsDown(['#perAside .perhl']),
    /* TEN / W7-045 [A2-golfers-7]: the page's one primary is the way to play, in the aside under the record */
    playPrimary,
    /* TEN / W7-048 [B2-golfers-13]: one course name, printed one way (the club, the layout only where the club does not say it, never the tee) */
    oneCourseName,
    /* Q47 · Devon's crest card wears no gold-ringed medallion (§6.5 row 3) */
    medallionOnPhotoOnly()) },
  /* TEN / W8 · W7-019 · at the desk a click on the scrim closes the board, as the sheet's does (a dialog) */
  { family: 'golfers', id: 'board-scrim', variant: 'member', desk: true, fullPage: false, title: 'The league board, dismissed by a click on the scrim (desk)',
    drive: async (page) => {
      await page.evaluate(() => window.switchView('board'))
      await until(page, () => document.getElementById('boardFull').classList.contains('open'))
      await page.waitForTimeout(400)
      await page.mouse.click(20, 20)
      await page.waitForTimeout(500)
    },
    expect: { selectors: { '#boardFull.open': 'hidden' } },
    check: async (page) => page.evaluate(() => document.getElementById('boardFull').classList.contains('open') ? 'a click on the scrim did not close the board' : true) },
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
    /* TEN (W3, 2026-09-28) · ONE TITLE: a christened rivalry's name is the
       page's head, and the pairing ("You and Devon Testwell") is its agate
       line — the page used to print the pairing twice around the name */
    expect: { view: 'view-h2h', selectors: { '#h2hName': 'text:^The Fixture Derby$', '#h2hMain .csleaf tbody tr': 'visible', '#h2hMain .cstape': 'visible' } },
    check: all(tapeDates, async (page) => page.evaluate(() => {
      const t = document.getElementById('view-h2h').innerText
      if (!/You and Devon Testwell/i.test(t)) return 'the pairing is missing'
      return document.querySelectorAll('#view-h2h .cs-display').length ? 'a second display title is on the page' : true
    })) },
  { family: 'golfers', id: 'board', variant: 'member', title: 'The league board · chat, round posts, kudos, a comment count', fullPage: false,
    drive: async (page) => {
      await page.evaluate(() => window.switchView('board'))
      await until(page, () => document.getElementById('boardFull').classList.contains('open') && /Anyone up for Saguaro Flats/.test((document.getElementById('boardFull') || {}).innerText || ''))
      await page.waitForTimeout(600)
    },
    expect: { selectors: { '#boardFull.open': 'visible', '#bfSub': 'text:NORTH GROVE' } },
    check: all(async (page) => page.evaluate(() => {
      const t = document.getElementById('boardFull').innerText.replace(/\s+/g, ' ')
      /* a comment lives behind its post's count on the board, not in the row */
      const need = [[/Anyone up for Saguaro Flats on Saturday\?/, 'Casey’s chat'], [/floors close Tuesday/i, 'Blake’s note'], [/\b84\b/, 'my 84']]
      for (const [re, what] of need) if (!re.test(t)) return `${what} is not on the board`
      /* TEN / W6 · DX2 OB2-01: a photo card has the ceremony ground under its
         picture, so its light ink never sits on the light page while the
         photo loads or fails */
      const photo = [...document.querySelectorAll('#boardFull .fcard .round.has-photo')]
      if (!photo.length) return 'no photo card on the board to read'
      const ground = (c) => { const i = document.createElement('i'); i.style.color = 'var(--ceremony)'; c.appendChild(i); const v = getComputedStyle(i).color; i.remove(); return v }
      const bare = photo.filter((c) => getComputedStyle(c).backgroundColor !== ground(c))
      if (bare.length) return `${bare.length} photo card(s) have no ground: ${getComputedStyle(bare[0]).backgroundColor}`
      return true
    }),
    /* TEN / W8 · W7-019 [A2-golfers-3, B2-golfers-4, A2-desk-3, B2-desk-3]: at the desk the board is the sheet's dialog, not the phone's takeover stretched
       edge to edge: a centred panel of 720 at most on the sheet's scrim, 82dvh at most, its cards inside the measure and a round's photo the
       2.1:1 band (§6.4); below 960 the panel dissolves and the board is the full screen, as before (D93/D223) */
    async (page) => page.evaluate(() => {
      const panel = document.querySelector('#boardFull .bf-panel'), r = panel.getBoundingClientRect()
      if (innerWidth < 960) return getComputedStyle(panel).display === 'contents' ? true : 'the phone board is not the full-screen takeover (the panel did not dissolve)'
      if (r.width > 720.5) return `the desk board is ${Math.round(r.width)}px wide, past the 720px reading measure`
      if (Math.abs(r.left + r.width / 2 - innerWidth / 2) > 2) return 'the desk board is not centred'
      if (r.height > innerHeight * 0.82 + 1) return `the desk board is ${Math.round(r.height)}px tall in a ${innerHeight}px window`
      const scrim = getComputedStyle(document.getElementById('boardFull')).backgroundColor
      if (!/rgba\(/.test(scrim)) return `the board has no scrim behind it: ${scrim}`
      const wide = [...document.querySelectorAll('#feedListFull .fcard')].filter((c) => c.getBoundingClientRect().width > 720)
      if (wide.length) return `${wide.length} post(s) are wider than the measure`
      const ph = document.querySelector('#feedListFull .fcard .round.has-photo'), pr = ph && ph.getBoundingClientRect()
      return !pr || (pr.width / pr.height > 2.0 && pr.width / pr.height < 2.25) ? true : `a photo card is ${Math.round(pr.width)}x${Math.round(pr.height)}, not the 2.1:1 band`
    }),
    squadInWords(false),
    /* TEN / W6 · AW2-06 + OB-05: a round card's course line and its margin's
       unit are agateS; only the margin's figure keeps mono (the column role) */
    notMono(['#boardFull .round .l2', '#boardFull .round .pvi small', '#bfTitle', '#feedListFull .datesep'], ['#boardFull .round .l2', '#boardFull .round .pvi small', '#bfTitle', '#feedListFull .datesep']),
    /* TEN / W6 · AW2-08: the report control is a word, not ⚑; no retired glyph on the board */
    noRetiredGlyph(),
    /* TEN / W6 · AW2-13: the reaction bar's controls and the tags are not pills, and the system row has no spine */
    noRetiredShape(),
    /* TEN / W7-046 [A2-golfers-9]: Report is for what another golfer wrote, never your own post or the server's lines */
    reportOthers,
    /* TEN / W6 · E's twin (N4-087, root's ruling (b)) · §10.3: the photo card is the wire's case. It has
       the ONE scrim's `.band` geometry (leading → trailing), the points on the bone panel, the margin in
       the copy column, and its copy measured on the fixture photo */
    async (page) => page.evaluate(() => {
      const c = [...document.querySelectorAll('#boardFull .fcard .round.has-photo')].find((e) => e.getBoundingClientRect().height > 0)
      if (!c) return 'no photo card on the board to read'
      const bg = getComputedStyle(c, '::before').backgroundImage
      if (!/^linear-gradient\((to right|90deg)/.test(bg)) return `the photo card's scrim is not the band (leading → trailing): ${bg.slice(0, 80)}`
      const tok = (n) => { const i = document.createElement('i'); i.style.color = `var(${n})`; c.appendChild(i); const v = getComputedStyle(i).color; i.remove(); return v }
      const pts = c.querySelector('.pts')
      if (pts && getComputedStyle(pts).backgroundColor !== tok('--panel')) return `the points are not on the bone panel: ${getComputedStyle(pts).backgroundColor}`
      if (c.querySelector(':scope > .pvi')) return 'the margin sits on the band\u2019s clear end'
      return true
    }),
    bandContrast('#boardFull .fcard .round.has-photo', [
      { name: 'name', sel: '.l1 span' }, { name: 'course', sel: '.l2' }, { name: 'gross', sel: '.rline' },
      { name: 'counting', sel: '.rline .ok, .rline .dim' }, { name: 'margin', sel: '.pvi-line b, .pvi', own: true },
      { name: 'margin unit', sel: '.pvi-line small, .pvi small' }, { name: 'points', sel: '.pts', own: true, large: true },
      { name: 'points unit', sel: '.pts small' }])) },
  /* TEN / W8 · W7-084's control: the board of a league that has no squads (a solo season) draws round posts with no stripe, no swatch and no name */
  { family: 'golfers', id: 'board-solo', variant: 'member', title: 'The league board of a solo season (South Wash Weekday): round posts, no squad', fullPage: false,
    drive: async (page) => {
      await page.evaluate((id) => window.enterLeagueById(id, false), SOLO_LEAGUE)
      await until(page, () => /South Wash/.test((window.CS && window.CS.league && window.CS.league.name) || ''), null, 15000)
      await page.evaluate(() => window.switchView('board'))
      await until(page, () => document.getElementById('boardFull').classList.contains('open') && document.querySelectorAll('#feedListFull .fcard .round').length > 0, null, 15000)
      await page.waitForTimeout(600)
    },
    expect: { selectors: { '#boardFull.open': 'visible' } },
    check: all(async (page) => page.evaluate(() => /SOUTH WASH/i.test(document.getElementById('bfSub').textContent) ? true : `the board is not the second league's: ${document.getElementById('bfSub').textContent}`),
      squadInWords(true)) },
]

export default [...HOME_HATCH, ...HOME_DISPATCH, ...HOME_LEAGUELESS, ...HOME_WORLD, ...GOLFERS]
