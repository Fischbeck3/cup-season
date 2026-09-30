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
      /* TEN / W6 · AW2-14: a public page's one action is its primary, in act (§16A.5, D359) */
      if (want.cta && ![...v.querySelectorAll('a.sv-action.is-primary')].some((a) => a.textContent.trim() === want.cta)) return `the page's one action "${want.cta}" is not its primary`
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
  /* TEN / W8 · W7-058 [A2-public-round-4]: a dead link says ONE fresh-one sentence for every kind of link (share_info answers the same null for all of them, D57),
     never 'from the round' */
  share('dead-link', SHARE.dead, { text: 'This link is dead[\\s\\S]*Whoever sent it can share a fresh one\\.', cta: 'Open Cup Season' },
    { check: async (page) => {
      const base = await shareCheck({ text: 'This link is dead[\\s\\S]*Whoever sent it can share a fresh one\\.', cta: 'Open Cup Season' })(page)
      if (base !== true) return base
      return page.evaluate(() => /from the round/i.test(document.getElementById('svCard').innerText) ? 'a dead link of any kind says "from the round"' : true)
    } }),
  share('settlement', SHARE.settlement, { text: 'MATCH PLAY[\\s\\S]*Blake & Devon beat Casey & Gray 3&2', cta: 'Play with your people', title: '^MATCH PLAY at ' },
    { check: async (page) => {
      const base = await shareCheck({ text: 'MATCH PLAY[\\s\\S]*Blake & Devon beat Casey & Gray 3&2', cta: 'Play with your people', title: '^MATCH PLAY at ' })(page)
      if (base !== true) return base
      return page.evaluate(() => {
        const img = document.querySelector('#svCard [role="img"][aria-label]')
        if (!img || !/Blake & Devon won 7 holes, Casey & Gray won 4, 5 halved, closed on 16\./.test(img.getAttribute('aria-label'))) return 'the strip has no spoken summary: ' + (img && img.getAttribute('aria-label'))
        const key = (document.querySelector('.sv-strip p[aria-hidden]') || {}).textContent || ''
        if (!/Blake & Devon won/.test(key) || !/Casey & Gray won/.test(key) || !/Halved/.test(key)) return 'the key does not name all three kinds: ' + key
        /* TEN / W6 · AW2-14: the sides are told by name and by pattern (full or half height) — never by ember */
        if ([...document.querySelectorAll('.sv-strip span[style]')].some((s) => /var\(--brand\)/.test(s.getAttribute('style')))) return 'the strip paints a side in ember'
        /* TEN / W8 · W7-057 [A2-public-round-2]: the four scores are a column of bare figures, so it carries a head (§16A.3): Golfers over the names and Gross over the
           figures, the second right-aligned over them — the recap's table names its Points the same way */
        const head = document.querySelector('.sv-colhead'), rows = document.querySelector('.sv-rows'), fig = rows && rows.querySelector('.fig')
        if (!head || !/^GOLFERS\s+GROSS$/i.test(head.innerText.replace(/\s+/g, ' ').trim())) return 'the settlement scores have no head: ' + JSON.stringify(head && head.innerText)
        if (head.nextElementSibling !== rows) return 'the head is not directly above the rows'
        const g = head.lastElementChild.getBoundingClientRect(), f = fig.getBoundingClientRect()
        return Math.abs(g.right - f.right) <= 1.5 ? true : `Gross sits ${Math.round(g.right - f.right)}px off the figures' right edge`
      })
    } }),
  /* TEN / W8 · W7-138 [A2-public-round-7]: the season's state is in the dateline, not an orphan agate label under the rows; when the story already says how long is
     left ('with N weeks to play') no 'In play' is printed at all */
  share('recap', SHARE.recap, { text: 'NORTH GROVE \\(FIXTURE\\)[\\s\\S]*Fixture Javelinas', cta: 'Play with your people' },
    { check: async (page) => {
      const base = await shareCheck({ text: 'NORTH GROVE \\(FIXTURE\\)[\\s\\S]*Fixture Javelinas', cta: 'Play with your people' })(page)
      if (base !== true) return base
      return page.evaluate(() => {
        const card = document.getElementById('svCard'), dl = (card.querySelector('.sv-eb') || {}).innerText || '', story = (card.querySelector('.sv-story') || {}).innerText || ''
        if (card.querySelector('.sv-status')) return 'the recap still prints an orphan status label under the rows'
        const carries = /to play\.?$/.test(story.trim())
        if (carries && /In play|Final/i.test(dl)) return `the dateline repeats the state the story already says: ${JSON.stringify(dl)} / ${JSON.stringify(story)}`
        if (!carries && !/In play|Final/i.test(dl)) return `nothing says the season's state: ${JSON.stringify(dl)} / ${JSON.stringify(story)}`
        return true
      })
    } }),
]

