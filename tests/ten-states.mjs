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
import { notMono, noRetiredGlyph, noRetiredShape, tertiaryDoor, btnNameRole } from './ten-mono.mjs'
const all = (...fns) => async (page) => { for (const f of fns) { const r = await f(page); if (r !== true) return r } return true }
/* TEN / W6 · Q5 (owner, 2026-09-29 §R: B1) · the build stamp is off the Door's face but in its DOM (the diagnostic reads
   it), and a long-press on the pennant shows it; the check puts it back before the capture */
const stampOffTheDoor = async (page) => {
  const first = await page.evaluate(() => {
    const c = document.getElementById('obCaption')
    if (!c || !/v23 · /.test(c.textContent || '')) return 'the caption left the DOM'
    return c.getBoundingClientRect().height === 0 ? true : 'the build stamp is on the Door\u2019s face'
  })
  if (first !== true) return first
  const pen = await page.$('.ob-sig .cs-mark-door')
  if (!pen) return 'no pennant'
  const b = await pen.boundingBox()
  await page.mouse.move(b.x + b.width / 2, b.y + b.height / 2); await page.mouse.down(); await page.waitForTimeout(750); await page.mouse.up()
  const shown = await page.evaluate(() => document.getElementById('obCaption').getBoundingClientRect().height > 0)
  await page.evaluate(() => document.getElementById('obCaption').classList.remove('is-shown'))
  return shown ? true : 'a long-press on the pennant does not show the stamp'
}
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
const CORE = [
  /* ------------------------------------------------------------ door */
  { family: 'door', id: 'initial', variant: 'signed_out', url: '/', expect: { door: true, selectors: { '#obEmail': 'visible', '#obJoin': 'visible' } },
    check: all(btnNameRole(['#obEmail', '#obJoin']), stampOffTheDoor) },   /* TEN / W6 · Q25, Q5 */
  { family: 'door', id: 'email', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => { await click(page, '#obEmail'); await until(page, () => document.querySelector('#emailbox').classList.contains('open')) },
    expect: { door: true, selectors: { '#obEmailIn': 'visible', '#obEmailGo': 'visible' } } },
  { family: 'door', id: 'sending', variant: 'signed_out', url: '/', short: true,
    hold: (e) => e.method === 'POST' && /\/auth\/v1\/otp/.test(e.path),
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => /Sending/.test(document.getElementById('obStatus').textContent))
    },
    expect: { door: true, selectors: { '#obStatus': 'text:Sending', '#obEmailGo': 'visible' } } },
  { family: 'door', id: 'code-entry', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => document.querySelector('#codebox').classList.contains('open'))
    },
    expect: { door: true, selectors: { '#obCodeIn': 'visible', '#obStatus': 'text:Sent to' } } },
  { family: 'door', id: 'code-error', variant: 'signed_out', url: '/', short: true,
    expectConsole: [/^\[cs\] (That code|Code didn|The code|That sign-in|Something went wrong)/, /^\[cs\] error: Code didn/, /status of 403/],
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => document.querySelector('#codebox').classList.contains('open'))
      await page.fill('#obCodeIn', '12345678')
      await until(page, () => /err/.test(document.getElementById('obStatus').className))
    },
    expect: { door: true, selectors: { '#obStatus.err': 'visible' } } },
  { family: 'door', id: 'send-failed', variant: 'signed_out', url: '/', short: true,
    world: { errors: { auth: { otp: { status: 429, body: { code: 429, error_code: 'over_email_send_rate_limit', msg: 'email rate limit exceeded' } } } } },
    expectConsole: [/^\[cs\] Too many sign-in emails/, /status of 429/],
    drive: async (page) => {
      await click(page, '#obEmail'); await page.fill('#obEmailIn', 'avery.fixture@example.invalid')
      await click(page, '#obEmailGo')
      await until(page, () => /err/.test(document.getElementById('obStatus').className))
    },
    expect: { door: true, selectors: { '#obStatus.err': 'visible' } } },
  { family: 'door', id: 'league-code', variant: 'signed_out', url: '/', short: true,
    drive: async (page) => { await click(page, '#obJoin'); await until(page, () => document.querySelector('#joinbox').classList.contains('open')) },
    expect: { door: true, selectors: { '#joinCode': 'visible' } } },

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
