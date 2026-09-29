/* Cup Season · ten-capture states, WX-D: LINKS · SETUP · SCHEDULE · COURSES ·
 * SETTINGS & SHEETS · THE STATIC PAGES · THE DESK.
 *
 * Every state is reached through the page's own URL handling, its router or
 * its own controls — never by writing markup. The one accepted exception in
 * the program (the public-round QA hook `window._csShareRender`) is NOT used
 * here: every public card comes from its own /?share= token through
 * share_info, the way a stranger's phone gets it. Each `check` proves the
 * intended surface is the one showing; a fall-through to the Door, Home or a
 * blank pane fails the capture.
 *
 * The answers behind these states: tests/fixtures/ten/rpc/40-links-setup.mjs.
 * The tokens and plan ids: tests/fixtures/ten/links-setup/ids.mjs. */
import { SHARE, CLAIM, JOIN, PLAN, COURSE } from '../fixtures/ten/links-setup/ids.mjs'

/* the catalogue's three helpers, restated (importing ../ten-states.mjs from a
   family module would be a cycle through its top-level await) */
const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const go = (v) => async (page) => { await page.evaluate((v) => window.switchView(v), v); await page.waitForTimeout(900) }

/* ------------------------------------------------------------ settles */
/* the signed-in boot is done: the door is down (or the card gate is up) */
async function bootDone(page, pause = 1800) {
  await page.waitForFunction(() => {
    const ob = document.getElementById('onboard')
    const hidden = ob && (ob.classList.contains('hide') || getComputedStyle(ob).display === 'none')
    return window.bootStep === 'reveal' && hidden
  }, null, { timeout: 20000 })
  await page.waitForTimeout(pause)
}
/* the share view is terminal: no boot, no door check — the card must have
   answered (share_info) and any photo must have loaded or been dropped */
async function shareSettle(page) {
  await page.waitForSelector('#shareView', { timeout: 15000 })
  await until(page, () => { const c = document.getElementById('svCard'); return !!c && !/Opening the card/.test(c.textContent) }, null, 15000)
  await until(page, () => { const im = document.querySelector('#shareView img.sv-photo'); return !im || (im.complete && im.naturalWidth > 0) }, null, 8000).catch(() => {})
  await page.waitForTimeout(400)
}
/* the door, once the signed-out boot has run its link handling */
const doorSettle = (ready) => async (page) => {
  await page.waitForSelector('#onboard', { timeout: 15000 })
  await until(page, ready, null, 15000)
  await page.waitForTimeout(500)
}
/* a request the page made, read off the harness's fetch recorder
   (route-fulfilled requests leave no Resource Timing entry) */
const asked = (page, re) => page.evaluate((src) => (window.__tenNet || []).some((e) => new RegExp(src).test(e.url)), re.source)

/* ---------------------------------------------------- the share checks */
function shareCheck(want) {
  return async (page) => {
    const why = await page.evaluate((want) => {
      const v = document.getElementById('shareView'); if (!v) return 'no #shareView'
      if (getComputedStyle(v).display === 'none') return '#shareView hidden'
      const card = document.getElementById('svCard'); const txt = card ? card.innerText : ''
      if (want.text && !new RegExp(want.text, 'i').test(txt)) return `card ${JSON.stringify(txt.slice(0, 140))} !~ /${want.text}/`
      if (want.round === true && !v.classList.contains('sv-round')) return 'not the round branch'
      if (/\bPTS\b/.test(v.innerText)) return 'private points on a public page'
      if (v.scrollWidth > v.clientWidth + 1) return `horizontal overflow (${v.scrollWidth} > ${v.clientWidth})`
      const photos = v.querySelectorAll('img.sv-photo').length
      if (want.photos != null && photos !== want.photos) return `photos ${photos}, expected ${want.photos}`
      if (window.__tenInjected !== undefined) return 'untrusted copy executed'
      if (want.band === false && v.querySelector('.sv-band')) return 'a band line rendered with no band'
      if (want.band === true && !v.querySelector('.sv-band')) return 'no band line'
      if (want.cta && ![...v.querySelectorAll('a')].some((a) => a.textContent.trim() === want.cta && a.offsetParent !== null)) return `CTA "${want.cta}" missing`
      if (want.title && !new RegExp(want.title).test(document.title)) return `title ${JSON.stringify(document.title)} !~ /${want.title}/`
      return true
    }, want)
    return why
  }
}
const share = (id, token, want, extra = {}) => ({
  family: 'public-round', id, variant: 'signed_out', url: `/?share=${token}`, settle: shareSettle,
  expect: { overlay: true }, check: shareCheck(want), ...extra,
})