/* ------------------------------------------- claim + invite recipients */
const claimDoor = (id, token, ready, selectors, extra = {}) => ({
  family: 'links', id, variant: 'signed_out', url: `/?claim=${token}`, short: true,
  settle: doorSettle(ready), expect: { door: true, selectors }, ...extra,
})
/* TEN / W8 · W7-107 [A2-claim-invite-1, B2-claim-invite-1, A2-claim-invite-11, A2-desk-10] · a scorecard link that cannot land is the LANDING at the top, as the dead
   league code is (41cf8050): announced as a status, the outcome's first sentence in the lead in INK (a spent link is not the golfer's error, §2.5) and what to do
   under it, the status line under the field empty, and the email field below the landing, focus on the lead. The kind is claim-<outcome>, never 'dead'. */
const outcomeLanding = (kind) => async (page) => page.evaluate((kind) => {
  const el = document.querySelector(`#obLink[data-kind="${kind}"]`); if (!el) return `no #obLink[data-kind="${kind}"] landing is drawn`
  if (el.getAttribute('role') !== 'status') return 'the landing is not announced as a status'
  const h = el.querySelector('h1'), sub = el.querySelector('.sub')
  if (!h || !sub) return 'the landing has no lead and sub'
  const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
  if (getComputedStyle(h).color !== probe('--ink')) return `the lead is ${getComputedStyle(h).color}, not ink`
  const st = (document.getElementById('obStatus').textContent || '').trim()
  if (st !== '') return `the status line under the field still speaks: ${JSON.stringify(st)}`
  if (!document.getElementById('onboard').classList.contains('ob-linked')) return 'the generic welcome is still the lead (the hero did not collapse)'
  if (!(el.compareDocumentPosition(document.getElementById('obEmail')) & Node.DOCUMENT_POSITION_FOLLOWING)) return 'the email field is not below the landing'
  return document.activeElement === h ? true : 'the lead does not hold focus'
}, kind)
/* TEN / W6 · craft (round 2): at 375 × 667 the covenant's terms outran the
   sheet and its answers sat at their end — Join cut at the screen's edge,
   Not now out of sight. At rest both answers are inside the visible sheet. */
const covenantAnswersInView = async (page) => page.evaluate(() => {
  const p = document.querySelector('#sheet .panel'), acts = ['covJoin', 'covNo'].map((id) => document.getElementById(id))
  if (!p || acts.some((b) => !b)) return 'the covenant has no answers'
  const pr = p.getBoundingClientRect(), bottom = Math.min(pr.bottom, innerHeight)
  const out = acts.filter((b) => { const r = b.getBoundingClientRect(); return r.top < pr.top - 0.5 || r.bottom > bottom + 0.5 })
  return out.length ? `the covenant's answers are out of view at rest: ${out.map((b) => '#' + b.id).join(', ')}` : true
})
/* TEN / W6 · K077 [A2-post-10] · UI_SYSTEM §13.4: the toast is one shape, and
   not a pill. It is a 46pt block, rc 10, bg2, body 15 in ink, with a 3pt leading
   rail in `rule`: the neutral kind, and the web's toasts carry no other. */
