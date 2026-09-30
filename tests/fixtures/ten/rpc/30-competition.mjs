/* Cup Season · ten-capture fixtures, COMPETITION (WX-C, 2026-09-28).
 *
 * The reads the season page, Compete, the Book (D381) and the event rooms make,
 * answered by PRODUCERS over the synthetic world's own tables -- never by
 * canned payloads -- so every figure a capture shows is traceable to
 * W.tables.rounds / v_rounds_ranked (spec §16). Each producer follows the
 * latest SQL definition in supabase/migrations, named beside it.
 *
 *   season_story          20261012090000 (S-35) + 20261204090000 [I6] final facts
 *   season_scenarios      20261204090000 [I6]
 *   cup_final_race        20260902170000 (cap_note)
 *   season_book           20261118090000 (v1 envelope -- see VERSION below)
 *   league_cancel_status  20261012090000
 *   major_leaderboard     20260720193000 (major_board)
 *   event_session_targets 20260716150000
 *   event_lineage         20260724100000
 *
 * install(W) also repairs TWO world shapes in this module's scope:
 * `standings_snapshots.standings` is `{ squads:[v_squad_standings rows],
 * individuals:[v_individual_standings rows] }` in production (snapshot_week,
 * 20260831130000); the core world wrote a flat array with invented points. The
 * snapshots are rebuilt here from the rounds, week by week, with the month cap
 * applied as of each capture date. And home_dispatch's membership standings
 * gain D381's `points_rank` / `points_tied` where rpc/10 leaves them out
 * (standingRanks). It adds the two empty tables a season read names that the
 * core world lacks: season_payouts and cup_finalists.
 *
 * The named exports are the world transforms the competition states run in
 * prepare(W): a Book world adopted from a synthetic envelope (adoptBook, read
 * at the capture clock by bookAt), close_season's crown (crownSeason), the
 * Cup Final seed lock (cupFinalOn) and two editions of a Ryder (ryderWorld).
 * They mutate only the capture's own world. */
import { readFileSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath } from 'node:url'

const HERE = dirname(fileURLToPath(import.meta.url))
const TEN = join(HERE, '..')

/* ------------------------------------------------------------------ dates */
const D = (iso) => { const [y, m, d] = String(iso).slice(0, 10).split('-').map(Number); return Date.UTC(y, m - 1, d) }
const iso = (t) => new Date(t).toISOString().slice(0, 10)
export const addDays = (s, n) => iso(D(s) + n * 864e5)
export const diffDays = (a, b) => Math.round((D(a) - D(b)) / 864e5)
const monthOf = (s) => String(s).slice(0, 7)
const monthStart = (s) => monthOf(s) + '-01'
/* a timestamptz as a UTC session renders it inside jsonb */
export const tsz = (s) => new Date(s).toISOString().replace(/\.\d{3}Z$/, '+00:00')
/* the local (America/Phoenix, UTC-7, no DST) calendar day of an instant */
const localDay = (s) => iso(Date.parse(s) - 7 * 3600e3)
const r1 = (x) => Math.round(x * 10) / 10
const firstname = (n) => (n == null ? 'Someone' : String(n).trim().split(/\s+/)[0])

/* -------------------------------------------------------------- lookups */
const T_ = (W, t) => (W.tables[t] ||= [])
const seasonById = (W, id) => T_(W, 'seasons').find((s) => s.id === id) || null
const settingsOf = (W, lid) => T_(W, 'league_settings').find((s) => s.league_id === lid) || {}
const leagueById = (W, id) => T_(W, 'leagues').find((l) => l.id === id) || null
const profileById = (W, id) => T_(W, 'profiles').find((p) => p.id === id) || null
const memberById = (W, id) => T_(W, 'league_members').find((m) => m.id === id) || null
const memberName = (W, id) => { const m = memberById(W, id); const p = m && profileById(W, m.profile_id); return p ? p.display_name : null }
const myMemberId = (W, lid) => (T_(W, 'league_members').find((m) => m.league_id === lid && m.profile_id === W.me) || {}).id || null
const squadsOf = (W, sid) => T_(W, 'squads').filter((q) => q.season_id === sid)
const squadMembers = (W, qid) => T_(W, 'squad_members').filter((x) => x.squad_id === qid).map((x) => x.member_id)
const mySquadId = (W, sid, mid) => (squadsOf(W, sid).find((q) => squadMembers(W, q.id).includes(mid)) || {}).id || null
const capOf = (W, lid) => { const c = settingsOf(W, lid).counting_cap; return c == null ? null : Number(c) }
const tz = (se) => se.timezone || 'America/Phoenix'
const weeksTotal = (se) => Math.max(1, Math.ceil(diffDays(se.ends_on, se.starts_on) / 7))
const weekNo = (se, today) => Math.max(1, Math.min(weeksTotal(se), Math.floor(diffDays(today, se.starts_on) / 7) + 1))

/* ============================================================ SNAPSHOTS */
/* standings as of the start of day `day`: rounds played before it, each
   member-month ranked by PvI inside that subset (the cap as it stood then),
   plus the ledger rows assessed before it */
function standingsAsOf(W, se, day) {
  const cap = capOf(W, se.league_id)
  const members = T_(W, 'league_members').filter((m) => m.league_id === se.league_id)
  const individuals = members.map((m) => {
    const rr = T_(W, 'v_rounds_ranked').filter((x) => x.season_id === se.id && x.member_id === m.id && x.played_on < day)
    const byM = {}
    for (const r of rr) (byM[monthOf(r.played_on)] ||= []).push(r)
    let points = 0
    for (const list of Object.values(byM)) { list.sort((a, b) => b.pvi - a.pvi); (cap == null ? list : list.slice(0, cap)).forEach((r) => { points += r.points }) }
    points += T_(W, 'season_adjustments').filter((a) => a.season_id === se.id && a.member_id === m.id && a.kind === 'override' && localDay(a.created_at) < day).reduce((s, a) => s + a.points, 0)
    return { season_id: se.id, league_id: se.league_id, member_id: m.id, profile_id: m.profile_id, points, rounds_posted: rr.length }
  })
  const squads = squadsOf(W, se.id).map((q) => {
    const ids = squadMembers(W, q.id)
    let points = individuals.filter((i) => ids.includes(i.member_id)).reduce((s, i) => s + i.points, 0)
    points += T_(W, 'season_adjustments').filter((a) => a.season_id === se.id && a.squad_id === q.id && a.kind !== 'override' && a.kind !== 'month_closed' && localDay(a.created_at) < day).reduce((s, a) => s + a.points, 0)
    return { season_id: se.id, squad_id: q.id, points }
  })
  const desc = (a, b) => b.points - a.points
  return { squads: squads.sort(desc), individuals: individuals.sort(desc) }
}
/* snapshot_week: week w is written on starts_on + 7w (the Sunday cron, 07:10 UTC) */
export function rebuildSnapshots(W, seasonIds = null) {
  const keep = T_(W, 'standings_snapshots').filter((s) => seasonIds && !seasonIds.includes(s.season_id))
  const out = [...keep]
  for (const se of T_(W, 'seasons')) {
    if (seasonIds && !seasonIds.includes(se.id)) continue
    if (!['active', 'cup_final', 'complete'].includes(se.status)) continue
    const total = Math.ceil((diffDays(se.ends_on, se.starts_on) + 1) / 7)
    for (let w = 1; w <= total; w++) {
      const day = addDays(se.starts_on, 7 * w)
      if (day > W.today || day > addDays(se.ends_on, 1)) break
      out.push({ id: `fc100000-0000-4000-8000-${String(Number(se.id.slice(-4)) * 100 + w).padStart(12, '0')}`, season_id: se.id, week_no: w, captured_at: `${day}T07:10:00+00:00`, standings: standingsAsOf(W, se, day) })
    }
  }
  W.tables.standings_snapshots = out
  return out
}

/* ============================================================ SCENARIOS */
export function seasonScenarios(W, seasonId) {
  const se = seasonById(W, seasonId); if (!se) return null
  const ls = settingsOf(W, se.league_id)
  const finish = ls.finish || 'cup_final', struct = ls.structure || 'squads2'
  const cap = ls.counting_cap == null ? 999 : Number(ls.counting_cap)
  const fins = T_(W, 'cup_finalists').filter((c) => c.season_id === se.id)
  const locked = se.status === 'cup_final' || (se.status === 'complete' && fins.length > 0)
  const seedEnd = finish === 'cup_final' ? addDays(se.ends_on, -27) : se.ends_on
  let months = 0
  if (!locked && seedEnd >= W.today) {
    const ym = (s) => Number(s.slice(0, 4)) * 12 + Number(s.slice(5, 7))
    months = Math.max(0, ym(seedEnd) - ym(W.today) + 1)
  }
  const level = struct === 'solo' ? 'member' : 'squad'
  const k = struct === 'solo' ? (finish === 'points_table' ? 1 : 2) : (finish === 'points_table' ? 1 : struct === 'squads2' ? 1 : 2)
  const base = level === 'squad'
    ? squadsOf(W, se.id).map((q) => ({ level, id: q.id, name: q.name, points: (T_(W, 'v_squad_standings').find((s) => s.squad_id === q.id && s.season_id === se.id) || {}).points || 0, roster: Math.max(1, squadMembers(W, q.id).length) }))
    : T_(W, 'v_individual_standings').filter((i) => i.season_id === se.id).map((i) => ({ level, id: i.member_id, name: memberName(W, i.member_id), points: i.points || 0, roster: 1 }))
  const finc = base.map((b) => ({ ...b, max_final: b.points + b.roster * months * cap * 12, seed: (fins.find((c) => c.squad_id === b.id || c.member_id === b.id) || {}).seed ?? null }))
  const kth = (arr) => { const s = arr.sort((a, b) => b - a); return s.length >= k ? s[k - 1] : -1 }
  const rows = finc.map((f) => {
    const clinch = kth(finc.filter((o) => o.id !== f.id).map((o) => o.max_final))
    const elim = kth(finc.filter((o) => o.id !== f.id).map((o) => o.points))
    const rank = 1 + finc.filter((o) => o.points > f.points).length
    return { level: f.level, id: f.id, name: f.name, points: f.points, max_final: f.max_final, roster: f.roster, rank, seed: f.seed,
      clinched: locked ? f.seed != null : f.points > clinch,
      eliminated: locked ? f.seed == null : elim > f.max_final,
      needs: locked || f.points > clinch ? 0 : Math.max(0, clinch - f.points + 1) }
  }).sort((a, b) => b.points - a.points || String(a.name).localeCompare(String(b.name)))
  const seeds = fins.slice().sort((a, b) => a.seed - b.seed).map((c) => ({ seed: c.seed, id: c.squad_id || c.member_id,
    name: c.squad_id ? (T_(W, 'squads').find((q) => q.id === c.squad_id) || {}).name : memberName(W, c.member_id), head_start: c.head_start ?? 0, rung: c.seed_rung ?? null }))
  return { meta: { finish, structure: struct, level, k, seed_end: seedEnd, months_left: months, locked, cap, status: se.status, ends_on: se.ends_on, seeds }, rows }
}

