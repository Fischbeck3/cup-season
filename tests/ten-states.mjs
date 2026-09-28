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

const CORE = [
  /* ------------------------------------------------------------ door */
  { family: 'door', id: 'initial', variant: 'signed_out', url: '/', expect: { door: true, selectors: { '#obEmail': 'visible', '#obJoin': 'visible' } } },
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
    expect: { door: true, selectors: { '#obProfile': 'visible', '#pfSave': 'visible', '#obDoor': 'hidden' } } },

  /* ------------------------------------------------------------ home */
  { family: 'home', id: 'member', variant: 'member', expect: { view: 'view-home' } },
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