const PUBLIC_ROUND = [
  share('public', SHARE.round, { round: true, text: 'Saguaro Flats[\\s\\S]*76[\\s\\S]*Devon Testwell', photos: 0, band: true, cta: 'Play with your people', title: '^Devon Testwell — 76 at ' }),
  share('photo', SHARE.roundPhoto, { round: true, text: 'Blake Sample', photos: 1, band: true, cta: 'Play with your people' }),
  share('long-name-nine', SHARE.roundLong, { round: true, text: 'NINE HOLES[\\s\\S]*Indigo Longname-Fixturington', photos: 0, cta: 'Play with your people' }),
  share('escaped-name', SHARE.roundEscaped, { round: true, text: '<img src=x onerror=', photos: 0, cta: 'Play with your people' }),
  share('no-band', SHARE.roundNoBand, { round: true, text: 'Jules Sandbox', photos: 0, band: false, cta: 'Play with your people' }),
  share('broken-photo', SHARE.roundBroken, { round: true, text: 'Harper Examplar', photos: 0, cta: 'Play with your people' }, { world: { flags: { brokenPhotos: true } }, expectConsole: [/status of 404/] }),
  /* W4 · one public shell and one action wording (craft C, critique B): the
     settled game and the season table say what the round record says, and a
     dead link's action names the product — "Play this" had nothing on the
     page to refer to. The strip is keyed in words and spoken as one image. */
  share('dead-link', SHARE.dead, { text: 'This link is dead', cta: 'Open Cup Season' }),
  share('settlement', SHARE.settlement, { text: 'MATCH PLAY[\\s\\S]*Blake & Devon beat Casey & Gray 3&2', cta: 'Play with your people', title: '^MATCH PLAY at ' },
    { check: async (page) => {
      const base = await shareCheck({ text: 'MATCH PLAY[\\s\\S]*Blake & Devon beat Casey & Gray 3&2', cta: 'Play with your people', title: '^MATCH PLAY at ' })(page)
      if (base !== true) return base
      return page.evaluate(() => {
        const img = document.querySelector('#svCard [role="img"][aria-label]')
        if (!img || !/Blake & Devon won 7 holes, Casey & Gray won 4, 5 halved, closed on 16\./.test(img.getAttribute('aria-label'))) return 'the strip has no spoken summary: ' + (img && img.getAttribute('aria-label'))
        const key = (document.querySelector('.sv-strip p[aria-hidden]') || {}).textContent || ''
        if (!/Blake & Devon won/.test(key) || !/Casey & Gray won/.test(key) || !/Halved/.test(key)) return 'the key does not name all three kinds: ' + key
        return true
      })
    } }),
  share('recap', SHARE.recap, { text: 'NORTH GROVE \\(FIXTURE\\)[\\s\\S]*Fixture Javelinas[\\s\\S]*IN PLAY', cta: 'Play with your people' }),
]