/* ============================================================ CUP FINAL RACE */
export function cupFinalRace(W, seasonId) {
  const se = seasonById(W, seasonId); if (!se) return null
  const st = settingsOf(W, se.league_id)
  const solo = st.structure === 'solo'
  const capN = st.counting_cap == null ? 10000 : Number(st.counting_cap)
  const capNote = st.counting_cap != null ? `Best ${st.counting_cap} per calendar month still applies — a round posted before the window can hold a slot.` : null
  const wStart = addDays(se.ends_on, -27)
  const head = { season_status: se.status, solo, window_start: wStart, window_end: se.ends_on, cap_n: capN, cap_note: capNote, days_left: Math.max(0, diffDays(se.ends_on, W.today)) }
  const fins = T_(W, 'cup_finalists').filter((c) => c.season_id === se.id).sort((a, b) => a.seed - b.seed)
  if (!fins.length) return { status: 'pending', ...head, finalists: [], seed_rung: null }
  const windowRounds = T_(W, 'v_rounds_ranked').filter((r) => r.season_id === se.id && r.month_rank <= capN && r.played_on >= wStart && r.played_on <= se.ends_on)
  const finalists = fins.map((cf) => {
    const who = cf.member_id ? [cf.member_id] : squadMembers(W, cf.squad_id)
    const w = windowRounds.filter((r) => who.includes(r.member_id)).sort((a, b) => (a.played_on < b.played_on ? 1 : -1))
    const q = cf.squad_id ? T_(W, 'squads').find((x) => x.id === cf.squad_id) : null
    const pts = w.reduce((s, r) => s + r.points, 0)
    return { seed: cf.seed, head_start: cf.head_start ?? 0, seed_rung: cf.seed_rung ?? null, squad_id: cf.squad_id || null, member_id: cf.member_id || null,
      name: q ? q.name : (memberName(W, cf.member_id) || 'A golfer'), color: q ? q.color : null,
      window_points: pts, rounds_used: w.length, last_round_on: w.length ? w[0].played_on : null, total: (cf.head_start ?? 0) + pts,
      rounds: w.map((r) => ({ round_id: r.round_id, played_on: r.played_on, points: r.points, month_rank: r.month_rank, pvi: r.pvi, holes_played: r.holes_played, member_id: r.member_id, golfer: memberName(W, r.member_id) || 'A golfer' })) }
  })
  const rung = (fins.slice().sort((a, b) => b.seed - a.seed).find((c) => c.seed_rung) || {}).seed_rung ?? null
  return { status: se.status === 'complete' ? 'complete' : 'live', ...head, finalists, seed_rung: rung }
}

