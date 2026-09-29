#!/usr/bin/env node
/* The competition surfaces say what is true (WX-C2's defects, 2026-09-28), and
   the Home / season furniture around them holds its measure.
   · a Ryder duel reads "A lost to B" when B won — never "A def. B";
   · a finished edition's series line counts its own result;
   · two four-golfer sides never overlap at phone widths;
   · a season before its first tee is Upcoming ("Before first tee"), by the
     LOCAL date, even on a Phoenix evening when UTC is already tomorrow;
   · a live Ryder's row never says "Forming";
   · the Cup Final race never prints a per-golfer cap beside a squad's rounds;
   · the Book's dialog is centred on the desk; the pot in the desk aside prints
     whole money; a season section lands below the sticky bar;
   · the Home hero is readable (a surface, not the figure tile) and its one
     move is the action green; Up Next never pushes the page sideways;
   · the RSVP buttons read on the sheet and reach 44.
   Everything is synthetic and in-page; every supabase.co request is aborted.

     node tests/competition-truth-browser.mjs [--base http://127.0.0.1:8801] [--shots <dir>]
*/
import { createRequire } from 'node:module'
import { existsSync, readdirSync, mkdirSync } from 'node:fs'
import { join } from 'node:path'
import { homedir } from 'node:os'
const require = createRequire(import.meta.url)
const arg = (k, d) => { const i = process.argv.indexOf('--' + k); return i > 0 ? process.argv[i + 1] : d }
const BASE = arg('base', 'http://127.0.0.1:8801')
const SHOTS = arg('shots', null); if (SHOTS) mkdirSync(SHOTS, { recursive: true })
const { chromium } = require(process.env.CS_PLAYWRIGHT || '/Users/fischbeck3/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/playwright')
const shell = () => { const r = join(homedir(), 'Library', 'Caches', 'ms-playwright'); for (const d of readdirSync(r).filter(d => d.startsWith('chromium_headless_shell')).sort().reverse()) { const p = join(r, d, 'chrome-headless-shell-mac-arm64', 'chrome-headless-shell'); if (existsSync(p)) return p } }
const results = []
const check = (name, ok, got) => { results.push({ ok: !!ok }); console.log((ok ? '  PASS  ' : 'X FAIL  ') + name + (ok ? '' : '  got: ' + JSON.stringify(got).slice(0, 600))) }

/* contrast, WCAG relative luminance, from computed rgb() strings */
const CONTRAST = `(() => {
  const lum = s => { const a = s.match(/[\\d.]+/g).slice(0, 3).map(Number).map(c => { c /= 255; return c <= .04045 ? c / 12.92 : ((c + .055) / 1.055) ** 2.4 }); return .2126 * a[0] + .7152 * a[1] + .0722 * a[2] }
  window.__ratio = (a, b) => { const x = lum(a), y = lum(b); return (Math.max(x, y) + .05) / (Math.min(x, y) + .05) }
  window.__bgOf = el => { for (let n = el; n; n = n.parentElement) { const c = getComputedStyle(n).backgroundColor; if (c && !/rgba\\(0, 0, 0, 0\\)|transparent/.test(c)) return c } return getComputedStyle(document.body).backgroundColor }
})()`