/* ------------------------------------------- claim + invite recipients */
const claimDoor = (id, token, ready, selectors, extra = {}) => ({
  family: 'links', id, variant: 'signed_out', url: `/?claim=${token}`, short: true,
  settle: doorSettle(ready), expect: { door: true, selectors }, ...extra,
})
const LINKS = [
  /* W4 · the round LEADS the door (#obLink, the lead serif) and the status line
     keeps the next step: the same ruled sentence (TERMINOLOGY §6), split,
     with the club in the sentence and the course · tee · day beneath it (no
     number in the serif, §1.4). It was
     one 12.5px mono line under the field (owner H, craft H/B, critique B). */
  claimDoor('claim-valid', CLAIM.valid,
    () => /Enter your email to keep it/.test((document.getElementById('obStatus') || {}).textContent || ''),
    { '#emailbox.open': 'visible', '#obEmailIn': 'visible', '#obLink h1': 'text:^Kit — 91 at Mesquite Wash Golf Club \\(fixture\\)\\.$',
      '#obLink .sub': 'text:^Mesquite Wash · Black · Sun, Sep 27$', '#obStatus': 'text:^Enter your email to keep it\\.$' }),
  claimDoor('claim-scan-partner', CLAIM.scan,
    () => /Enter your email to keep it/.test((document.getElementById('obStatus') || {}).textContent || ''),
    { '#emailbox.open': 'visible', '#obLink h1': 'text:^Kit Specimen — 94 at Papago Fixture Links\\.$', '#obLink .sub': 'text:^North · Gold · Fri, Sep 25$' },
    { world: { errors: { rpc: { guest_live_state: { __error: 'No such round', status: 400 } } } }, expectConsole: [/status of 400/] }),
  claimDoor('claim-used', CLAIM.used,
    () => { try { return localStorage.getItem('cs_claim') === null && (window.__tenNet || []).some((e) => /rpc\/claim_round_info/.test(e.url) && e.status === 200) } catch (_) { return false } },
    /* W4 · a kept scorecard SAYS so (owner R, critique B P2): it was the plain
       door, pixel for pixel. Not an error, and no more than CS_CLAIM_DEAD
       already says to any token. */
    { '#obEmail': 'visible', '#obJoin': 'visible', '#emailbox': 'hidden', '#obStatus': 'text:^That scorecard is already on a golfer’s record\\. If it’s yours, sign in with the same email' },
    { check: async (page) => ((await page.evaluate(() => !document.getElementById('obStatus').classList.contains('err'))) ? true : 'the kept-scorecard line is styled as an error') }),
  claimDoor('claim-unfinished', CLAIM.abandoned,
    () => /never finished/.test((document.getElementById('obStatus') || {}).textContent || ''),
    { '#obStatus.err': 'visible', '#obStatus': 'text:^This round was never finished' },
    { expectConsole: [/^\[cs\] This round was never finished/] }),
  claimDoor('claim-not-started', CLAIM.setup,
    () => /hasn.t teed off yet/.test((document.getElementById('obStatus') || {}).textContent || ''),
    { '#obStatus': 'text:^That round hasn.t teed off yet' },
    { check: async (page) => ((await page.evaluate(() => !document.getElementById('obStatus').classList.contains('err') && localStorage.getItem('cs_claim') !== null)) ? true : 'the not-started line is an error, or the pencil was dropped') }),
  claimDoor('claim-dead', CLAIM.dead,
    () => /expired or was already claimed/.test((document.getElementById('obStatus') || {}).textContent || ''),
    { '#obStatus.err': 'visible', '#obStatus': 'text:^That scorecard link has expired or was already claimed' },
    { world: { errors: { rpc: { guest_live_state: { __error: 'No such round', status: 400 }, scan_claim_info: { __error: 'Claim link not recognized', status: 400 } } } },
      expectConsole: [/^\[cs\] That scorecard link has expired/, /status of 400/] }),
  /* signed in: the card asks before anything is claimed (R5) */
  { family: 'links', id: 'claim-signed-in-ask', variant: 'member', url: `/?claim=${CLAIM.valid}`,
    settle: async (page) => { await bootDone(page, 600); await until(page, () => document.getElementById('sheet').classList.contains('open') && /A scorecard link/.test(document.getElementById('shTitle').textContent), null, 12000); await page.waitForTimeout(500) },
    expect: { sheet: '^A scorecard link$', selectors: { '#lnkYes': 'text:^Add it to my record$', '#lnkNo': 'visible', '#lnkAsk .lead': 'text:Add this 91 at Mesquite Wash' } } },

  /* the league invite link, /?join=CODE (the format shareInvite writes, index.html:27224) */
  /* W4 · the invitation leads the door (#obLink) and the status keeps the next
     step; the invitation is to a season, never "the league" (T §2.3) */
  { family: 'links', id: 'join-valid', variant: 'signed_out', url: `/?join=${JOIN.season}`, short: true,
    settle: doorSettle(() => /invited to North Grove/.test((document.querySelector('#obLink h1') || {}).textContent || '')),
    expect: { door: true, selectors: { '#emailbox.open': 'visible', '#obLink h1': "text:^You’re invited to North Grove \\(fixture\\)\\.$", '#obStatus': 'text:^Sign in to read the terms before you join\\.$' } } },
  /* a code that matches no league says so (owner panel P1: it said "You're
     invited" to a stranger) and is dropped, so signing in tries no join */
  { family: 'links', id: 'join-unavailable', variant: 'signed_out', url: `/?join=${JOIN.dead}`, short: true,
    settle: doorSettle(() => /^No league with that code/.test((document.getElementById('obStatus') || {}).textContent || '') && (window.__tenNet || []).some((e) => /rpc\/league_by_code/.test(e.url) && e.status === 200)),
    expect: { door: true, selectors: { '#emailbox.open': 'visible', '#obStatus': "text:^No league with that code\\. Check with your Pro\\.$", '#obLink': 'hidden' } },
    check: async (page) => ((await page.evaluate(() => localStorage.getItem('cs_code') === null && localStorage.getItem('cs_code_name') === null)) ? true : 'the dead code was kept, or resolved to a name') },
  /* signed in with no league: the covenant gate, before join_league runs */
  { family: 'links', id: 'join-covenant', variant: 'brand_new', url: `/?join=${JOIN.season}`,
    settle: async (page) => { await until(page, () => document.getElementById('sheet').classList.contains('open') && /Before you join/.test(document.getElementById('shTitle').textContent), null, 15000); await page.waitForTimeout(600) },
    expect: { allowDoor: true, sheet: '^Before you join North Grove \\(fixture\\)$',
      selectors: { '#covJoin': 'text:^Join — I’m in for \\$75$', '#covNo': 'visible', '#shBody': 'text:Blake Sample runs the season \\(the Pro\\)' } } },
  { family: 'links', id: 'join-covenant-free', variant: 'brand_new', url: `/?join=${JOIN.free}`,
    settle: async (page) => { await until(page, () => document.getElementById('sheet').classList.contains('open') && /Before you join/.test(document.getElementById('shTitle').textContent), null, 15000); await page.waitForTimeout(600) },
    expect: { allowDoor: true, sheet: '^Before you join South Wash Weekday \\(fixture\\)$',
      selectors: { '#covJoin': 'text:^Join South Wash Weekday \\(fixture\\)$', '#shBody': 'text:every round counts' } } },
  /* signed in and already in: the covenant is not shown again; the line says so */
  { family: 'links', id: 'join-already-in', variant: 'member', url: `/?join=${JOIN.season}`,
    settle: async (page) => { await bootDone(page, 300); await until(page, () => /already in for season 1/.test((document.getElementById('toast') || {}).textContent || ''), null, 8000) },
    expect: { view: 'view-home', selectors: { '#toast': 'text:^You’re already in for season 1\\.$' } }, pause: 50 },
  /* in-app invitation (my_invites): drawn ONCE, then its terms. W4 · the banner
     row and Home's lead drew the same invitation twice with two "See the terms"
     (owner H, critique B P2); the banner row now stands down while the lead
     carries the invitation (csBannerYield), so the invitation is the lead's
     and its door opens the terms. The row itself is the safety net for an
     invitation the dispatch does not carry. */
  { family: 'links', id: 'invite-banner', variant: 'brand_new', world: { flags: { invite: true } },
    settle: async (page) => { await until(page, () => !!document.querySelector('#homeLead [data-dkey^="invite:"]') && !!document.querySelector('#notifBanner [data-ivacc]'), null, 15000); await page.waitForTimeout(500) },
    expect: { allowDoor: false, selectors: { '#homeLead': 'text:put you on North Grove \\(fixture\\)', '#notifBanner': 'hidden' } },
    check: async (page) => page.evaluate(() => /Season invite · North Grove \(fixture\)/.test(document.querySelector('#notifBanner .notifrow b')?.textContent || '') ? true : 'the banner row does not name a Season invite') },
  { family: 'links', id: 'invite-terms', variant: 'brand_new', world: { flags: { invite: true } },
    settle: async (page) => { await until(page, () => !!document.querySelector('#homeLead [data-dgo^="invite:"]'), null, 15000); await page.waitForTimeout(300) },
    drive: async (page) => { await click(page, '#homeLead [data-dgo^="invite:"]'); await until(page, () => /Before you join/.test(document.getElementById('shTitle').textContent) && document.getElementById('sheet').classList.contains('open')) },
    expect: { sheet: '^Before you join North Grove \\(fixture\\)$', selectors: { '#covJoin': 'visible' } } },
  /* the buddy link: the landing card, then the signed-in ask (R5) */
  { family: 'links', id: 'person-landing', variant: 'signed_out', url: `/?p=${SHARE.person}`, settle: shareSettle,
    /* W4 · "wants you in their golf" read as a translation error (critique B) */
    expect: { overlay: true }, check: shareCheck({ text: 'Blake Sample wants to play golf with you[\\s\\S]*7 rounds posted, best 81', cta: 'Get the app' }) },
  { family: 'links', id: 'person-landing-new', variant: 'signed_out', url: `/?p=${SHARE.personNew}`, settle: shareSettle,
    expect: { overlay: true }, check: shareCheck({ text: 'Kit Specimen wants to play golf with you', cta: 'Get the app' }) },
  /* the landing keeps its token (cs_person); opening the app again spends it
     through the ask — the same two steps a golfer takes */
  { family: 'links', id: 'person-signed-in-ask', variant: 'member', url: `/?p=${SHARE.person}`, settle: shareSettle,
    drive: async (page) => {
      await page.goto(new URL('/', page.url()).href, { waitUntil: 'load' })
      await bootDone(page, 600)
      await until(page, () => document.getElementById('sheet').classList.contains('open') && /A buddy link/.test(document.getElementById('shTitle').textContent), null, 12000)
      await page.waitForTimeout(500)
    },
    expect: { sheet: '^A buddy link$', selectors: { '#lnkYes': 'text:^Add as a buddy$', '#lnkAsk .lead': 'text:Add Blake Sample as a buddy\\?' } } },
]

export default [...PUBLIC_ROUND, ...LINKS]