/* ============================================================ SEASON STORY */
export function seasonStory(W, { p_season = null, p_league = null } = {}) {
  let se = null
  if (p_season) se = seasonById(W, p_season)
  else if (p_league) se = T_(W, 'seasons').filter((s) => s.league_id === p_league)
    .sort((a, b) => (Number(['active', 'cup_final'].includes(b.status)) - Number(['active', 'cup_final'].includes(a.status))) || (a.starts_on < b.starts_on ? 1 : -1))[0] || null
  if (!se) return null
  const ls = settingsOf(W, se.league_id)
  const league = leagueById(W, se.league_id)
  const solo = (ls.structure || 'squads2') === 'solo'
  const finish = ls.finish || 'cup_final'
  const today = W.today
  const weeks = weeksTotal(se), week = weekNo(se, today)
  const ends = addDays(se.starts_on, Math.floor(Math.max(0, diffDays(today, se.starts_on)) / 7) * 7 + 6)
  const opens = finish === 'cup_final' ? addDays(se.ends_on, -27) : null
  const me = myMemberId(W, se.league_id)
  const cap = ls.counting_cap == null ? 2147483647 : Number(ls.counting_cap)

  /* THE TABLE, now */
  let now
  if (solo) {
    now = T_(W, 'v_individual_standings').filter((v) => v.season_id === se.id)
      .map((v) => ({ id: v.member_id, name: memberName(W, v.member_id) || 'A golfer', points: v.points || 0,
        rounds: v.rounds_posted || 0,
        counted: T_(W, 'v_rounds_ranked').filter((r) => r.member_id === v.member_id && r.season_id === se.id && monthOf(r.played_on) === monthOf(today) && r.month_rank <= cap).length,
        left: !!(memberById(W, v.member_id) || {}).left_at, is_me: v.member_id === me }))
  } else {
    now = squadsOf(W, se.id).map((q) => ({ id: q.id, name: q.name, points: (T_(W, 'v_squad_standings').find((s) => s.squad_id === q.id && s.season_id === se.id) || {}).points || 0,
      rounds: null, counted: null, left: false, is_me: squadMembers(W, q.id).includes(me) }))
  }
  now.sort((a, b) => b.points - a.points || (a.id < b.id ? -1 : 1))
  now.forEach((r, i) => { r.rank = i + 1 })
  now = now.map(({ id, name, points, rank, rounds, counted, left, is_me }) => ({ id, name, points, rank, rounds, counted, left, is_me }))
  const nameIn = (id) => (now.find((x) => x.id === id) || {}).name ?? null

  /* EVERY WEEKLY SNAPSHOT, ranked */
  const snaps = T_(W, 'standings_snapshots').filter((s) => s.season_id === se.id).sort((a, b) => a.week_no - b.week_no).map((s) => {
    const arr = ((s.standings || {})[solo ? 'individuals' : 'squads']) || []
    const rows = arr.map((x) => ({ id: x.squad_id || x.member_id, points: Number(x.points || 0) }))
      .sort((a, b) => b.points - a.points || (a.id < b.id ? -1 : 1)).map((x, i) => ({ id: x.id, points: x.points, rank: i + 1 }))
    return { week: s.week_no, at: tsz(s.captured_at), rows }
  })
  const top = (s) => (s && s.rows[0] ? s.rows[0].id : '')

  /* THE FACTS */
  const lead = now[0] || null
  let run = 0
  if (lead && snaps.length) for (let i = snaps.length - 1; i >= 0 && top(snaps[i]) === lead.id; i--) run++
  let flip = null
  for (let i = snaps.length - 1; i >= 1; i--) {
    const w = snaps[i], wp = snaps[i - 1]
    if (top(w) !== top(wp) && top(w) !== '') {
      flip = { week: w.week, on: w.at, to: nameIn(top(w)), to_id: top(w), from: nameIn(top(wp)),
        first_time: !snaps.some((s2) => s2.week < w.week && top(s2) === top(w)), source: 'standings_snapshots' }
      break
    }
  }
  let closer = null
  if (snaps.length >= 3 && lead) {
    const sNow = snaps[snaps.length - 1], sThen = snaps[snaps.length - 3]
    const leadNow = (sNow.rows[0] || {}).points || 0, leadThen = (sThen.rows[0] || {}).points || 0
    let best = 0
    for (let j = 1; j <= Math.max(1, sNow.rows.length) - 1; j++) {
      const r = sNow.rows[j]; if (!r) continue
      const gapNow = leadNow - r.points
      const gapThen = leadThen - ((sThen.rows.find((x) => x.id === r.id) || {}).points || 0)
      if (gapThen > 0 && gapNow <= gapThen / 2 && gapThen - gapNow > best) { best = gapThen - gapNow; closer = { name: nameIn(r.id), taken: gapThen - gapNow, weeks: 2, source: 'standings_snapshots' } }
    }
  }
  let final = null
  if (opens) {
    let live = null, scen = null
    try { scen = seasonScenarios(W, se.id); live = (scen.rows || []).filter((x) => !x.eliminated).length } catch { live = null }
    const locked = !!(scen && scen.meta && scen.meta.locked)
    final = { opens_on: opens, in_weeks: opens < today ? null : Math.ceil(diffDays(opens, today) / 7), seats: 2, still_live: live,
      locked, seeds: (scen && scen.meta && scen.meta.seeds) || [], race: locked ? cupFinalRace(W, se.id) : null, source: 'season_scenarios' }
  }
  const facts = {
    week_no: week, weeks_total: weeks, weeks_left: Math.max(0, weeks - week), week_ends_on: ends, field: now.length,
    leader: lead ? { id: lead.id, name: lead.name, points: lead.points, run_weeks: run, since: null, is_me: !!lead.is_me, source: 'standings_snapshots' } : null,
    runner_up: now.length < 2 ? null : { name: now[1].name, points: now[1].points },
    top_gap: now.length < 2 ? null : now[0].points - now[1].points,
    lead_flip: flip, closer, final,
    last_snapshot_on: snaps.length ? snaps[snaps.length - 1].at : null,
  }

  /* RUNG 7 · the reach back */
  const hist = []
  const mine = now.find((x) => x.is_me) || null
  if (me && typeof W.handlers.my_rivalries === 'function') {
    try {
      const riv = ([].concat(W.handlers.my_rivalries({}, W) || []))
        .filter((r) => T_(W, 'league_members').some((m) => m.league_id === se.league_id && m.profile_id === r.opponent))
        .sort((a, b) => (b.meetings || 0) - (a.meetings || 0) || String(a.display_name).localeCompare(String(b.display_name)))[0]
      if (riv) {
        const opp = (T_(W, 'league_members').find((m) => m.league_id === se.league_id && m.profile_id === riv.opponent) || {}).id
        const seasonIds = T_(W, 'seasons').filter((s) => s.league_id === se.league_id).map((s) => s.id)
        const settled = T_(W, 'week_clashes').filter((c) => seasonIds.includes(c.season_id) && c.settled_at && ((c.a_member === me && c.b_member === opp) || (c.b_member === me && c.a_member === opp)))
        const since = settled.map((c) => localDay(c.settled_at)).sort().pop()
        if (since) hist.push({ kind: 'unsettled_week', source: 'week_clashes', record_source: 'my_rivalries', opponent: riv.display_name, since, days: diffDays(today, since), wins: riv.wins || 0, losses: riv.losses || 0, ties: riv.ties || 0 })
      }
    } catch { /* my_rivalries not there: one fewer candidate */ }
  }
  if (mine && snaps.length >= 2) {
    const rankIn = (s) => (s.rows.find((x) => x.id === mine.id) || {}).rank ?? null
    const myRank = rankIn(snaps[snaps.length - 1])
    if (myRank != null) {
      let streak = 0
      for (let i = snaps.length - 1; i >= 0 && rankIn(snaps[i]) === myRank; i--) streak++
      if (streak >= 2) hist.push({ kind: 'my_run', source: 'standings_snapshots', rank: myRank, weeks: streak })
    }
    let best = 0, bw = null
    for (let i = 1; i < snaps.length; i++) {
      const cur = (snaps[i].rows.find((x) => x.id === mine.id) || {}).points || 0
      const prev = (snaps[i - 1].rows.find((x) => x.id === mine.id) || {}).points || 0
      if (cur - prev > best) { best = cur - prev; bw = snaps[i].week }
    }
    if (best > 0) hist.push({ kind: 'my_best_week', source: 'standings_snapshots', week: bw, points: best })
  }

  /* THE ARC, newest first */
  let arc = []
  for (let o = 1; o < snaps.length; o++) {
    const s2 = snaps[o], sp = snaps[o - 1]
    if (top(s2) !== top(sp) && top(s2) !== '') arc.push({ kind: 'lead_change', source: 'standings_snapshots', week: s2.week, on: s2.at, subject: nameIn(top(s2)), other: nameIn(top(sp)) })
  }
  if (me) {
    for (const wc of T_(W, 'week_clashes').filter((c) => c.season_id === se.id && c.settled_at && (c.a_member === me || c.b_member === me))) {
      arc.push({ kind: 'clash', source: 'week_clashes', week: wc.week_no, on: tsz(wc.settled_at),
        subject: wc.winner_member === me ? 'you' : (wc.winner_member ? memberName(W, wc.winner_member) : null),
        other: memberName(W, wc.a_member === me ? wc.b_member : wc.a_member) || 'a golfer in your season', mine: true })
    }
  }
  const posts = T_(W, 'posts').filter((p) => p.league_id === se.league_id && ['moment', 'system'].includes(p.kind)
    && localDay(p.created_at) >= se.starts_on && localDay(p.created_at) <= se.ends_on)
    .sort((a, b) => Date.parse(b.created_at) - Date.parse(a.created_at)).slice(0, 40)
  for (const po of posts) arc.push({ kind: 'post', source: 'posts', week: Math.max(1, Math.min(weeks, Math.floor(diffDays(localDay(po.created_at), se.starts_on) / 7) + 1)), on: tsz(po.created_at), text: po.body, post_kind: po.kind })
  arc = arc.sort((a, b) => (a.on == null ? 1 : b.on == null ? -1 : a.on < b.on ? 1 : a.on > b.on ? -1 : 0))

  /* THE ARCHIVE */
  const archive = T_(W, 'seasons').filter((s) => s.league_id === se.league_id).sort((a, b) => b.number - a.number).map((s) => ({
    season_id: s.id, number: s.number, starts_on: s.starts_on, ends_on: s.ends_on, status: s.status,
    champion: (s.champion_squad_id && (T_(W, 'squads').find((q) => q.id === s.champion_squad_id) || {}).name) || (s.champion_member_id && memberName(W, s.champion_member_id)) || null,
    is_current: s.id === se.id }))

  return {
    season: { id: se.id, league_id: se.league_id, league: league ? league.name : null, number: se.number, starts_on: se.starts_on, ends_on: se.ends_on,
      status: se.status, finish, structure: ls.structure || 'squads2', solo, today, my_member_id: me, i_left: !!(memberById(W, me) || {}).left_at },
    facts, history: hist, arc, table: now, archive, generated_at: tsz(W.now),
  }
}

/* ============================================================ THE BOOK */
/* VERSION · the clients validate `version === 1` (index.html SeasonBook.validate,
   the phone's SeasonBookSnapshot). 20261130090000 emitted version 2, and
   20261205090000 (applied in prod) patched the envelope back to version 1 on
   purpose, KEEPING the additive `frozen` and `withdrawn` fields: "both deployed
   Book readers require envelope version 1". The producer answers as prod does. */
