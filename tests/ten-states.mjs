/* Cup Season · the ten-capture STATE CATALOGUE (WX lane, 2026-09-28).
 *
 * One entry per family/state. Each names the synthetic account (`variant`,
 * see tests/fixtures/ten/world.mjs), how to reach the state through the
 * page's OWN controls or its own router (`drive`), and what must be true for
 * the capture to count (`expect` / `check`). A state that lands anywhere else
 * -- the Door, Home, a blank pane -- is recorded as FAILED, never re-labelled.
 * `expectConsole` lists the console lines a state provokes on purpose (an
 * injected failure); every other line is normal operation and is reported. */

const until = async (page, fn, arg, ms = 8000) => page.waitForFunction(fn, arg, { timeout: ms })
const click = async (page, sel) => { await page.locator(sel).first().click({ timeout: 8000 }) }
const go = (v) => async (page) => { await page.evaluate((v) => window.switchView(v), v); await page.waitForTimeout(900) }

import { readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import { notMono, noRetiredGlyph, noRetiredShape, tertiaryDoor } from './ten-mono.mjs'
const HERE = dirname(fileURLToPath(import.meta.url))

/* Family modules: tests/ten-states.d/<family>.mjs, each `export default [ ...states ]`.
   Loaded in filename order after the core list below. */
async function familyModules() {
  const dir = join(HERE, 'ten-states.d')
  let files = []
  try { files = readdirSync(dir).filter((f) => f.endsWith('.mjs')).sort() } catch { return [] }
  const out = []
  for (const f of files) { const m = await import(pathToFileURL(join(dir, f)).href); out.push(...(m.default || [])) }
  return out
}

/* TEN / W6 · W7-114 [A2-identity-13] · root's ruling: the card gate names the
   account it is for and offers the way out of the wrong one. The line sits at
   the gate's foot, "Signed in as <email> · Not you? Sign out": the sentence in
   body-s, mut, the email wrapping whole, and Sign out the in-content tertiary
   link, which signs out of THIS device only (scope local). The harness seeds
   the session on every load, so the reload lands on the gate again, and the
   check waits for it so the capture is the gate as before. */
const gateWho = async (page) => {
  const r = await page.evaluate(() => {
    const w = document.getElementById('pfWho'), a = document.getElementById('pfWhoOut')
    if (!w || w.hidden || !a) return 'the card gate does not say whose account it is'
    const t = w.textContent.replace(/\s+/g, ' ').trim()
    if (!/^Signed in as \S+@\S+ · Not you\? Sign out$/.test(t)) return 'the line reads ' + JSON.stringify(t)
    const probe = document.createElement('i'); probe.style.color = 'var(--mut)'; document.body.appendChild(probe)
    const mut = getComputedStyle(probe).color; probe.remove()
    const cs = getComputedStyle(w)
    if (cs.color !== mut || cs.fontSize !== '15px') return 'the line is not body-s in mut: ' + cs.color + ' ' + cs.fontSize
    if (getComputedStyle(w.querySelector('.pfwho-em')).overflowWrap !== 'anywhere') return 'the email does not wrap whole'
    return document.getElementById('pfSave').compareDocumentPosition(w) & Node.DOCUMENT_POSITION_FOLLOWING ? true : 'the line is not at the gate’s foot'
  })
  if (r !== true) return r
  const door = await tertiaryDoor('#pfWhoOut')(page)
  if (door !== true) return door
  const req = page.waitForRequest((q) => /\/auth\/v1\/logout/.test(q.url()), { timeout: 8000 }).catch(() => null)
  await page.locator('#pfWhoOut').click()
  const q = await req
  if (!q) return 'Sign out sent no sign-out'
  if (!/scope=local/.test(q.url())) return 'Sign out is not this device only: ' + q.url()
  await page.waitForFunction(() => { const g = document.getElementById('obProfile'); return !!g && g.style.display === 'block' && !document.getElementById('pfWho').hidden }, null, { timeout: 15000 }).catch(() => {})
  await page.waitForTimeout(600)
  return true
}
/* TEN / W8 · W7-109 [A2-door-5, B2-door-3, A2-desk-23] · the Door's field rows stack: each open row's field takes the whole row, its action sits beneath it at the same
   width, and the address being sent to (`whole`, the email field's id) is WHOLE in its field, with nothing to scroll: the two moments a golfer checks it for a typo */
const doorStacked = (whole) => async (page) => page.evaluate((whole) => {
  const rows = [...document.querySelectorAll('#emailbox.open, #codebox.open, #joinbox.open')]
  if (!rows.length) return 'no Door field row is open'
  for (const row of rows) {
    const inp = row.querySelector('input'), btn = row.querySelector('.btn')
    const ri = inp.getBoundingClientRect(), rb = btn.getBoundingClientRect(), rr = row.getBoundingClientRect()
    if (!ri.width || !rb.width) continue   /* a field or action the state has put away (the email row's Send code once the code step is open) */
    if (ri.width < rr.width - 1) return `#${inp.id} is ${Math.round(ri.width)}px in a ${Math.round(rr.width)}px row: it shares the row with its action`
    if (rb.top < ri.bottom - 0.5) return `#${btn.id} is beside #${inp.id}, not beneath it`
    if (Math.abs(rb.width - rr.width) > 1) return `#${btn.id} is ${Math.round(rb.width)}px, not the row's ${Math.round(rr.width)}px`
  }
  if (whole) { const i = document.getElementById(whole); if (i.scrollWidth > i.clientWidth + 1) return `the address in #${whole} is cut: ${i.scrollWidth}px of text in ${i.clientWidth}px` }
  return true
}, whole)
/* TEN / W8 · Q46 (owner, 2026-09-29) [B2-door-8] · the Door's field edges and its quiet button's outline are OPAQUE mut, at 3:1 or better against the ground they sit on
   and against a field's own fill (WCAG 1.4.11): 7.07:1 dark and 5.85:1 light. `sels` are the Door's own fields and its quiet button; each must be drawn and carry a 1px edge */
const doorEdgesMut = (sels) => async (page) => page.evaluate((sels) => {
  const rgb = (c) => (c.match(/[\d.]+/g) || []).slice(0, 3).map(Number)
  const lin = (v) => { v /= 255; return v <= 0.03928 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4 }
  const lum = (c) => { const [r, g, b] = rgb(c); return 0.2126 * lin(r) + 0.7152 * lin(g) + 0.0722 * lin(b) }
  const ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + 0.05) / (Math.min(x, y) + 0.05) }
  const probe = (v) => { const d = document.createElement('i'); d.style.color = `var(${v})`; document.body.appendChild(d); const c = getComputedStyle(d).color; d.remove(); return c }
  const mut = probe('--mut'), ground = probe('--bg0')
  for (const sel of sels) {
    const el = document.querySelector(sel)
    if (!el || !el.getBoundingClientRect().width) return `${sel} is not drawn`
    const cs = getComputedStyle(el)
    if (cs.borderTopWidth !== '1px') return `${sel} has a ${cs.borderTopWidth} edge, not 1px`
    if (cs.borderTopColor !== mut) return `${sel}'s edge is ${cs.borderTopColor}, not opaque mut (${mut})`
    if (ratio(cs.borderTopColor, ground) < 3) return `${sel}'s edge is ${ratio(cs.borderTopColor, ground).toFixed(2)}:1 against the ground`
    const fill = cs.backgroundColor
    if (rgb(fill).length && !/rgba\(.*, 0\)$/.test(fill) && ratio(cs.borderTopColor, fill) < 3) return `${sel}'s edge is ${ratio(cs.borderTopColor, fill).toFixed(2)}:1 against its own fill`
  }
  return true
}, sels)
/* TEN / W8 · W7-163 [A2-door-2, B2-door-9] · a route to help from the Door, at the moment of need: once the code step is open or a sign-in error is on screen, 'Trouble signing in?'
   is a quiet in-content link (2px mut underline, 44px) to support's own answer, in a NEW tab so the Door keeps what was typed; before that (`shown` false) it is not drawn */
