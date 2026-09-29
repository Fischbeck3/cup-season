#!/usr/bin/env node
/* Chosen states are shapes, not colours; rows and grids hold their measure.
   · Card & settings: the chosen ball marker and the chosen appearance are the
     chosen pill (.mini.sel), each says aria-pressed, and exactly one is chosen;
   · the wizard's step rail is ink (the phone's WizardDots), not ember;
   · a bylaw row's label keeps its measure beside a long value;
   · the desk's calendar is short rows, not ~170px squares;
   · a rivalry record and a tee time are ink, never gold.
   Synthetic and in-page; every supabase.co request is aborted.

     node tests/selection-rows-browser.mjs [--base http://127.0.0.1:8801]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 600))) }

const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [320, 375, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t); localStorage.setItem('cs_nudge_done', '1') } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof window.openProfileHub === 'function' && typeof renderCalendar === 'function', null, { timeout: 20000 })
  await page.evaluate(() => document.fonts.ready)
  const label = `${width} ${theme}`
  await page.evaluate(() => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false; CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
    CS.profile = { id: CS.user.id, display_name: 'Avery Fixture', handle: 'avery', marker: 'island', city: 'Mesa, AZ' }
    CS.memberships = []
  })

  /* ---- Card & settings: chosen pills */
  const pick = await page.evaluate(async () => {
    switchView('stats'); window.openProfileHub()
    await new Promise(r => setTimeout(r, 150))
    const mk = [...document.querySelectorAll('#phMarkers [data-phmk]')]
    const chosen = mk.filter(b => b.getAttribute('aria-pressed') === 'true')
    const bg = b => getComputedStyle(b).backgroundColor
    const out = { n: mk.length, chosen: chosen.map(b => b.dataset.phmk), chosenSel: chosen.every(b => b.classList.contains('sel')),
      shapeDiffers: chosen.length === 1 && mk.filter(b => b !== chosen[0]).every(b => bg(b) !== bg(chosen[0])) }
    document.querySelector('#phSeg [data-ph="settings"]')?.click()
    await new Promise(r => setTimeout(r, 100))
    const th = [...document.querySelectorAll('#phTheme [data-th]')]
    out.theme = th.map(b => ({ th: b.dataset.th, pressed: b.getAttribute('aria-pressed'), sel: b.classList.contains('sel'), bg: bg(b) }))
    closeSheet()
    return out
  })
  check(`${label}: exactly one marker is chosen (${pick.chosen}), as the chosen pill, not a colour`, pick.n > 4 && pick.chosen.length === 1 && pick.chosen[0] === 'island' && pick.chosenSel && pick.shapeDiffers, pick)
  const want = theme
  const onTh = (pick.theme || []).filter(t => t.pressed === 'true')
  check(`${label}: the chosen appearance (${onTh.map(t => t.th)}) says aria-pressed and is the chosen pill`, onTh.length === 1 && onTh[0].th === want && onTh[0].sel && pick.theme.filter(t => t.pressed === 'false').length === 2 && pick.theme.every(t => t.th === want || t.bg !== onTh[0].bg), pick.theme)

  /* ---- the wizard rail is ink */
  const rail = await page.evaluate(() => {
    const d = document.createElement('div'); d.className = 'wizdots'; d.innerHTML = '<i class="on"></i><i></i><i></i>'; document.body.appendChild(d)
    const on = getComputedStyle(d.querySelector('i.on')).backgroundColor
    const probe = document.createElement('span'); probe.style.color = 'var(--ink)'; document.body.appendChild(probe); const ink = getComputedStyle(probe).color
    const probe2 = document.createElement('span'); probe2.style.color = 'var(--brand)'; document.body.appendChild(probe2); const brand = getComputedStyle(probe2).color
    d.remove(); probe.remove(); probe2.remove(); return { on, ink, brand }
  })
  check(`${label}: the wizard's step rail is ink, never ember`, rail.on === rail.ink && rail.on !== rail.brand, rail)

  /* ---- a bylaw row keeps its label's measure */
  const row = await page.evaluate(() => {
    const host = document.createElement('div'); host.style.cssText = 'width:' + Math.min(311, innerWidth - 64) + 'px'
    host.innerHTML = '<div class="byrow"><span>How scores count</span><b>Scored against your playing HCP — your index at 95 percent</b></div>'
    document.body.appendChild(host)
    /* count the TEXT's line boxes (a flex item stretches to the row, so its box height is the value's) */
    const sp = host.querySelector('span'), r = document.createRange(); r.selectNodeContents(sp)
    const tops = new Set([...r.getClientRects()].map(x => Math.round(x.top)))
    const out = { lines: tops.size, w: Math.round(host.getBoundingClientRect().width) }
    host.remove(); return out
  })
  check(`${label}: a bylaw label beside a long value stays whole (${row.lines} line${row.lines === 1 ? '' : 's'} in ${row.w}px)`, row.lines <= (row.w < 280 ? 2 : 1), row)

  /* ---- the desk calendar, and ink facts */
  const cal = await page.evaluate(() => {
    window.mySchedule = []; window.watchAll = []
    switchView('schedule'); renderCalendar()
    const cells = [...document.querySelectorAll('#calGrid .calcell:not(.blank)')].map(c => c.getBoundingClientRect())
    /* the rivalry tag rides the crew's plans (module-side: reached through its bridge) */
    window.RIVALS = [{ opponent: 'pf2', display_name: 'Devon Example', meetings: 7, wins: 3, losses: 4, rivalry_name: 'The Fixture Derby' }]
    /* 2026-09-28 · critique-B P0: "in" means an explicit yes. A tagged plan
       with `my_rsvp:'in'` says YOU'RE IN in the row's fixed state slot (it was
       "ON THE SCHEDULE", printed on the TAG alone, which told a golfer who had
       never answered that they had said yes); a tagged plan with no answer
       says ASKED and offers I'm in. The soonest plan of yours leads the page
       (#schNext), so a plan of the viewer's own comes first and the two tagged
       rows fall to the list this suite reads. */
    const soon = n => isoOf(new Date(Date.now() + n * 864e5))
    window.watchAll = [
      { id: 'm1', profile_id: 'me', display_name: 'Me', mine: true, shared_league: false, tagged_me: false, play_on: soon(1), course_label: 'Papago', marker: 'saguaro' },
      { id: 'w1', profile_id: 'pf2', display_name: 'Devon Example', mine: false, shared_league: true, tagged_me: true, my_rsvp: 'in', play_on: soon(5), course_label: 'Mesquite Wash', marker: 'saguaro' },
      { id: 'w2', profile_id: 'pf2', display_name: 'Devon Example', mine: false, shared_league: true, tagged_me: true, my_rsvp: null, play_on: soon(6), course_label: 'Mesquite Wash', marker: 'saguaro' }]
    window.renderWatchList()
    const tagEl = [...document.querySelectorAll('#calWatch small span')].find(e => /leads|even/.test(e.textContent))
    const c = tagEl ? getComputedStyle(tagEl).color : null
    const status = [...document.querySelectorAll('#calWatch .schrow-chip')].find(e => /You’re in/i.test(e.textContent))
    const sc = status ? getComputedStyle(status).color : null
    const asked = document.querySelector('#calWatch [data-wopen="w2"]')
    const askedOk = !!asked && /Asked/.test(asked.textContent) && !/You’re in/i.test(asked.textContent) && !!asked.querySelector('[data-imin]')
    const probe = document.createElement('span'); probe.style.color = 'var(--ink)'; document.body.appendChild(probe); const ink = getComputedStyle(probe).color; probe.remove()
    const card = homeRoundCard({ id: 'x', mine: false, display_name: 'Devon Example', play_on: '2026-10-03', tee_time: '08:10', course_label: 'Mesquite Wash', marker: 'saguaro' }, false)
    return { maxH: Math.max(...cells.map(r => r.height)), minW: Math.min(...cells.map(r => r.width)), rivalry: c, status: sc, askedOk, ink, teeGold: /color:var\(--gold\)/.test(card) }
  })
  if (width >= 960) check(`${label}: the desk calendar is short rows (${Math.round(cal.maxH)}px tall days), not squares`, cal.maxH <= 100 && cal.minW > cal.maxH, cal)
  /* 44 from 375 (the smallest supported iPhone) is calendar-album's; at 320 CSS
     (Display Zoom, narrow windows) seven days cannot all be 44 inside a card —
     a named exception: WCAG 2.5.8's 24px holds, and the days stay square */
  else if (width >= 375) check(`${label}: a phone's calendar days stay square 44px targets`, cal.maxH >= 44 && cal.minW >= 44 && Math.abs(cal.maxH - cal.minW) < 1, cal)
  else check(`${label}: at 320 the days stay square and above WCAG's 24px (${Math.round(cal.minW)}px, named exception)`, cal.minW >= 24 && Math.abs(cal.maxH - cal.minW) < 1, cal)
  check(`${label}: a rivalry record, "you're in" and a tee time are ink, never gold`, cal.rivalry === cal.ink && cal.status === cal.ink && !cal.teeGold, cal)
  check(`${label}: a tag nobody answered says ASKED and offers I'm in — never "you're in"`, cal.askedOk, cal)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