const VERSION = 1
const BOOK_DROP = (cap) => `Outside the best ${cap} for this calendar month; the round stays in the record.`
export function seasonBook(W, leagueId, seasonId) {
  /* a state that adopted a synthetic envelope answers with it, verbatim */
  if (W.book && W.book.league_id === leagueId && W.book.season_id === seasonId) return JSON.parse(JSON.stringify(W.book))
  const se = seasonById(W, seasonId)
  const viewer = T_(W, 'league_members').find((m) => m.league_id === leagueId && m.profile_id === W.me && !m.left_at && !m.suspended_at && (m.agreed_seasons || []).includes(se && se.number))
  if (!se || se.league_id !== leagueId || !viewer) return null
  const ls = settingsOf(W, leagueId)
  const cap = ls.counting_cap == null ? 999 : Number(ls.counting_cap)
  const weekCount = Math.floor(diffDays(se.ends_on, se.starts_on) / 7) + 1
  const thisWeek = W.today < se.starts_on ? 0 : Math.min(weekCount, Math.floor(diffDays(W.today, se.starts_on) / 7) + 1)
  const weeks = Array.from({ length: weekCount }, (_, i) => ({ week: i + 1, starts_on: addDays(se.starts_on, i * 7), ends_on: [se.ends_on, addDays(se.starts_on, (i + 1) * 7 - 1)].sort()[0] }))
  const rankOf = (arr) => arr.map((x) => ({ ...x, points_rank: 1 + arr.filter((o) => o.points > x.points).length, tied: arr.filter((o) => o.points === x.points).length > 1 }))
  const members = rankOf(T_(W, 'v_individual_standings').filter((v) => v.season_id === se.id).map((v) => ({ member_id: v.member_id, name: memberName(W, v.member_id) || 'Golfer', points: v.points || 0 })))
  const squadRows = rankOf(squadsOf(W, se.id).map((q) => ({ id: q.id, name: q.name, points: (T_(W, 'v_squad_standings').find((s) => s.squad_id === q.id && s.season_id === se.id) || {}).points || 0 })))
  const rounds = T_(W, 'v_rounds_ranked').filter((r) => r.season_id === se.id).map((r) => ({ ...r, week: Math.floor(diffDays(r.played_on, se.starts_on) / 7) + 1, counting: r.month_rank <= cap }))
  const E = []
  const roundEntry = (rowId, r, squadId) => E.push({ row_id: rowId, id: 'round:' + r.round_id, round_id: r.round_id, member_id: r.member_id, squad_id: squadId, week: r.week,
    recorded_on: r.played_on, affected_month: monthStart(r.played_on), kind: 'round', points: r.points, contribution: r.counting ? r.points : 0,
    count_state: r.counting ? 'counting' : 'dropped', reason: r.counting ? 'Counting round' : BOOK_DROP(ls.counting_cap) })
  for (const r of rounds) roundEntry('golfer:' + r.member_id, r, null)
  for (const q of squadRows) for (const mid of squadMembers(W, q.id)) for (const r of rounds.filter((x) => x.member_id === mid)) {
    roundEntry('squad:' + q.id, r, q.id); roundEntry('contribution:' + q.id + ':' + mid, r, q.id)
  }
  const adjWeek = (a) => { const d = localDay(a.created_at); return d >= se.starts_on && d <= se.ends_on ? Math.floor(diffDays(d, se.starts_on) / 7) + 1 : null }
  const adjs = T_(W, 'season_adjustments').filter((a) => a.season_id === se.id && a.kind !== 'month_closed')
  for (const a of adjs.filter((a) => members.some((m) => m.member_id === a.member_id))) E.push({ row_id: 'golfer:' + a.member_id, id: 'adjustment:' + a.id, round_id: null, member_id: a.member_id, squad_id: a.squad_id,
    week: adjWeek(a), recorded_on: localDay(a.created_at), affected_month: a.month, kind: a.kind, points: a.points, contribution: a.kind === 'override' ? a.points : 0,
    count_state: a.kind === 'bye' ? 'bye' : 'adjustment', reason: (a.reason || 'Recorded adjustment') + (!['override', 'bye'].includes(a.kind) ? ' Does not change the individual points total.' : '') })
  for (const a of adjs.filter((a) => squadRows.some((q) => q.id === a.squad_id))) E.push({ row_id: 'squad:' + a.squad_id, id: 'adjustment:' + a.id, round_id: null, member_id: a.member_id, squad_id: a.squad_id,
    week: adjWeek(a), recorded_on: localDay(a.created_at), affected_month: a.month, kind: a.kind, points: a.points, contribution: a.points,
    count_state: a.kind === 'bye' ? 'bye' : 'adjustment', reason: a.reason || 'Recorded adjustment' })
  const mySquads = squadRows.filter((q) => squadMembers(W, q.id).includes(viewer.id)).map((q) => q.id)
  const comps = [
    ...members.map((m) => ({ id: 'golfer:' + m.member_id, kind: 'golfer', name: m.name, member_id: m.member_id, squad_id: null, points: m.points, points_rank: m.points_rank, tied: m.tied, mine: m.member_id === viewer.id })),
    ...squadRows.map((q) => ({ id: 'squad:' + q.id, kind: 'squad', name: q.name, member_id: null, squad_id: q.id, points: q.points, points_rank: q.points_rank, tied: q.tied, mine: mySquads.includes(q.id) })),
    ...squadRows.flatMap((q) => squadMembers(W, q.id).map((mid) => { const m = members.find((x) => x.member_id === mid); return m ? ({ id: `contribution:${q.id}:${mid}`, kind: 'contribution', name: m.name, member_id: mid, squad_id: q.id,
      points: E.filter((e) => e.row_id === `contribution:${q.id}:${mid}`).reduce((s, e) => s + e.contribution, 0), points_rank: null, tied: false, mine: mid === viewer.id }) : null }).filter(Boolean)),
  ]
  const sum = (xs) => xs.reduce((s, e) => s + e.contribution, 0)
  const rows = comps.map((c) => {
    const es = E.filter((e) => e.row_id === c.id).sort((a, b) => (a.recorded_on == null ? 1 : b.recorded_on == null ? -1 : a.recorded_on < b.recorded_on ? -1 : a.recorded_on > b.recorded_on ? 1 : a.id < b.id ? -1 : 1))
    return { ...c, reconciled: c.points === sum(es), unplaced_points: sum(es.filter((e) => e.week == null)),
      entries: es.map(({ row_id, ...e }) => e),
      cells: weeks.map((w) => {
        const exact = es.filter((e) => e.week === w.week), through = es.filter((e) => e.week != null && e.week <= w.week), future = w.week > thisWeek
        return { week: w.week, points: future || !exact.length ? null : sum(exact), cumulative: future || !through.length ? null : sum(through), future }
      }) }
  }).sort((a, b) => (a.kind < b.kind ? -1 : a.kind > b.kind ? 1 : 0) || b.points - a.points || String(a.name).localeCompare(String(b.name)) || (a.id < b.id ? -1 : 1))
  const league = leagueById(W, leagueId)
  return { version: VERSION, league_id: leagueId, season_id: se.id, name: league ? league.name : null, number: se.number, status: se.status, starts_on: se.starts_on, ends_on: se.ends_on,
    timezone: tz(se), generated_at: tsz(W.now), current_week: thisWeek, structure: ls.structure, field_size: members.length, counting_cap: ls.counting_cap ?? null,
    participation_floor: ls.participation_floor ?? null,
    /* W7-120 · a finished season in this world closed after D383, so it is
       booked: its lines are frozen at the close (20261130090000:247-250,
       applied in prod, envelope version 1 per 20261205090000) */
    rules_note: se.status === 'complete' ? 'These are the lines the season closed with. Later rule changes, posts and deletions do not move them.' : null,
    frozen: se.status === 'complete',
    coverage_complete: rows.every((r) => r.reconciled), weeks, rows }
}

/* ============================================================ EVENTS */
const eventById = (W, id) => T_(W, 'events').find((e) => e.id === id) || null
const eventPlayer = (W, id) => T_(W, 'event_players').find((p) => p.id === id) || null
/* the best eligible PvI in [from, to] at the event's allowance (unrounded, as the SQL) */
function bestIn(W, profileId, from, to, allowance, { eighteenOnly = false } = {}) {
  const rs = T_(W, 'rounds').filter((r) => r.profile_id === profileId && r.played_on >= from && r.played_on <= to && !r.voided && (r.source || 'app') !== 'sim'
    && r.index_at_post != null && r.differential != null && (!eighteenOnly || r.holes_played === 18))
    .map((r) => ({ r, pvi: (r.index_at_post * allowance) / 100 - r.differential }))
    .sort((a, b) => b.pvi - a.pvi || (a.r.created_at < b.r.created_at ? -1 : 1))
  return { best: rs[0] || null, cards: rs.length }
}
export function majorLeaderboard(W, eventId) {
  const e = eventById(W, eventId); if (!e) return []
  const s = T_(W, 'event_sessions').find((x) => x.event_id === e.id && x.session_no === 1); if (!s) return []
  return T_(W, 'event_players').filter((p) => p.event_id === e.id).map((p) => {
    const pr = profileById(W, p.profile_id) || {}
    const { best, cards } = bestIn(W, p.profile_id, s.opens_on, s.closes_on, e.allowance ?? 100, { eighteenOnly: true })
    return { player_id: p.id, profile_id: p.profile_id, display_name: pr.display_name, marker: pr.marker, exhibition: !!p.exhibition,
      round_id: best ? best.r.id : null, gross: best ? best.r.gross : null, pvi: best ? r1(best.pvi) : null, cards: best ? cards : 0, best_posted_at: best ? tsz(best.r.created_at) : null }
  }).sort((a, b) => (a.pvi == null ? 1 : b.pvi == null ? -1 : b.pvi - a.pvi) || String(a.display_name).localeCompare(String(b.display_name)))
}
export function eventSessionTargets(W, sessionId) {
  const s = T_(W, 'event_sessions').find((x) => x.id === sessionId); if (!s || s.status !== 'open') return []
  const e = eventById(W, s.event_id); if (!e) return []
  /* numeric in SQL: exact; rounded here only to shed binary-float noise */
  const side = (pid) => { const p = eventPlayer(W, pid); const b = p && bestIn(W, p.profile_id, s.opens_on, s.closes_on, e.allowance ?? 100).best; return b ? Math.round(b.pvi * 1e4) / 1e4 : null }
  return T_(W, 'event_duels').filter((d) => d.session_id === s.id).map((d) => ({ duel_id: d.id, a_pvi: side(d.a_player), b_pvi: side(d.b_player) }))
}
export function eventLineage(W, eventId) {
  const e = eventById(W, eventId); if (!e) return []
  let root = e; const seen = new Set()
  while (root.lineage_id && !seen.has(root.id)) { seen.add(root.id); root = eventById(W, root.lineage_id) || root; if (!root.lineage_id) break }
  return T_(W, 'events').filter((x) => x.id === root.id || x.lineage_id === root.id)
    .sort((a, b) => (a.starts_on < b.starts_on ? -1 : a.starts_on > b.starts_on ? 1 : (a.created_at < b.created_at ? -1 : 1)))
    .map((x) => {
      const card = x.kind === 'major' ? T_(W, 'event_major_cards').find((c) => c.event_id === x.id && c.rank === 1) : null
      const cp = card && eventPlayer(W, card.player_id)
      const wt = x.winner_team_id ? T_(W, 'event_teams').find((t) => t.id === x.winner_team_id) : null
      return { event_id: x.id, name: x.name, kind: x.kind, status: x.status, starts_on: x.starts_on, year: Number(x.starts_on.slice(0, 4)), is_current: x.id === eventId,
        champion: cp ? (profileById(W, cp.profile_id) || {}).display_name : null, champ_gross: card ? card.gross : null, champ_pvi: card ? card.pvi : null,
        winner_slot: wt ? wt.slot : null, winner_team: wt ? wt.name : null, winner_shared: x.kind !== 'major' && x.status === 'complete' && !x.winner_team_id }
    })
}

/* ============================================================ LEAGUE CANCEL */
export function leagueCancelStatus(W, leagueId) {
  const req = T_(W, 'league_cancellations').find((c) => c.league_id === leagueId)
  if (!req) return null
  const mid = myMemberId(W, leagueId)
  const votes = T_(W, 'cancellation_votes').filter((v) => v.league_id === leagueId)
  const seasons = T_(W, 'seasons').filter((s) => s.league_id === leagueId).map((s) => s.id)
  return { open: true, members: T_(W, 'league_members').filter((m) => m.league_id === leagueId).length, approved: votes.length,
    you_approved: votes.some((v) => v.member_id === mid),
    you_refund_cents: T_(W, 'buy_ins').filter((b) => seasons.includes(b.season_id) && b.member_id === mid && b.paid).reduce((s, b) => s + (b.amount_cents || 0), 0),
    is_pro: (memberById(W, mid) || {}).role === 'commissioner', requested_by_me: req.requested_by === W.me }
}