const toastIsTheBlock = async (page) => page.evaluate(() => {
  const t = document.getElementById('toast'), cs = getComputedStyle(t), be = getComputedStyle(t, '::before')
  const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
  const want = { bg: probe('--bg2'), ink: probe('--ink'), rule: probe('--rule') }
  const got = { radius: cs.borderTopLeftRadius, bg: cs.backgroundColor, ink: cs.color, size: cs.fontSize, weight: cs.fontWeight, h: t.getBoundingClientRect().height, align: cs.textAlign, rail: [be.content, be.width, be.backgroundColor] }
  if (got.radius !== '10px') return 'the toast is not rc 10: ' + JSON.stringify(got)
  if (got.bg !== want.bg || got.ink !== want.ink) return 'the toast is not ink on bg2: ' + JSON.stringify(got)
  if (got.size !== '15px' || got.weight !== '400') return 'the toast is not body 15: ' + JSON.stringify(got)
  if (got.h < 45.5) return 'the toast is shorter than 46: ' + got.h
  if (be.content === 'none' || be.width !== '3px' || be.backgroundColor !== want.rule) return 'the toast has no 3pt rail in rule: ' + JSON.stringify(got)
  return got.align === 'left' ? true : 'the toast sentence is centred, not led by its rail'
})
/* TEN / W8 · W7-149 [A2-claim-invite-3, B2-claim-invite-4] · the invitation is answerable where Home shows it: one quiet 'Decline' on the item itself (D351: one tap,
   ungated; D389: until the first tee they see an invitation with its Decline), a 44px target in a group named for the answer, and never a second filled button (§16A.5) */
const inviteDeclineOnItem = async (page) => page.evaluate(() => {
  const b = document.querySelector('#homeLead [data-ivdec], #homeDeck [data-ivdec]')
  if (!b) return 'the invitation on Home has no Decline'
  if (b.textContent.trim() !== 'Decline') return `the invitation's answer reads ${JSON.stringify(b.textContent.trim())}, not 'Decline'`
  const r = b.getBoundingClientRect()
  if (r.height < 43.5) return `Decline is ${Math.round(r.height)}px tall, under the 44px target`
  const g = b.closest('[role="group"]')
  if (!g || g.getAttribute('aria-label') !== 'Answer this invitation') return 'Decline is not in a group named for the answer'
  if (b.classList.contains('btn')) return 'Decline is a filled button beside the one primary'
  return true
})
/* TEN / W8 · Q15 (3) (owner, 2026-09-29) [craft claim-invite D 7] · the covenant's terms sit under THREE HEADS in this order, "Who", "How it scores", "The money", each with terms under it and nothing
   between heads but its own paragraphs; a free season has no money head (L-10). `want` is the heads this season has */