const browser = await chromium.launch({ headless: true, executablePath: shell() })
for (const width of [375, 402, 1280]) for (const theme of ['dark', 'light']) {
  const ctx = await browser.newContext({ viewport: { width, height: width < 500 ? 740 : 900 }, serviceWorkers: 'block', reducedMotion: 'reduce', timezoneId: 'America/Phoenix' })
  await ctx.addInitScript(t => { try { localStorage.setItem('cs_theme', t); localStorage.setItem('cs_nudge_done', '1') } catch (e) {} }, theme)
  const page = await ctx.newPage()
  const errs = []; page.on('pageerror', e => errs.push(e.message))
  await page.route('**/*', r => /supabase\.co/.test(r.request().url()) ? r.abort() : r.continue())
  /* a Phoenix EVENING: 19:30 on Sep 28 is already Sep 29 in UTC */
  await page.clock.setFixedTime(new Date('2026-09-28T19:30:00-07:00'))
  await page.goto(BASE + '/?exit', { waitUntil: 'load' })
  await page.waitForFunction(() => window.sb && typeof window.renderEvent === 'function' && typeof csCompeteList === 'function', null, { timeout: 20000 })
  await page.evaluate(CONTRAST)
  await page.evaluate(() => document.fonts.ready)
  const label = `${width} ${theme}`
  const shot = async n => { if (SHOTS) await page.screenshot({ path: join(SHOTS, `${n}--${width}--${theme}.png`) }) }
  await page.evaluate(() => {
    const ob = document.getElementById('onboard'); ob.classList.add('hide'); ob.style.display = 'none'
    state.demo = false; CS.user = { id: '00000000-0000-4000-8000-00000000f1f1' }
  })

  /* ---- the Ryder room */
  const room = await page.evaluate(() => {
    const T1 = 't1', T2 = 't2', EV = 'e0000000-0000-4000-8000-0000000000e1'
    const names = ['Avery Fixture', 'Blake Sample', 'Casey Testwell', 'Devon Example', 'Emery Fixture', 'Finley Sample', 'Gray Testwell', 'Harper Example']
    const players = names.map((n, i) => ({ id: 'p' + i, profile_id: 'pf' + i, name: n, marker: 'saguaro', team_id: i < 4 ? T1 : T2 }))
    window.CS_EVENT = { id: EV, state: 'ready',
      event: { id: EV, kind: 'ryder', name: 'The Fixture Cup', status: 'complete', winner_team_id: T1, session_count: 1, starts_on: '2026-09-06', created_by: 'someone-else' },
      teams: [{ id: T1, slot: 0, name: 'Pines', color: 0 }, { id: T2, slot: 1, name: 'Oaks', color: 1 }],
      players, sessions: [{ id: 's1', session_no: 1, status: 'closed', opens_on: '2026-09-06', closes_on: '2026-09-12' }],
      duels: [{ id: 'd1', session_id: 's1', a_player: 'p0', b_player: 'p4', result: 'a', a_pvi: 1.2, b_pvi: -0.4 },
              { id: 'd2', session_id: 's1', a_player: 'p1', b_player: 'p5', result: 'b', a_pvi: -2.0, b_pvi: 0.8 },
              { id: 'd3', session_id: 's1', a_player: 'p2', b_player: 'p6', result: 'halve', a_pvi: 0.1, b_pvi: 0.1 }],
      scoreboard: { [T1]: 7, [T2]: 5 }, targets: {}, posts: [],
      lineage: [{ event_id: EV, kind: 'ryder', status: 'complete', winner_slot: 0 }, { event_id: 'e2', kind: 'ryder', status: 'setup' }] }
    switchView('event'); window.renderEvent()
    /* 2026-09-28 · §9.1 (detector TP-04): at a phone's width the clash board
       abbreviates the GIVEN name for every row ("B. Sample lost to F. Sample")
       rather than cutting a surname, so the visible words are compared in the
       form the board is in, and the row's spoken sentence keeps every name
       whole. The verb is the same truth either way. */
    const narrow = innerWidth <= 480
    const form = n => narrow ? n.replace(/^(\S)\S*\s+/, '$1. ') : n
    const rows = [...document.querySelectorAll('#eventBody .evclash .top')].map(t => t.textContent.replace(/\s+/g, ' ').trim())
    const said = [...document.querySelectorAll('#eventBody .evclash')].map(c => c.getAttribute('aria-label') || '')
    const want = { b: `${form('Blake Sample')} lost to ${form('Finley Sample')}`, bDef: `${form('Blake Sample')} def.`, a: `${form('Avery Fixture')} def. ${form('Emery Fixture')}` }
    const series = [...document.querySelectorAll('#eventBody p.fine')].map(p => p.textContent).find(t => /Ryder ·/.test(t)) || ''
    const a = document.querySelector('#eventBody .evside.a'), b = document.querySelector('#eventBody .evside.b')
    let overlap = null
    if (a && b) {
      const ar = a.getBoundingClientRect(), br = b.getBoundingClientRect()
      const discs = s => [...s.querySelectorAll('.who .d')].map(d => d.getBoundingClientRect())
      overlap = { sides: ar.right > br.left + 0.5, aOut: discs(a).some(r => r.right > ar.right + 0.5 || r.left < ar.left - 0.5), bOut: discs(b).some(r => r.right > br.right + 0.5 || r.left < br.left - 0.5) }
    }
    return { rows, said, want, series, overlap, page: document.documentElement.scrollWidth - innerWidth }
  })
  check(`${label}: a B win reads "${room.rows[1]}" — the loser is never the one who "def."`, (room.rows[1] || '').includes(room.want.b) && !(room.rows[1] || '').includes(room.want.bDef) && /^Blake Sample lost to Finley Sample\b/.test(room.said[1] || ''), room)
  check(`${label}: an A win reads "def.", a halve reads "halved"`, (room.rows[0] || '').includes(room.want.a) && /halved/.test(room.rows[2] || '') && /^Avery Fixture beat Emery Fixture\b/.test(room.said[0] || ''), room)
  check(`${label}: the finished edition's series line counts its own result ("${room.series}")`, /The 1st Ryder · Pines hold the Ryder 1–0/.test(room.series) && !/all square 0–0/.test(room.series), room.series)
  check(`${label}: two four-golfer sides never overlap, and the page stays put`, room.overlap && !room.overlap.sides && !room.overlap.aOut && !room.overlap.bOut && room.page <= 0, room)
  await shot('ryder')

  /* ---- Compete rows */
  const rows = await page.evaluate(() => {
    const L1 = 'l1', L2 = 'l2'
    const facts = new Map([
      [L1, { season: { id: 'se1', week_no: 1, weeks_total: 12, starts_on: '2026-09-29' }, standing: { points_rank: 1, of: 8, points: 0 } }],
      [L2, { season: { id: 'se2', week_no: 3, weeks_total: 12, starts_on: '2026-09-13', days_to_first_tee: 0 }, standing: { points_rank: 2, of: 8, points: 14, gap_to_leader: 3, leader_name: 'Blake Sample' } }],
    ])
    const ms = [{ role: 'member', league: { id: L1, name: 'Fixture League One', phase: 'season' } }, { role: 'member', league: { id: L2, name: 'Fixture League Two', phase: 'season' } }]
    const events = [{ id: 'ev1', name: 'The Fixture Cup', status: 'live', kind: 'ryder' }, { id: 'ev2', name: 'The Fixture Open', status: 'live', kind: 'ryder', starts_on: '2026-09-27' }]
    const out = csCompeteList(ms, events, [], null, facts)
    const all = [...(out.seasons || []), ...(out.moments || []), ...(out.finished || [])]
    const by = id => all.find(r => r.id === id) || {}
    return { up: by('league:l1'), live: by('league:l2'), ev1: by('event:ev1'), ev2: by('event:ev2') }
  })
  check(`${label}: tomorrow's first tee on a Phoenix evening is Upcoming, "${rows.up.eyebrow}"`, rows.up.state === 'Upcoming' && rows.up.eyebrow === 'Before first tee' && !rows.up.figure, rows.up)
  check(`${label}: a season under way is Live, "${rows.live.eyebrow}"`, rows.live.state === 'Live' && rows.live.eyebrow === 'Week 3 of 12', rows.live)
  check(`${label}: a live Ryder with no date says "${rows.ev1.eyebrow}", never Forming; with a date, the day`, rows.ev1.eyebrow === 'Live' && rows.ev2.eyebrow && rows.ev2.eyebrow !== 'Forming', { ev1: rows.ev1, ev2: rows.ev2 })

  /* ---- the Cup Final race: no per-golfer cap beside a squad's rounds */
  const race = await page.evaluate(() => {
    teams.length = 0; teams.push({ id: 'sq1', name: 'Fixture Wrens', ci: 0 }, { id: 'sq2', name: 'Fixture Javelinas', ci: 1 })
    CS.season = { status: 'cup_final' }
    window.cupRace = { status: 'live', days_left: 12, cap_n: 3, finalists: [
      { squad_id: 'sq1', seed: 1, head_start: 10, window_points: 20, total: 30, rounds_used: 4 },
      { squad_id: 'sq2', seed: 2, head_start: 0, window_points: 26, total: 26, rounds_used: 5 }] }
    switchView('hub'); renderCupRace()
    return [...document.querySelectorAll('#cupRace .tc')].map(t => t.textContent)
  })
  check(`${label}: the race prints a squad's rounds alone ("${race[0]}")`, race.length === 2 && race.every(t => /\d ROUNDS?$/.test(t) && !/ OF \d/.test(t)), race)

  /* ---- a season section lands below the sticky bar (phone) */
  if (width < 960) {
    const landed = await page.evaluate(async () => {
      document.body.classList.remove('noleague'); state.stake = 75; switchView('hub'); document.getElementById('room-pot').style.display = ''; window.scrollTo(0, 0); setRoomSeg('pot')
      await new Promise(r => setTimeout(r, 900))
      const bar = document.querySelector('.hdr').getBoundingClientRect(), pot = document.getElementById('room-pot').getBoundingClientRect()
      return { bar: Math.round(bar.bottom), pot: Math.round(pot.top), room: document.getElementById('room-pot').parentElement.id }
    })
    check(`${label}: the pot section lands below the bar (${landed.pot} ≥ ${landed.bar})`, landed.pot >= landed.bar, landed)
  } else {
    const pot = await page.evaluate(() => {
      document.body.classList.remove('noleague'); state.stake = 75; window.csDeskColumns?.(); switchView('hub'); document.getElementById('room-pot').style.display = ''
      /* real-sized money: a four-figure pot's split */
      ;[['pay1', '$1,440'], ['pay2', '$600'], ['pay3', '$360']].forEach(([id, v]) => { const e = document.getElementById(id); if (e) e.textContent = v })
      const room = document.getElementById('room-pot'), grid = room.querySelector('.potgrid')
      const money = [...room.querySelectorAll('.trip .p b')].map(b => ({ t: b.textContent, w: b.clientWidth, clipped: !b.clientWidth || b.scrollWidth > b.clientWidth + 1 }))
      return { slot: room.parentElement.id, grid: getComputedStyle(grid).display, money }
    })
    check(`${label}: the pot in the desk aside is one column and prints whole money (${pot.money.map(m => m.t).join(' / ')})`, pot.slot === 'deskPotSlot' && pot.grid === 'block' && pot.money.length === 3 && pot.money.every(m => !m.clipped), pot)
    const dlg = await page.evaluate(() => {
      const d = document.createElement('dialog'); d.className = 'sb-dialog'; d.innerHTML = '<p>fixture</p>'; document.body.appendChild(d); d.showModal()
      const r = d.getBoundingClientRect(); const out = { left: Math.round(r.left), right: Math.round(innerWidth - r.right), top: Math.round(r.top), bottom: Math.round(innerHeight - r.bottom) }
      d.close(); d.remove(); return out
    })
    check(`${label}: the Book's dialog is centred on the desk (${dlg.left}/${dlg.right} · ${dlg.top}/${dlg.bottom})`, Math.abs(dlg.left - dlg.right) <= 1 && Math.abs(dlg.top - dlg.bottom) <= 1, dlg)
  }

  /* ---- the Home hero and Up Next */
  const hero = await page.evaluate(() => {
    window.__leadOwnsToday = false; window.career = { rounds: 0 }; window.buddyCount = 0
    switchView('home'); renderHomeHero()
    const h = document.querySelector('#homeHero .hhero'); if (!h) return null
    const bg = getComputedStyle(h).backgroundColor, line = h.querySelector('.hh-line'), top = h.querySelector('.hh-top'), cta = h.querySelector('.hh-cta')
    const act = getComputedStyle(document.documentElement).getPropertyValue('--act').trim()
    const probe = document.createElement('i'); probe.style.color = act; document.body.appendChild(probe); const actRgb = getComputedStyle(probe).color; probe.remove()
    return { calm: h.classList.contains('calm'), line: window.__ratio(getComputedStyle(line).color, bg), top: window.__ratio(getComputedStyle(top).color, bg),
      ctaBg: getComputedStyle(cta).backgroundColor, actRgb, cta: window.__ratio(getComputedStyle(cta).color, getComputedStyle(cta).backgroundColor), text: cta.textContent }
  })
  check(`${label}: the hero's words read on it (${hero && hero.line.toFixed(2)}:1, label ${hero && hero.top.toFixed(2)}:1)`, hero && hero.line >= 4.5 && hero.top >= 4.5, hero)
  check(`${label}: its one move ("${hero && hero.text}") is the action green, and reads (${hero && hero.cta.toFixed(2)}:1)`, hero && hero.calm && hero.ctaBg === hero.actRgb && hero.cta >= 4.5, hero)
  const chip = await page.evaluate(() => {
    const box = document.getElementById('homeUpNext')
    box.innerHTML = upChip('Next round', 'Sat Oct 3 · The Championship Course at Whispering Fixture Pines Country Club — Championship', 'schedule', false)
    const c = box.querySelector('.upchip'), r = c.getBoundingClientRect(), col = box.getBoundingClientRect()
    return { right: r.right, colRight: col.right, h: r.height, page: document.documentElement.scrollWidth - innerWidth, whole: /Championship$/.test(c.querySelector('b').textContent) }
  })
  check(`${label}: a long Next round wraps inside its chip (${Math.round(chip.h)}px tall), whole, and the page does not scroll sideways`, chip.right <= chip.colRight + 0.5 && chip.h >= 44 && chip.page <= 0 && chip.whole, chip)
  await shot('home')

  /* ---- the RSVP set on the sheet */
  const rsvp = await page.evaluate(() => {
    openSheet('A round', '', '<div class="rsvpset"><button class="rbtn" data-rsvp="in">I’m in</button><button class="rbtn on maybe" data-rsvp="maybe">Maybe</button><button class="rbtn" data-rsvp="out">Can’t</button></div>')
    const bs = [...document.querySelectorAll('#sheet .rbtn')]
    const out = bs.map(b => ({ t: b.textContent, h: b.getBoundingClientRect().height, c: window.__ratio(getComputedStyle(b).color, window.__bgOf(b)) }))
    closeSheet(); return out
  })
  check(`${label}: the RSVP buttons read on the sheet (${rsvp.map(b => b.c.toFixed(2)).join(' / ')}) and reach 44`, rsvp.length === 3 && rsvp.every(b => b.c >= 4.5 && b.h >= 44), rsvp)
  check(`${label}: no page errors`, errs.length === 0, errs)
  await ctx.close()
}
await browser.close()
const failed = results.filter(r => !r.ok)
console.log(`\n${results.length - failed.length}/${results.length} passed`)
process.exit(failed.length ? 1 : 0)