/* ============================================================ HOME FACTS */
/* native_home's `memberships[]` (20261019090000 + D381's points_rank/tied), the
   part of home_dispatch's `me` Compete reads for the Scoreboard. Built from the
   same world the season page reads, so the band and the table agree. */
export function homeMemberships(W) {
  return T_(W, 'league_members').filter((m) => m.profile_id === W.me).map((m) => {
    const L = leagueById(W, m.league_id) || {}
    const ls = settingsOf(W, m.league_id)
    const solo = ls.structure === 'solo'
    const se = T_(W, 'seasons').filter((s) => s.league_id === m.league_id)
      .sort((a, b) => (Number(['active', 'cup_final'].includes(b.status)) - Number(['active', 'cup_final'].includes(a.status))) || (a.starts_on < b.starts_on ? 1 : -1))[0] || null
    const all = T_(W, 'league_members').filter((x) => x.league_id === m.league_id)
    const pro = all.find((x) => x.role === 'commissioner')
    const proName = pro ? (profileById(W, pro.profile_id) || {}).display_name : null
    let season = null, squad = null, standing = null
    if (se) {
      season = { id: se.id, number: se.number, starts_on: se.starts_on, ends_on: se.ends_on, status: se.status, timezone: tz(se), grace_hours: 48,
        champion_squad_id: se.champion_squad_id ?? null, champion_member_id: se.champion_member_id ?? null, points_king_member_id: se.points_king_member_id ?? null, tiebreak_rung: se.tiebreak_rung ?? null,
        week_no: weekNo(se, W.today), weeks_total: weeksTotal(se), week_ends_on: addDays(se.starts_on, Math.floor(Math.max(0, diffDays(W.today, se.starts_on)) / 7) * 7 + 6),
        days_to_first_tee: se.starts_on > W.today ? diffDays(se.starts_on, W.today) : null, days_left: Math.max(0, diffDays(se.ends_on, W.today)),
        final_opens_on: (ls.finish || 'cup_final') === 'cup_final' ? addDays(se.ends_on, -27) : null }
      const q = solo ? null : squadsOf(W, se.id).find((x) => squadMembers(W, x.id).includes(m.id))
      if (q) squad = { id: q.id, name: q.name, color: q.color }
      const table = solo
        ? T_(W, 'v_individual_standings').filter((v) => v.season_id === se.id).map((v) => ({ id: v.member_id, name: memberName(W, v.member_id), speak: firstname(memberName(W, v.member_id)), points: v.points || 0 }))
        : squadsOf(W, se.id).map((x) => ({ id: x.id, name: x.name, speak: x.name, points: (T_(W, 'v_squad_standings').find((s) => s.squad_id === x.id && s.season_id === se.id) || {}).points || 0 }))
      table.sort((a, b) => b.points - a.points || String(a.name).localeCompare(String(b.name)))
      const mineId = solo ? m.id : (q && q.id)
      const i = table.findIndex((x) => x.id === mineId)
      if (i >= 0) {
        const me = table[i], ld = table[0]
        const rank = 1 + table.filter((x) => x.points > me.points).length
        const snap = T_(W, 'standings_snapshots').filter((s) => s.season_id === se.id).sort((a, b) => b.week_no - a.week_no)[0]
        let prev = null
        if (snap) { const arr = ((snap.standings || {})[solo ? 'individuals' : 'squads'] || []).slice().sort((a, b) => b.points - a.points); const k = arr.findIndex((x) => (x.squad_id || x.member_id) === mineId); if (k >= 0) prev = 1 + arr.filter((x) => x.points > arr[k].points).length }
        standing = { rank, of: table.length, points: me.points, leader_squad_id: solo ? null : ld.id, leader_member_id: solo ? ld.id : null, leader_points: ld.points,
          gap_to_leader: ld.points - me.points, gap_to_next: i > 0 ? table[i - 1].points - me.points : null, leader_name: ld.speak,
          runner_up_name: table[1] ? table[1].speak : null, runner_up_points: table[1] ? table[1].points : null,
          next_up: i > 0 ? { name: table[i - 1].speak, points: table[i - 1].points } : null, next_down: table[i + 1] ? { name: table[i + 1].speak, points: table[i + 1].points } : null,
          points_rank: rank, points_tied: table.filter((x) => x.points === me.points).length > 1, prev_rank: prev }
        if (se.status === 'cup_final') {
          const fins = T_(W, 'cup_finalists').filter((c) => c.season_id === se.id).sort((a, b) => a.seed - b.seed)
          standing.seed = (fins.find((c) => (c.squad_id || c.member_id) === mineId) || {}).seed ?? null
          standing.finalists = fins.map((c) => (c.squad_id ? (T_(W, 'squads').find((x) => x.id === c.squad_id) || {}).name : firstname(memberName(W, c.member_id))))
        }
      }
    }
    return { league_id: m.league_id, member_id: m.id, code: L.code, name: L.name, role: m.role, phase: L.phase, sandbox: !!L.sandbox, marker: m.marker || null,
      members: all.length, roster: all.length, pro_name: proName ? firstname(proName) : null, commissioner_name: proName,
      settings: { finish: ls.finish, preset: ls.preset, locked_at: ls.locked_at, structure: ls.structure, buyin_cents: ls.buyin_cents, payout_king: ls.payout_king,
        counting_cap: ls.counting_cap ?? null, payout_champ: ls.payout_champ, floor_penalty: ls.floor_penalty, payout_runnerup: ls.payout_runnerup,
        handicap_allowance: ls.handicap_allowance, participation_floor: ls.participation_floor },
      season, squad, standing, clash: null, pulse: null, buy_in: null, last_season: null }
  })
}
/* the home_dispatch Compete needs: keep whatever `me` and items another
   module answers with; supply `me.memberships` only where it has none */
export function withHomeMemberships(W, override = null) {
  const prev = W.handlers.home_dispatch
  W.handlers.home_dispatch = async (args, W2) => {
    const base = prev ? await prev(args, W2) : null
    const out = base && typeof base === 'object' ? { ...base } : { items: [], lead_suppress: [], generated_at: tsz(W.now) }
    const me = out.me && typeof out.me === 'object' ? { ...out.me } : { profile: null, events: [], invites: [], flags: {}, live_round: null, open_duels: [], upcoming_rounds: [] }
    if (override) me.memberships = override(W2)
    else if (!Array.isArray(me.memberships) || !me.memberships.length) me.memberships = homeMemberships(W2)
    out.me = me
    if (!Array.isArray(out.items)) out.items = []
    return out
  }
}

/* ============================================ D381 · THE STANDING'S OWN RANK */
/* 20261118090000 patches native_home in place so every membership's standing
   carries `points_rank` (rank() over points, ties share it) and `points_tied`.
   Compete's Scoreboard reads exactly those two (index.html csSeasonRowFacts);
   the home_dispatch producer in rpc/10 predates the patch and answers without
   them, so the band lost its "2nd · Tied of 4" line. Added here from the same
   standings views the table reads -- only where a standing lacks them, and only
   for a season this world holds (a Home-state payload is left as it came). */
export function standingRanks(W, m) {
  const st = m && m.standing
  if (!st || st.points_rank !== undefined || !m.season || !m.season.id) return
  const se = seasonById(W, m.season.id); if (!se) return
  const solo = (settingsOf(W, se.league_id).structure || 'squads2') === 'solo'
  const key = solo ? m.member_id : (m.squad && m.squad.id)
  const table = solo
    ? T_(W, 'v_individual_standings').filter((v) => v.season_id === se.id).map((v) => ({ id: v.member_id, points: Number(v.points || 0) }))
    : T_(W, 'v_squad_standings').filter((v) => v.season_id === se.id).map((v) => ({ id: v.squad_id, points: Number(v.points || 0) }))
  const mine = table.find((x) => x.id === key); if (!mine) return
  st.points_rank = 1 + table.filter((x) => x.points > mine.points).length
  st.points_tied = table.filter((x) => x.points === mine.points).length > 1
}

/* ============================================================ INSTALL */
export default function install(W) {
  rebuildSnapshots(W)
  /* read by enterLeague for a complete season, and by the scenario/race
     producers; the core world has neither table */
  W.tables.season_payouts ||= []
  W.tables.cup_finalists ||= []
  const prevDispatch = W.handlers.home_dispatch
  const H = {
    season_story: (a, W2) => seasonStory(W2, a),
    season_scenarios: (a, W2) => seasonScenarios(W2, a.p_season),
    cup_final_race: (a, W2) => cupFinalRace(W2, a.p_season),
    season_book: (a, W2) => seasonBook(W2, a.p_league_id, a.p_season_id),
    league_cancel_status: (a, W2) => leagueCancelStatus(W2, a.p_league),
    major_leaderboard: (a, W2) => majorLeaderboard(W2, a.p_event),
    event_session_targets: (a, W2) => eventSessionTargets(W2, a.p_session),
    event_lineage: (a, W2) => eventLineage(W2, a.p_event),
  }
  /* requested on every signed-in boot; owned by the round/board fixtures. An
     honest empty (no thread counts, no course circle) only where no other
     module answers it. */
  if (!W.handlers.posted_rounds_social) H.posted_rounds_social = () => ({ items: [] })
  if (prevDispatch) H.home_dispatch = async (a, W2) => {
    const out = await prevDispatch(a, W2)
    const ms = out && out.me && Array.isArray(out.me.memberships) ? out.me.memberships : null
    if (ms) ms.forEach((m) => standingRanks(W2, m))
    return out
  }
  return H
}