const covenantHeads = (want) => async (page) => page.evaluate((want) => {
  const hs = [...document.querySelectorAll('#shBody [data-covhead]')]
  const got = hs.map((h) => h.textContent.trim())
  if (got.join('|') !== want.join('|')) return `the covenant's heads read ${JSON.stringify(got)}, expected ${JSON.stringify(want)}`
  for (const h of hs) { const n = h.nextElementSibling; if (!n || n.tagName !== 'P') return `the head '${h.textContent.trim()}' has no terms under it` }
  const body = document.getElementById('shBody').innerText
  if (want.includes('The money') && !/\$75 each\./.test(body)) return 'the stake is not in the covenant'
  const money = document.querySelector('#shBody [data-covhead="money"]')
  if (money && !/\$75 each\./.test(money.nextElementSibling.textContent)) return 'the money head does not open on the stake'
  return true
}, want)
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
    { '#obEmail': 'visible', '#obJoin': 'visible', '#emailbox': 'hidden', '#obLink[data-kind="claim-used"] h1': 'text:^That scorecard is already on a golfer’s record\\.$',
      '#obLink[data-kind="claim-used"] .sub': 'text:^If it’s yours, sign in with the same email and it’s in your rounds\\.$' },
    { check: outcomeLanding('claim-used') }),
  claimDoor('claim-unfinished', CLAIM.abandoned,
    () => /never finished/.test((document.querySelector('#obLink[data-kind="claim-unfinished"] h1') || {}).textContent || ''),
    { '#obEmail': 'visible', '#obLink[data-kind="claim-unfinished"] h1': 'text:^This round was never finished, so there’s no scorecard to keep\\.$',
      '#obLink[data-kind="claim-unfinished"] .sub': 'text:^Whoever ran it can tee off again and send your link from the new round\\.$' },
    { check: outcomeLanding('claim-unfinished') }),
  claimDoor('claim-not-started', CLAIM.setup,
    () => /hasn.t teed off yet/.test((document.querySelector('#obLink[data-kind="claim-not-started"] h1') || {}).textContent || ''),
    { '#obEmail': 'visible', '#obLink[data-kind="claim-not-started"] h1': 'text:^That round hasn.t teed off yet\\.$',
      '#obLink[data-kind="claim-not-started"] .sub': 'text:^Open this link again once it tees off to keep your own score, or once it finishes to keep your scorecard\\.$' },
    { check: async (page) => { const r = await outcomeLanding('claim-not-started')(page); if (r !== true) return r; return (await page.evaluate(() => localStorage.getItem('cs_claim') !== null)) ? true : 'the pencil was dropped: a round not yet started keeps its link' } }),
  claimDoor('claim-dead', CLAIM.dead,
    () => /expired or was already claimed/.test((document.querySelector('#obLink[data-kind="claim-dead"] h1') || {}).textContent || ''),
    { '#obEmail': 'visible', '#obLink[data-kind="claim-dead"] h1': 'text:^That scorecard link has expired or was already claimed\\.$',
      '#obLink[data-kind="claim-dead"] .sub': 'text:^Whoever sent it can share a fresh one from the round\\.$' },
    { world: { errors: { rpc: { guest_live_state: { __error: 'No such round', status: 400 }, scan_claim_info: { __error: 'Claim link not recognized', status: 400 } } } },
      expectConsole: [/status of 400/], check: outcomeLanding('claim-dead') }),
  /* signed in: the card asks before anything is claimed (R5) */
  { family: 'links', id: 'claim-signed-in-ask', variant: 'member', url: `/?claim=${CLAIM.valid}`,
    settle: async (page) => { await bootDone(page, 600); await until(page, () => document.getElementById('sheet').classList.contains('open') && /A scorecard link/.test(document.getElementById('shTitle').textContent), null, 12000); await page.waitForTimeout(500) },
    expect: { sheet: '^A scorecard link$', selectors: { '#lnkYes': 'text:^Add it to my record$', '#lnkNo': 'visible', '#lnkAsk .lead': 'text:Add this 91 at Mesquite Wash' } },
    /* TEN / W8 · W7-169 [A2-claim-invite-2] · the guest's name (Kit) and the golfer's (Avery Fixture) differ, so the ask says both, in INK, between the facts and the note;
       whose the scorecard is is said once (the facts line does not repeat 'Scored as') */
    check: async (page) => page.evaluate(() => {
      const fines = [...document.querySelectorAll('#lnkAsk p.fine')], mm = fines.find((p) => /you.re signed in as/.test(p.textContent))
      if (!mm) return 'the ask names no mismatch: ' + JSON.stringify(fines.map((p) => p.textContent))
      if (mm.textContent.trim() !== 'Scored as Kit — you’re signed in as Avery Fixture. Add it only if it’s yours.') return `the mismatch line reads ${JSON.stringify(mm.textContent.trim())}`
      const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
      if (getComputedStyle(mm).color !== probe('--ink')) return `the mismatch line is ${getComputedStyle(mm).color}, not ink`
      const note = fines.find((p) => /posts to your rounds/.test(p.textContent))
      if (!note || !(mm.compareDocumentPosition(note) & Node.DOCUMENT_POSITION_FOLLOWING)) return 'the mismatch line is not above the note'
      if (fines.some((p) => p !== mm && /Scored as/.test(p.textContent))) return 'whose the scorecard is is said twice (the facts line repeats Scored as)'
      return true
    }) },

  /* the league invite link, /?join=CODE (the format shareInvite writes, index.html:27224) */
  /* W4 · the invitation leads the door (#obLink) and the status keeps the next
     step; the invitation is to a season, never "the league" (T §2.3) */
  { family: 'links', id: 'join-valid', variant: 'signed_out', url: `/?join=${JOIN.season}`, short: true,
    settle: doorSettle(() => /invited to North Grove/.test((document.querySelector('#obLink h1') || {}).textContent || '')),
    expect: { door: true, selectors: { '#emailbox.open': 'visible', '#obLink h1': "text:^You’re invited to North Grove \\(fixture\\)\\.$", '#obLink .pitch': 'text:^Golf with your people, all season\\.$', '#obStatus': 'text:^Sign in to read the terms before you join\\.$' } } },
  /* a code that matches no league says so (owner panel P1: it said "You're
     invited" to a stranger) and is dropped, so signing in tries no join */
  { family: 'links', id: 'join-unavailable', variant: 'signed_out', url: `/?join=${JOIN.dead}`, short: true,
    /* ROUND 2 (G3): the dead link is the landing at the top, not a status line
       under an email box opened on the join premise (critique B's fix; at 375×380
       the status had fallen below the fold) */
    settle: doorSettle(() => /No league with that code/.test((document.querySelector('#obLink[data-kind="dead"]') || {}).textContent || '') && (window.__tenNet || []).some((e) => /rpc\/league_by_code/.test(e.url) && e.status === 200)),
    expect: { door: true, selectors: { '#emailbox.open': 'hidden', '#obLink[data-kind="dead"] h1': "text:^No league with that code\\.$", '#obLink[data-kind="dead"] .sub': "text:^Check with your Pro\\.$" } },
    check: async (page) => ((await page.evaluate(() => localStorage.getItem('cs_code') === null && localStorage.getItem('cs_code_name') === null)) ? true : 'the dead code was kept, or resolved to a name') },
  /* signed in with no league: the covenant gate, before join_league runs */
  { family: 'links', id: 'join-covenant', variant: 'brand_new', url: `/?join=${JOIN.season}`,
    settle: async (page) => { await until(page, () => document.getElementById('sheet').classList.contains('open') && /Before you join/.test(document.getElementById('shTitle').textContent), null, 15000); await page.waitForTimeout(600) },
    expect: { allowDoor: true, sheet: '^Before you join North Grove \\(fixture\\)$',
      selectors: { '#covJoin': 'text:^Join — I’m in for \\$75$', '#covNo': 'visible', '#shBody': 'text:Blake Sample runs the season \\(the Pro\\)' } },
    check: async (page) => { const r = await covenantAnswersInView(page); return r === true ? covenantHeads(['Who', 'How it scores', 'The money'])(page) : r } },
  { family: 'links', id: 'join-covenant-free', variant: 'brand_new', url: `/?join=${JOIN.free}`,
    settle: async (page) => { await until(page, () => document.getElementById('sheet').classList.contains('open') && /Before you join/.test(document.getElementById('shTitle').textContent), null, 15000); await page.waitForTimeout(600) },
    expect: { allowDoor: true, sheet: '^Before you join South Wash Weekday \\(fixture\\)$',
      selectors: { '#covJoin': 'text:^Join South Wash Weekday \\(fixture\\)$', '#shBody': 'text:every round counts' } },
    check: async (page) => { const r = await covenantAnswersInView(page); return r === true ? covenantHeads(['Who', 'How it scores'])(page) : r } },
  /* signed in and already in: the covenant is not shown again; the line says so */
  { family: 'links', id: 'join-already-in', variant: 'member', url: `/?join=${JOIN.season}`,
    settle: async (page) => { await bootDone(page, 300); await until(page, () => /already in for season 1/.test((document.getElementById('toast') || {}).textContent || ''), null, 8000) },
    expect: { view: 'view-home', selectors: { '#toast': 'text:^You’re already in for season 1\\.$' } }, pause: 50,
    check: toastIsTheBlock },
  /* in-app invitation (my_invites): drawn ONCE, then its terms. W4 · the banner
     row and Home's lead drew the same invitation twice with two "See the terms"
     (owner H, critique B P2). An invitation the served dispatch carries is the
     dispatch's item (lead or wire), and the banner keeps only the rest
     (renderNotifications' csDispatchCarries filter, lane W3's mechanism; the
     banner's look — a flat row, the stacked title, See the terms and a one-tap
     Decline — is W4's). So the invitation is the lead's, drawn once, and its
     door opens the terms. NOTE: on the W4 branch alone csDispatchCarries does
     not exist yet, so this state holds only once W3's half is merged. */
  { family: 'links', id: 'invite-banner', variant: 'brand_new', world: { flags: { invite: true } },
    settle: async (page) => { await until(page, () => !!document.querySelector('#homeLead [data-dkey^="invite:"]'), null, 15000); await page.waitForTimeout(500) },
    expect: { allowDoor: false, selectors: { '#homeLead': 'text:put you on North Grove \\(fixture\\)' } },
    check: async (page) => page.evaluate(() => {
      const key = (document.querySelector('#homeLead [data-dkey^="invite:"]') || {}).getAttribute?.('data-dkey') || ''
      const id = key.slice(7)
      const shown = (el) => !!el && el.offsetParent !== null
      const drawn = [...document.querySelectorAll('#homeLead [data-dkey], #homeDeck [data-dgo]')].filter((n) => (n.getAttribute('data-dkey') || n.getAttribute('data-dgo')) === key && shown(n)).length
        + [...document.querySelectorAll('#notifBanner [data-inv]')].filter((n) => n.getAttribute('data-inv') === id && shown(n)).length
      return drawn === 1 ? true : `the invitation is drawn ${drawn} times on Home`
    }).then((r) => r === true ? inviteDeclineOnItem(page) : r) },
  /* W7-149 · and the tap answers: one respond_invite with p_accept false, no confirm in between (D351) */
  { family: 'links', id: 'invite-decline', variant: 'brand_new', world: { flags: { invite: true } },
    settle: async (page) => { await until(page, () => !!document.querySelector('#homeLead [data-ivdec]'), null, 15000); await page.waitForTimeout(400) },
    drive: async (page) => {
      let asked = null
      const req = page.waitForRequest((r) => /rpc\/respond_invite/.test(r.url()), { timeout: 8000 }).then((r) => { asked = r.postData() || '' }).catch(() => {})
      await click(page, '#homeLead [data-ivdec]')
      await req
      await page.evaluate((b) => { window.__tenAsked = b }, asked)
      await page.waitForTimeout(600)
    },
    expect: { allowDoor: false },
    check: async (page) => page.evaluate(() => /"p_accept"\s*:\s*false/.test(window.__tenAsked || '') ? true : `Decline did not send respond_invite with p_accept false: ${JSON.stringify(window.__tenAsked)}`) },
  { family: 'links', id: 'invite-terms', variant: 'brand_new', world: { flags: { invite: true } },
    settle: async (page) => { await until(page, () => !!document.querySelector('#homeLead [data-dgo^="invite:"]'), null, 15000); await page.waitForTimeout(300) },
    drive: async (page) => { await click(page, '#homeLead [data-dgo^="invite:"]'); await until(page, () => /Before you join/.test(document.getElementById('shTitle').textContent) && document.getElementById('sheet').classList.contains('open')) },
    expect: { sheet: '^Before you join North Grove \\(fixture\\)$', selectors: { '#covJoin': 'visible' } },
    check: covenantAnswersInView },
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