const doorHelp = (shown) => async (page) => {
  const r = await page.evaluate((shown) => {
    const a = document.getElementById('obHelp')
    if (!a) return 'the Door has no help link'
    const drawn = a.getBoundingClientRect().width > 0 && getComputedStyle(a).display !== 'none'
    if (!shown) return drawn ? 'the help link is drawn before anything went wrong' : true
    if (!drawn) return 'no help link on the Door after the code step opened or an error'
    if (a.textContent.trim() !== 'Trouble signing in?') return `the help link reads ${JSON.stringify(a.textContent.trim())}`
    if (a.getAttribute('href') !== '/support#code' || a.getAttribute('target') !== '_blank' || !/noopener/.test(a.getAttribute('rel') || '')) return `the help link is ${a.getAttribute('href')} target=${a.getAttribute('target')} rel=${a.getAttribute('rel')}, not /support#code in a new tab`
    const rs = document.getElementById('obResend')
    if (rs && rs.getBoundingClientRect().width > 0 && !(rs.compareDocumentPosition(a) & Node.DOCUMENT_POSITION_FOLLOWING)) return 'the help link is not after Resend code'
    return true
  }, shown)
  if (r !== true || !shown) return r
  /* the Door's own quiet link (.cs-tskip, as Back and Resend code are): a word in opaque mut under an underline, in a 44px box (§7.1, §16.2) */
  return page.evaluate(() => {
    const a = document.getElementById('obHelp'), cs = getComputedStyle(a), r = a.getBoundingClientRect()
    const probe = document.createElement('i'); probe.style.color = 'var(--mut)'; document.body.appendChild(probe); const mut = getComputedStyle(probe).color; probe.remove()
    if (!a.classList.contains('cs-tskip')) return 'the help link is not the Door\'s quiet link (.cs-tskip)'
    if (!/underline/.test(cs.textDecorationLine)) return 'the help link has no underline'
    if (cs.color !== mut) return `the help link is ${cs.color}, not opaque mut`
    return r.height >= 43.5 ? true : `the help link is ${Math.round(r.height)}px tall, under the 44px target`
  })
}
const CORE = [
  /* ------------------------------------------------------------ door */
  { family: 'door', id: 'initial', variant: 'signed_out', url: '/', expect: { door: true, selectors: { '#obEmail': 'visible', '#obJoin': 'visible' } }, check: async (page) => { const r = await doorEdgesMut(['#obJoin'])(page); return r === true ? doorHelp(false)(page) : r } },
  { family: 'door', id: 'email', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => { await click(page, '#obEmail'); await until(page, () => document.querySelector('#emailbox').classList.contains('open')) },
    expect: { door: true, selectors: { '#obEmailIn': 'visible', '#obEmailGo': 'visible' } }, check: async (page) => { const r = await doorStacked()(page); if (r !== true) return r; const e = await doorEdgesMut(['#obEmailIn'])(page); return e === true ? doorHelp(false)(page) : e } },
  { family: 'door', id: 'sending', variant: 'signed_out', url: '/', short: true,
    hold: (e) => e.method === 'POST' && /\/auth\/v1\/otp/.test(e.path),
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => /Sending/.test(document.getElementById('obStatus').textContent))
    },
    expect: { door: true, selectors: { '#obStatus': 'text:Sending', '#obEmailGo': 'visible' } }, check: doorStacked('obEmailIn') },
  { family: 'door', id: 'code-entry', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => document.querySelector('#codebox').classList.contains('open'))
    },
    expect: { door: true, selectors: { '#obCodeIn': 'visible', '#obStatus': 'text:Sent to' } }, check: async (page) => { const r = await doorStacked()(page); if (r !== true) return r; const e = await doorEdgesMut(['#obCodeIn'])(page); return e === true ? doorHelp(true)(page) : e } },
  { family: 'door', id: 'code-error', variant: 'signed_out', url: '/', short: true,
    expectConsole: [/^\[cs\] (That code|Code didn|The code|That sign-in|Something went wrong)/, /^\[cs\] error: Code didn/, /status of 403/],
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => document.querySelector('#codebox').classList.contains('open'))
      await page.fill('#obCodeIn', '12345678')
      await until(page, () => /err/.test(document.getElementById('obStatus').className))
    },
    expect: { door: true, selectors: { '#obStatus.err': 'visible' } }, check: async (page) => { const r = await doorStacked()(page); return r === true ? doorHelp(true)(page) : r } },
  { family: 'door', id: 'send-failed', variant: 'signed_out', url: '/', short: true,
    world: { errors: { auth: { otp: { status: 429, body: { code: 429, error_code: 'over_email_send_rate_limit', msg: 'email rate limit exceeded' } } } } },
    expectConsole: [/^\[cs\] Too many sign-in emails/, /status of 429/],
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => /err/.test(document.getElementById('obStatus').className))
    },
    expect: { door: true, selectors: { '#obStatus.err': 'visible' } }, check: async (page) => { const r = await doorStacked('obEmailIn')(page); return r === true ? doorHelp(true)(page) : r } },
  { family: 'door', id: 'league-code', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => { await click(page, '#obJoin'); await until(page, () => document.querySelector('#joinbox').classList.contains('open')); await page.waitForTimeout(900) },
    expect: { door: true, selectors: { '#joinCode': 'visible' } },
    check: async (page) => {
      const r = await doorStacked()(page); if (r !== true) return r
      const e = await doorEdgesMut(['#joinCode'])(page); if (e !== true) return e
      /* TEN / W8 · W7-161 [B2-door-2] · with the keyboard up (the 375x380 proxy) the league-code field and Join land WHOLE, mid-view, as the email branch's sentence does: the
         box's bottom edge clears the view by a 44px target (§13.2a: whole or clearly half-scrolled, never sheared) */
      return page.evaluate(() => {
        if (innerHeight > 400) return true
        const b = document.getElementById('joinbox').getBoundingClientRect()
        return b.bottom + 44 <= innerHeight + 0.5 && b.top >= 0 ? true : `the league-code box is cut by the ${innerHeight}px view: top ${Math.round(b.top)}, bottom ${Math.round(b.bottom)}`
      })
    } },

  /* ---------------------------------------------------- onboarding gate */
  { family: 'onboarding', id: 'card-gate', variant: 'no_card', short: true,
    /* the gate lives on the door overlay (#obProfile inside #onboard) */
    expect: { door: true, selectors: { '#obProfile': 'visible', '#pfSave': 'visible', '#obDoor': 'hidden' } },
    /* TEN / W6 · delta G4 (round 2): stuck, the Save meets the window's edge —
       no strip beneath it where the form shows through, sliced */
    check: async (page) => {
      const save = await page.evaluate(() => {
        const bar = document.querySelector('#obProfile .pfsave'), sc = document.getElementById('onboard')
        if (!bar || !sc || getComputedStyle(bar).position !== 'sticky') return true
        if (sc.scrollHeight <= sc.clientHeight + 1) return true   /* the whole card fits: the bar is in its place */
        /* W7-114 · a bar whose own place is already on screen is not stuck: what
           is under it is the gate's foot (the GHIN note, the account line), not
           the form showing through */
        const was = bar.style.position; bar.style.position = 'static'
        const own = bar.getBoundingClientRect().bottom; bar.style.position = was
        if (own <= sc.getBoundingClientRect().bottom + 1) return true
        const gap = Math.round(sc.getBoundingClientRect().bottom - bar.getBoundingClientRect().bottom)
        return gap <= 1 ? true : `the Save bar floats ${gap}px above the window's edge, and the form shows beneath it`
      })
      if (save !== true) return save
      /* W7-114 · one version of the item: B's #pfWho (a4fb9be1, the ruled words); C's duplicate line was
         reverted on its branch (369202e6). From C it keeps the SIGNED IN stamp's removal: whose account
         this is is said once, at the gate's foot */
      if (await page.evaluate(() => !!document.querySelector('#obProfile .lockbadge'))) return 'the gate still draws the SIGNED IN chip'
      const g = await noRetiredGlyph()(page)
      return g !== true ? g : gateWho(page)
    } },

  /* ------------------------------------------------------------ home */
  /* TEN / W6 · AW2-13: the header and the tab bar sit on the page's own ground — no glass */
  { family: 'home', id: 'member', variant: 'member', expect: { view: 'view-home' }, check: noRetiredShape() },
  { probe: true, family: 'explore', id: 'stats', variant: 'member', drive: go('stats'), expect: { view: 'view-stats' } },
  { probe: true, family: 'explore', id: 'record', variant: 'member', drive: go('record'), expect: { view: 'view-record' } },
  { probe: true, family: 'explore', id: 'hub', variant: 'member', drive: go('hub'), expect: { view: 'view-hub' } },
  { probe: true, family: 'explore', id: 'compete', variant: 'member', drive: go('compete'), expect: { view: 'view-compete' } },
  { probe: true, family: 'explore', id: 'golfers', variant: 'member', drive: go('golfers'), expect: { view: 'view-golfers' } },
  { probe: true, family: 'explore', id: 'schedule', variant: 'member', drive: go('schedule'), expect: { view: 'view-schedule' } },
  { probe: true, family: 'explore', id: 'play', variant: 'member', drive: go('play'), expect: { view: 'view-play' } },
  { probe: true, family: 'explore', id: 'post', variant: 'member', drive: go('post'), expect: { view: 'view-post' } },
  { probe: true, family: 'explore', id: 'wizard', variant: 'pro_setup', expect: { view: 'view-wizard' } },
  { probe: true, family: 'explore', id: 'event', variant: 'member', drive: go('event'), expect: { view: 'view-event' } },
]

export const STATES = [...CORE, ...(await familyModules())]
export const helpers = { until, click, go }