/* ================================================= WORLD TRANSFORMS (prepare) */
export const ids = {
  event: (n) => `f8000000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  team: (n) => `f8100000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  eplayer: (n) => `f8200000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  session: (n) => `f8300000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  duel: (n) => `f8400000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  card: (n) => `f8500000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  post: (n) => `f7000000-0000-4000-8000-${String(n).padStart(12, '0')}`,
  person: (n) => `f1000000-0000-4000-8000-${String(9000 + n).padStart(12, '0')}`,
}

/* ------------------------------------------------------------------ the Book */
/* The four synthetic envelopes (tests/fixtures/ten/book-*.synthetic.json, the
   renamed copies of the D381 fixtures). A Book state ADOPTS one: the world
   gains that league, season, roster, squads, ledger and standings under the
   envelope's own ids, so the page behind the dialog, Compete's Scoreboard and
   the Book itself read one set of facts. The files are read, never written. */
export const BOOKS = ['upcoming', 'squads', 'tie', 'finished']
export function readBook(name) {
  const b = JSON.parse(readFileSync(join(TEN, `book-${name}.synthetic.json`), 'utf8'))
  delete b._ten
  return b
}
/* The same envelope as season_book would answer it on `today`: the
   20261118090000 this_week rule (the dates alone -- never the status) and every
   cell re-derived from the row's entries by the rule SeasonBook.validate
   checks. No entry is added, moved or dropped: a Book read on the capture
   clock (Monday of week 13, before anyone has played it) of the season the
   envelope recorded on its generation day (week 12). */
export function bookAt(b, today, generatedAt = null) {
  const out = JSON.parse(JSON.stringify(b))
  const tw = today < out.starts_on ? 0 : Math.min(out.weeks.length, Math.floor(diffDays(today, out.starts_on) / 7) + 1)
  const sum = (xs) => xs.reduce((s, e) => s + e.contribution, 0)
  out.current_week = tw
  if (generatedAt) out.generated_at = generatedAt
  for (const r of out.rows) r.cells = out.weeks.map((w) => {
    const exact = r.entries.filter((e) => e.week === w.week), through = r.entries.filter((e) => e.week != null && e.week <= w.week), future = w.week > tw
    return { week: w.week, future, points: future || !exact.length ? null : sum(exact), cumulative: future || !through.length ? null : sum(through) }
  })
  return out
}
const MARKER_POOL = ['saguaro', 'lighthouse', 'lonetree', 'island', 'dunes', 'shark', 'pews', 'jug', 'thistle', 'beer', 'no2']
const slug = (s) => String(s).toLowerCase().replace(/[^a-z]+/g, '.').replace(/^\.+|\.+$/g, '')
/* a cast golfer keeps their own profile; a name from cast.TEN_NAME_POOL (the
   legacy fixture's renamed people) gets one synthetic profile, once */
function profileFor(W, name) {
  const cast = W.cast.PEOPLE.find((p) => p.name === name)
  if (cast) return profileById(W, W.ids.uid(cast.n))
  const had = T_(W, 'profiles').find((x) => x.display_name === name)
  if (had) return had
  const n = (W._bookPeople = (W._bookPeople || 0) + 1)
  const p = { id: ids.person(n), display_name: name, city: null, home_course: null, index_current: r1(6 + ((n * 37) % 190) / 10), index_source: 'auto',
    marker: MARKER_POOL[n % MARKER_POOL.length], notify_chat: true, notify_rounds: true, handle: slug(name), discoverable: 'everyone', ghin_number: null,
    created_at: '2026-06-01T19:00:00Z', photo_path: null, scan_consent_at: null, email: `${slug(name)}@example.invalid` }
  T_(W, 'profiles').push(p)
  return p
}
/* the band table (tests/fixtures/bands.json) read backwards: a PvI inside each
   points band, stepped down a hundredth per place so the month order the
   envelope's count_state implies (counting first, best first) is the order
   the cap applies. The envelope carries points, not PvI; nothing on a Book
   surface prints this figure. */
const BAND_PVI = { 12: 3.6, 9: 1.8, 7: 0.2, 6: -1.8, 5: -3.8 }
const r2 = (x) => Math.round(x * 100) / 100
export function adoptBook(W, b, { status = null, finish = 'points_table' } = {}) {
  const T = W.tables, uid = W.ids.uid
  const L = b.league_id, S = b.season_id, st = status || b.status
  const home = JSON.parse(readFileSync(join(TEN, 'book-home.synthetic.json'), 'utf8'))
  const hm = (home.memberships || []).find((m) => m.league_id === L) || {}
  const hs = hm.settings || {}
  const golfers = b.rows.filter((r) => r.kind === 'golfer'), squads = b.rows.filter((r) => r.kind === 'squad'), contribs = b.rows.filter((r) => r.kind === 'contribution')
  if (!golfers.some((r) => r.mine && r.name === (profileById(W, W.me) || {}).display_name)) throw new Error(`adoptBook: ${b.name} does not seat the viewer`)
  const pro = uid(2)   /* book-home: every Book league is run by Blake Sample */
  T.leagues.push({ id: L, name: b.name, code: hm.code || null, phase: st === 'complete' ? 'complete' : 'season', sandbox: false, created_by: pro, created_at: `${addDays(b.starts_on, -21)}T18:00:00Z` })
  T.league_settings.push({ league_id: L, preset: hs.preset || 'standard', handicap_allowance: hs.handicap_allowance ?? 100, verification: 'attested',
    counting_cap: b.counting_cap, participation_floor: b.participation_floor, floor_penalty: hs.floor_penalty || 'deduct', season_format: 'points',
    buyin_cents: hs.buyin_cents ?? 0, season_months: Math.max(1, Math.round(b.weeks.length / 4.3)), sim_rounds_allowed: true, nine_hole_allowed: true,
    /* book-home carries locked_at null for a league in play; a season has a lock */
    locked_at: `${addDays(b.starts_on, -7)}T18:00:00Z`, structure: b.structure, draft_type: 'random',
    payout_champ: hs.payout_champ ?? 60, payout_runnerup: hs.payout_runnerup ?? 25, payout_king: hs.payout_king ?? 15, finish })
  T.seasons.push({ id: S, league_id: L, number: b.number, starts_on: b.starts_on, ends_on: b.ends_on, status: st, champion_squad_id: null, champion_member_id: null,
    runnerup_squad_id: null, runnerup_member_id: null, points_king_member_id: null, champion_score: null, runnerup_score: null, tiebreak_rung: null, pot_cents: 0, collected_cents: 0 })
  for (const r of golfers) {
    const p = profileFor(W, r.name)
    T.league_members.push({ id: r.member_id, league_id: L, profile_id: p.id, role: p.id === pro ? 'commissioner' : 'player', index_current: p.index_current,
      joined_at: `${addDays(b.starts_on, -14)}T18:00:00Z`, marker: null, suspended_at: null, agreed_seasons: [b.number] })
  }
  /* squads: colours in id order (book-home paints mine, the …300 squad, 0);
     the envelope names no captain, so the top contributor carries the armband */
  squads.slice().sort((a, c) => (a.squad_id < c.squad_id ? -1 : 1)).forEach((q, i) => {
    const mem = contribs.filter((c) => c.squad_id === q.squad_id)
    const cap = mem.slice().sort((a, c) => c.points - a.points || String(a.name).localeCompare(String(c.name)))[0]
    T.squads.push({ id: q.squad_id, season_id: S, league_id: L, name: q.name, color: i % 4, captain_member_id: cap ? cap.member_id : null })
    for (const c of mem) T.squad_members.push({ squad_id: q.squad_id, member_id: c.member_id })
  })
  for (const r of golfers) T.v_individual_standings.push({ season_id: S, league_id: L, member_id: r.member_id, profile_id: memberById(W, r.member_id).profile_id,
    points: r.points, rounds_posted: r.entries.filter((e) => e.round_id).length })
  for (const q of squads) T.v_squad_standings.push({ season_id: S, squad_id: q.squad_id, points: q.points })
  /* the ledger, once per adjustment id; a squad row carries the raw reason,
     a golfer row appends the individual-total clause the Book adds */
  const seen = new Set()
  for (const r of [...squads, ...golfers]) for (const e of r.entries) {
    if (e.round_id || seen.has(e.id)) continue
    seen.add(e.id)
    T.season_adjustments.push({ id: e.id.replace(/^adjustment:/, ''), season_id: S, squad_id: e.squad_id, member_id: e.member_id, month: e.affected_month,
      kind: e.kind, points: e.points, reason: String(e.reason || '').replace(/ Does not change the individual points total\.$/, ''),
      created_by: null, created_at: `${e.recorded_on || b.starts_on}T19:00:00Z` })
  }
  /* every round the envelope counts or drops, as v_rounds_ranked holds it */
  for (const r of golfers) {
    const m = memberById(W, r.member_id)
    const byMonth = {}
    for (const e of r.entries.filter((x) => x.round_id)) (byMonth[e.affected_month || monthStart(e.recorded_on)] ||= []).push(e)
    for (const list of Object.values(byMonth)) {
      list.sort((a, c) => (a.count_state === 'counting' ? 0 : 1) - (c.count_state === 'counting' ? 0 : 1) || c.points - a.points || (a.recorded_on < c.recorded_on ? -1 : a.recorded_on > c.recorded_on ? 1 : 0))
      const counting = list.filter((e) => e.count_state === 'counting').length
      if (b.counting_cap != null && counting !== Math.min(b.counting_cap, list.length)) throw new Error(`adoptBook: ${r.name} ${list[0].affected_month} counts ${counting} of ${list.length}`)
      list.forEach((e, i) => {
        if (BAND_PVI[e.points] == null) throw new Error(`adoptBook: no band holds ${e.points} points`)
        const pvi = r2(BAND_PVI[e.points] - 0.01 * i)
        T.v_rounds_ranked.push({ round_id: e.round_id, season_id: S, league_id: L, member_id: r.member_id, profile_id: m.profile_id, pvi, points: e.points,
          band: W.cast.bandOf(pvi), month_rank: i + 1, floor_credit: 1, played_on: e.recorded_on, index_at_post: m.index_current, holes_played: 18, gross: null, course_label: null })
      })
    }
  }
  rebuildSnapshots(W, [S])
  /* a complete season was crowned when it was recorded complete: the envelope's own generation time */
  if (st === 'complete') crownSeason(W, S, tsz(b.generated_at))
  /* W7-121 · a complete season's Book is read as season_book answers once
     close_season has run: on the day after its ends_on, so current_week is the
     last and no cell is "Future week" (production cannot draw one) */
  W.book = bookAt(b, st === 'complete' ? addDays(b.ends_on, 1) : W.today, tsz(W.now))
  W.book.status = st
  W.notes.push(`book: adopted ${b.name} (${L}) at week ${W.book.current_week}, status ${st}`)
  return { league: L, season: S, book: W.book }
}

/* ------------------------------------------------------------ the crown */
/* close_season's crown for a season that ends on the points table
   (20261012090000): the table's own points, then months won, best single
   month, fewest rounds used -- each over the counting rounds -- and the rung
   that separated a level top two; the Points King on the same ladder over
   every member. The last rung is random() in SQL; here the coin lands for the
   lower id, every run, and the rung is recorded as the coin flip it was. The
   board is told in that function's own sentence, stamped `at` (the moment
   the season was recorded complete). */
export function crownSeason(W, seasonId, at) {
  const se = seasonById(W, seasonId); if (!se) throw new Error('crownSeason: no season ' + seasonId)
  const ls = settingsOf(W, se.league_id)
  if ((ls.finish || 'cup_final') === 'cup_final') throw new Error('crownSeason: a Cup Final crowns from its window; not modelled')
  const solo = ls.structure === 'solo', cap = ls.counting_cap == null ? 10000 : Number(ls.counting_cap)
  const rr = T_(W, 'v_rounds_ranked').filter((r) => r.season_id === se.id && r.month_rank <= cap)
  const squadOf = (mid) => (squadsOf(W, se.id).find((q) => squadMembers(W, q.id).includes(mid)) || {}).id || null
  const ladderOf = (cids, cidOf, scoreOf) => {
    const months = {}
    for (const r of rr) { const c = cidOf(r.member_id); if (!c) continue; const k = c + '|' + monthOf(r.played_on); months[k] = (months[k] || 0) + r.points }
    const byMon = {}
    for (const [k, v] of Object.entries(months)) { const [c, mon] = k.split('|'); (byMon[mon] ||= []).push({ c, v }) }
    return cids.map((c) => {
      const mine = Object.entries(months).filter(([k]) => k.startsWith(c + '|'))
      const won = mine.filter(([k, v]) => { const mon = k.split('|')[1]; return v > Math.max(-1, ...byMon[mon].filter((x) => x.c !== c).map((x) => x.v)) }).length
      return { c, score: scoreOf(c), won, best: mine.length ? Math.max(...mine.map(([, v]) => v)) : 0, used: rr.filter((r) => cidOf(r.member_id) === c).length }
    }).sort((a, b) => b.score - a.score || b.won - a.won || b.best - a.best || a.used - b.used || (a.c < b.c ? -1 : 1))
  }
  const rungOf = (a, b) => (!b || a.score !== b.score ? null : a.won !== b.won ? 'months won' : a.best !== b.best ? 'best single month' : a.used !== b.used ? 'fewest rounds used' : 'coin flip')
  const memberIds = T_(W, 'league_members').filter((m) => m.league_id === se.league_id).map((m) => m.id)
  const indPts = (c) => Number((T_(W, 'v_individual_standings').find((i) => i.season_id === se.id && i.member_id === c) || {}).points || 0)
  const ranked = solo ? ladderOf(memberIds, (m) => m, indPts)
    : ladderOf(squadsOf(W, se.id).map((q) => q.id), squadOf, (c) => Number((T_(W, 'v_squad_standings').find((s) => s.season_id === se.id && s.squad_id === c) || {}).points || 0))
  const king = ladderOf(memberIds, (m) => m, indPts)
  const [c1, c2] = ranked, [k1, k2] = king
  const rung = rungOf(c1, c2), kingRung = rungOf(k1, k2)
  Object.assign(se, { status: 'complete', champion_squad_id: solo ? null : c1.c, champion_member_id: solo ? c1.c : null, runnerup_squad_id: solo ? null : (c2 || {}).c || null,
    runnerup_member_id: solo ? (c2 || {}).c || null : null, points_king_member_id: k1.c, champion_score: c1.score, runnerup_score: c2 ? c2.score : null, tiebreak_rung: rung, king_rung: kingRung })
  const L = leagueById(W, se.league_id); if (L) L.phase = 'complete'
  const nm = (c) => (solo ? memberName(W, c) : (T_(W, 'squads').find((q) => q.id === c) || {}).name) || 'The champion'
  const say = (r) => (r === 'months won' ? 'months won this season' : r)
  const body = 'Season complete: ' + nm(c1.c) + (solo ? ' takes' : ' take') + ' the Cup' + (c2 ? ` ${c1.score}–${c2.score}` : '')
    + (rung ? '. Tiebreak: ' + say(rung) : '') + (memberName(W, k1.c) ? '. Points King: ' + memberName(W, k1.c) + (kingRung ? ` (tiebreak: ${say(kingRung)})` : '') : '') + '.'
  T_(W, 'posts').push({ id: ids.post(951), league_id: se.league_id, season_id: se.id, profile_id: null, kind: 'system', member_id: null, body, created_at: at,
    round_id: null, live_round_id: null, scheduled_round_id: null })
  W.notes.push('crown: ' + body)
  return { champion: c1, runner_up: c2 || null, king: k1, rung, king_rung: kingRung, body }
}

/* ------------------------------------------------------------ the Cup Final */
/* the daily tick's seed lock (20260828170100 enter_cup_final) as it ran on
   ends_on − 27: the table as of that morning, the top two seeded (a squads2
   top seed carries a 10-point head start), the season flipped to cup_final
   and the board told, in 20260930093000's words. A tie on the seed line would
   need the §14.3 ladder, which this world does not model -- it refuses. */
export function cupFinalOn(W, seasonId) {
  const se = seasonById(W, seasonId); if (!se) throw new Error('cupFinalOn: no season ' + seasonId)
  const ls = settingsOf(W, se.league_id)
  const solo = ls.structure === 'solo'
  const lock = addDays(se.ends_on, -27)
  if (W.today < lock) throw new Error(`cupFinalOn: the window opens ${lock}, after the capture clock`)
  ls.finish = 'cup_final'
  se.status = 'cup_final'
  const asOf = standingsAsOf(W, se, lock)
  const rows = (solo ? asOf.individuals : asOf.squads).slice().sort((a, b) => b.points - a.points)
  if (rows.length > 2 && (rows[0].points === rows[1].points || rows[1].points === rows[2].points)) throw new Error('cupFinalOn: the seed line is tied')
  W.tables.cup_finalists = T_(W, 'cup_finalists').filter((c) => c.season_id !== se.id).concat(rows.slice(0, 2).map((r, i) => ({
    season_id: se.id, squad_id: solo ? null : r.squad_id, member_id: solo ? r.member_id : null, seed: i + 1,
    head_start: !solo && ls.structure === 'squads2' && i === 0 ? 10 : 0, seed_rung: null })))
  T_(W, 'posts').push({ id: ids.post(950), league_id: se.league_id, season_id: se.id, profile_id: null, kind: 'system', member_id: null,
    body: 'The Cup Final is live. Four weeks, scored fresh, and the Final is set.', created_at: `${lock}T07:15:00+00:00`, round_id: null, live_round_id: null, scheduled_round_id: null })
  if (W.book && W.book.season_id === se.id) W.book.status = 'cup_final'
  W.notes.push(`cup final: ${se.id} seeded ${rows.slice(0, 2).map((r) => r.squad_id || r.member_id).join(', ')} as of ${lock}`)
  return W.tables.cup_finalists.filter((c) => c.season_id === se.id)
}

/* ---------------------------------------------------------------- the Ryder */
/* Two editions of one Ryder attached to North Grove, organised by its Pro:
   the first is complete, the second -- its rematch (lineage_id) -- is live in
   its third week. Pairings rotate the same eight golfers; every closed week is
   resolved by resolve_session's own rule (20261012090000: the best PvI in the
   window at the event allowance, a missing card loses, two missing halve),
   the cup is decided by its clinch/points rule, and every board line is the
   sentence that function writes. D398 (Q44 A, 20261215090000): a closed
   week's "is up" ask is gone -- its result replaced it -- so only the open
   week keeps one, stamped a moment after the result the same tick wrote
   (event_post's clock_timestamp); and the cup post says the cup without the
   score the last week's result already printed. The open week's chips are
   event_session_targets over the same rounds. */
const evhalf = (n) => (n - Math.floor(n) >= 0.5 ? Math.floor(n) + '½' : String(Math.floor(n)))
const r4 = (x) => (x == null ? null : Math.round(x * 1e4) / 1e4)
export function ryderWorld(W) {
  const T = W.tables, uid = W.ids.uid, league = W.ids.lid(1)
  const TEAMS = [{ slot: 0, name: 'Fixture Hawks', color: 2, roster: [8, 1, 4, 5] }, { slot: 1, name: 'Fixture Bobcats', color: 3, roster: [2, 3, 6, 7] }]
  const EDITIONS = [
    { n: 1, starts_on: '2026-08-13', lineage_id: null, created_at: '2026-08-06T18:00:00Z' },
    { n: 2, starts_on: '2026-09-10', lineage_id: ids.event(11), created_at: '2026-09-04T18:00:00Z' },
  ]
  const NAME = 'The North Grove Ryder (fixture)'
  const out = {}
  for (const ed of EDITIONS) {
    const E = ids.event(10 + ed.n)
    const ev = { id: E, name: NAME, created_by: uid(2), league_id: league, kind: 'ryder', status: 'live', starts_on: ed.starts_on, session_count: 3, session_weeks: 1,
      draw_rule: 'team_pvi', defender_team_id: null, allowance: 100, winner_team_id: null, created_at: ed.created_at, lineage_id: ed.lineage_id,
      buy_in: 0, pot_split: 'places', decided_by: null, tz: 'America/Phoenix', course_id: null, course_label: null }
    T.events.push(ev)
    const teams = TEAMS.map((t) => ({ id: ids.team(ed.n * 10 + t.slot), event_id: E, slot: t.slot, name: t.name, color: t.color, captain_player_id: ids.eplayer(ed.n * 100 + t.roster[0]) }))
    T.event_teams.push(...teams)
    const players = TEAMS.flatMap((t, ti) => t.roster.map((pn, i) => ({ id: ids.eplayer(ed.n * 100 + pn), event_id: E, profile_id: uid(pn), team_id: teams[ti].id,
      role: i === 0 ? 'captain' : 'player', seed: i + 1, benched_count: 0, created_at: ed.created_at, notify_target: false, exhibition: false })))
    T.event_players.push(...players)
    const side = (slot) => players.filter((p) => p.team_id === teams[slot].id)
    const nameOf = (p) => firstname((profileById(W, p.profile_id) || {}).display_name)
    const sessions = [], duels = [], posts = []
    let pa = 0, pb = 0, decided = false
    for (let k = 0; k < 3; k++) {
      const opens = addDays(ed.starts_on, 7 * k), closes = addDays(ed.starts_on, 7 * k + 6)
      const status = closes < W.today ? 'closed' : opens <= W.today ? 'open' : 'upcoming'
      const s = { id: ids.session(ed.n * 10 + k + 1), event_id: E, session_no: k + 1, opens_on: opens, closes_on: closes, status, weight: 1 }
      sessions.push(s)
      if (status === 'upcoming') continue
      /* D398: the result replaces the ask, so only a week still open keeps it */
      if (status !== 'closed') posts.push({ body: `Week ${k + 1} is up. 4 clashes — find yours.`, at: `${opens}T07:20:01+00:00` })
      const A = side(0), B = side(1)
      const ds = A.map((a, i) => ({ id: ids.duel(ed.n * 100 + (k + 1) * 10 + i + 1), event_id: E, session_id: s.id, a_player: a.id, b_player: B[(i + k) % 4].id,
        a_round: null, b_round: null, a_pvi: null, b_pvi: null, a_points: 0, b_points: 0, result: 'pending', resolved_at: null }))
      duels.push(...ds)
      if (status !== 'closed') continue
      const lines = []
      for (const d of ds) {
        const a = players.find((p) => p.id === d.a_player), b = players.find((p) => p.id === d.b_player)
        const ba = bestIn(W, a.profile_id, opens, closes, ev.allowance).best, bb = bestIn(W, b.profile_id, opens, closes, ev.allowance).best
        d.a_round = ba ? ba.r.id : null; d.b_round = bb ? bb.r.id : null
        d.a_pvi = ba ? r4(ba.pvi) : null; d.b_pvi = bb ? r4(bb.pvi) : null
        if (d.a_pvi == null && d.b_pvi == null) { d.result = 'halve'; d.a_points = 0.5; d.b_points = 0.5 }
        else if (d.b_pvi == null || (d.a_pvi != null && d.a_pvi > d.b_pvi)) { d.result = 'a'; d.a_points = 1 }
        else if (d.a_pvi == null || d.b_pvi > d.a_pvi) { d.result = 'b'; d.b_points = 1 }
        else { d.result = 'halve'; d.a_points = 0.5; d.b_points = 0.5 }
        d.resolved_at = `${addDays(closes, 1)}T07:20:00+00:00`
        const by = d.a_pvi != null && d.b_pvi != null ? ' by ' + Math.abs(d.a_pvi - d.b_pvi).toFixed(1) : ''
        lines.push(d.result === 'a' ? `${nameOf(a)} beat ${nameOf(b)}${by}` : d.result === 'b' ? `${nameOf(b)} beat ${nameOf(a)}${by}` : `${nameOf(a)} and ${nameOf(b)} halved`)
        pa += d.a_points; pb += d.b_points
      }
      const score = pa === pb ? `All square, ${evhalf(pa)}–${evhalf(pb)}` : pa > pb ? `${teams[0].name} lead ${evhalf(pa)}–${evhalf(pb)}` : `${teams[1].name} lead ${evhalf(pb)}–${evhalf(pa)}`
      posts.push({ body: `${score} after week ${k + 1}. ${lines.join(' · ')}.`, at: `${addDays(closes, 1)}T07:20:00+00:00` })
      /* the clinch / completion rule; a decided cup is never re-decided (D146) */
      const mTotal = 4 * ev.session_count
      const allClosed = k === 2
      if (!decided && (Math.max(pa, pb) > mTotal / 2 || (allClosed && pa !== pb))) {
        decided = true; ev.status = 'complete'; ev.winner_team_id = pa > pb ? teams[0].id : teams[1].id
      } else if (!decided && allClosed) {
        const tot = (slot) => duels.reduce((s2, d) => s2 + (slot === 0 ? (d.a_pvi || 0) : (d.b_pvi || 0)), 0)
        const sa = tot(0), sb = tot(1)
        decided = true; ev.status = 'complete'; ev.decided_by = sa === sb ? 'shared cup' : 'total PvI'; ev.winner_team_id = sa > sb ? teams[0].id : sb > sa ? teams[1].id : null
      }
      if (decided && !ev._posted) {
        ev._posted = true
        const rec = players.map((p) => {
          const mine = duels.filter((d) => d.result !== 'pending' && (d.a_player === p.id || d.b_player === p.id))
          const w = mine.filter((d) => (d.a_player === p.id && d.result === 'a') || (d.b_player === p.id && d.result === 'b')).length
          const l = mine.filter((d) => (d.a_player === p.id && d.result === 'b') || (d.b_player === p.id && d.result === 'a')).length
          const h = mine.filter((d) => d.result === 'halve').length
          return { p, w, l, h, tot: mine.reduce((s2, d) => s2 + ((d.a_player === p.id ? d.a_pvi : d.b_pvi) || 0), 0) }
        }).sort((x, y) => y.w - x.w || y.tot - x.tot)[0]
        /* D398: the week's result just above already says the score */
        const win = teams.find((t) => t.id === ev.winner_team_id)
        const head = !win ? `${teams[0].name} and ${teams[1].name} share ${NAME}.`
          : ev.decided_by ? `${win.name} take ${NAME} on ${ev.decided_by}.`
          : `${win.name} take ${NAME}.`
        posts.push({ body: `${head}${rec ? ` ${nameOf(rec.p)} is MVP at ${rec.w}-${rec.l}-${rec.h}.` : ''}`, at: `${addDays(closes, 1)}T07:21:00+00:00` })
      }
    }
    delete ev._posted
    T.event_sessions.push(...sessions)
    T.event_duels.push(...duels)
    posts.forEach((p, i) => T_(W, 'posts').push({ id: ids.post(960 + ed.n * 10 + i), league_id: null, event_id: E, profile_id: null, kind: 'system', member_id: null,
      body: p.body, created_at: p.at, round_id: null, live_round_id: null, scheduled_round_id: null }))
    out[ed.n] = ev
  }
  /* v_event_scoreboard, as the view sums it: each duel's points to its side's team */
  W.tables.v_event_scoreboard = []
  for (const ev of T.events) {
    const pts = {}
    for (const d of T.event_duels.filter((x) => x.event_id === ev.id)) {
      const a = eventPlayer(W, d.a_player), b = eventPlayer(W, d.b_player)
      if (a && a.team_id) pts[a.team_id] = (pts[a.team_id] || 0) + d.a_points
      if (b && b.team_id) pts[b.team_id] = (pts[b.team_id] || 0) + d.b_points
    }
    for (const [team_id, points] of Object.entries(pts)) W.tables.v_event_scoreboard.push({ event_id: ev.id, team_id, points })
  }
  return { first: out[1], rematch: out[2] }
}
