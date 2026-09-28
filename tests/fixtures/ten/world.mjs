/* Cup Season · the ten-capture SYNTHETIC WORLD (WX lane, 2026-09-28).
 *
 * A small in-memory database built from cast.mjs, answering the web client's
 * reads the way PostgREST and the RPCs would: base tables with every column
 * the client selects, the scoring views derived from the rounds with the band
 * table's own arithmetic, embedded resources resolved from a relation map, and
 * one handler per RPC (tests/fixtures/ten/rpc/*.mjs). A request the world does
 * not answer returns GAP and the harness aborts it and writes it down.
 *
 * Variants (VARIANTS below) are the account states a capture needs: signed out,
 * no golfer card, brand new, one round, a populated league member, the Pro,
 * a Pro mid-setup, and failure modes. A variant is DATA, never a code path in
 * the product: the page under test runs its own boot against these answers. */
import { readdirSync } from 'node:fs'
import { dirname, join } from 'node:path'
import { fileURLToPath, pathToFileURL } from 'node:url'
import {
  CAPTURE_NOW, TODAY, PEOPLE, person, COURSES, LEAGUES, PARS18, SI18, uid, lid, mid, sid, qid, rid, pid, eid,
  addDays, r1, buildRounds, pviOf, pointsOf, bandOf,
} from './cast.mjs'

const HERE = dirname(fileURLToPath(import.meta.url))
export const GAP = Symbol.for('ten-fixture-gap')

export const VARIANTS = {
  signed_out:      { session: false },
  no_card:         { session: true, card: false },
  brand_new:       { session: true, card: true, rounds: 'none', leagues: [] },
  one_round:       { session: true, card: true, rounds: 'one', leagues: [] },
  rounds_no_league:{ session: true, card: true, rounds: 'all', leagues: [] },
  member:          { session: true, card: true, rounds: 'all', leagues: [1, 2], role: { 1: 'player', 2: 'commissioner' }, last: 1 },
  pro:             { session: true, card: true, rounds: 'all', leagues: [1], role: { 1: 'commissioner' }, last: 1 },
  pro_setup:       { session: true, card: true, rounds: 'all', leagues: [3], role: { 3: 'commissioner' }, last: 3 },
}

/* ------------------------------------------------------------ select parser */
function splitTop(s) {
  const out = []; let depth = 0, cur = ''
  for (const ch of s) {
    if (ch === '(') depth++
    if (ch === ')') depth--
    if (ch === ',' && depth === 0) { if (cur.trim()) out.push(cur.trim()); cur = ''; continue }
    cur += ch
  }
  if (cur.trim()) out.push(cur.trim())
  return out
}
export function parseSelect(sel) {
  return splitTop(String(sel || '*').replace(/\s+/g, ' ')).map((item) => {
    const m = /^(?:([a-zA-Z0-9_]+):)?([a-zA-Z0-9_]+)(?:!([a-zA-Z0-9_]+))?\s*\((.*)\)$/.exec(item)
    if (m) return { embed: true, alias: m[1] || m[2], target: m[2], hint: m[3] || null, inner: parseSelect(m[4]) }
    if (item === '*') return { star: true }
    const c = /^(?:([a-zA-Z0-9_]+):)?([a-zA-Z0-9_]+)(?:::[a-z0-9_]+)?$/.exec(item)
    if (c) return { col: c[2], alias: c[1] || c[2] }
    return { col: item, alias: item }
  })
}

/* relation map: `<from>.<target>` -> how to join. `one` follows a foreign key
   on the FROM row; `many` collects TARGET rows whose `ref` equals FROM.id. */
const REL = {
  'league_members.leagues': { one: 'league_id' },
  'league_members.profiles': { one: 'profile_id' },
  'leagues.seasons': { many: 'league_id' },
  'leagues.league_settings': { one: 'id', key: 'league_id' },
  'squads.squad_members': { many: 'squad_id' },
  'squad_members.league_members': { one: 'member_id' },
  'api_courses.api_course_tees': { many: 'course_id' },
  'api_course_tees.api_course_holes': { many: 'tee_id' },
  'event_players.events': { one: 'event_id' },
  'event_players.profiles': { one: 'profile_id' },
  'event_players.event_teams': { one: 'team_id' },
  'live_rounds.live_round_players': { many: 'live_round_id' },
  'live_round_players.league_members': { one: 'member_id' },
  'live_round_players.profiles': { one: 'guest_profile_id' },
  'post_comments.league_members': { one: 'member_id' },
  'post_kudos.league_members': { one: 'member_id' },
  'posts.league_members': { one: 'member_id' },
  'rounds.profiles': { one: 'profile_id' },
  'round_comments.profiles': { one: 'profile_id' },
  'events.event_teams': { many: 'event_id' },
  'events.event_players': { many: 'event_id' },
  'seasons.leagues': { one: 'league_id' },
}

export function makeWorld(variantName = 'member', overrides = {}) {
  const V = { ...(VARIANTS[variantName] || VARIANTS.member), ...overrides }
  const W = { variant: variantName, V, now: CAPTURE_NOW, today: TODAY, tables: {}, rpc: {}, flags: { ...(overrides.flags || {}) },
    errors: { auth: {}, rpc: {}, table: {}, write: {}, ...(overrides.errors || {}) }, notes: [] }
  const T = W.tables
  W.iso = (off = 0) => addDays(TODAY, off)
  W.at = (off = 0, hh = 9, mm = 0) => `${addDays(TODAY, off)}T${String(hh).padStart(2, '0')}:${String(mm).padStart(2, '0')}:00-07:00`
  W.me = uid(1)
  W.ids = { uid, lid, mid, sid, qid, rid, pid, eid }
  W.cast = { PEOPLE, person, COURSES, LEAGUES, PARS18, SI18, pviOf, pointsOf, bandOf, r1 }

  /* ---- profiles ---- */
  T.profiles = PEOPLE.map((p) => ({
    id: uid(p.n), display_name: p.name, city: p.city, home_course: p.n === 1 ? 'Saguaro Flats Municipal (fixture)' : null,
    index_current: p.index, index_source: p.n === 1 ? 'auto' : 'auto', marker: p.marker, notify_chat: true, notify_rounds: true,
    handle: p.handle, discoverable: true, ghin_number: null, created_at: '2026-03-01T19:00:00Z', photo_path: null,
    scan_consent_at: null, email: p.email,
  }))
  const me = T.profiles[0]
  if (V.card === false) { me.marker = null; me.handle = null; me.display_name = 'avery.fixture'; me.index_current = null; me.city = null; me.home_course = null }
  if (V.rounds === 'none') { me.index_current = null; me.index_source = null; me.home_course = null }
  if (V.rounds === 'one') { me.index_current = null; me.index_source = null }
  if (overrides.meIndex !== undefined) me.index_current = overrides.meIndex

  /* ---- leagues, settings, seasons, members, squads ---- */
  const leagues = [...LEAGUES]
  leagues.push({ n: 3, name: 'Desert Setup League (fixture)', code: 'DSFX26', phase: 'setup', sandbox: false, pro: 1, members: [1],
    season: null, squads: [], settings: { ...LEAGUES[0].settings, locked_at: null, structure: 'squads2', season_format: 'points', counting_cap: 4 } })
  T.leagues = []; T.league_settings = []; T.seasons = []; T.league_members = []; T.squads = []; T.squad_members = []; T.buy_ins = []
  const inLeague = new Set(V.leagues || [])
  for (const L of leagues) {
    const members = L.n === 1 || L.n === 2 ? L.members : L.members
    T.leagues.push({ id: lid(L.n), name: L.name, code: L.code, phase: L.phase, sandbox: L.sandbox, created_by: uid(L.pro), created_at: '2026-07-20T18:00:00Z' })
    T.league_settings.push({ league_id: lid(L.n), ...L.settings })
    if (L.season) T.seasons.push({ id: sid(L.n, 1), league_id: lid(L.n), number: L.season.number, starts_on: L.season.starts_on, ends_on: L.season.ends_on,
      status: L.season.status, champion_squad_id: null, champion_member_id: null, runnerup_squad_id: null, runnerup_member_id: null,
      points_king_member_id: null, champion_score: null, runnerup_score: null, tiebreak_rung: null, pot_cents: L.season.pot_cents, collected_cents: L.season.collected_cents })
    for (const pn of members) {
      if (pn === 1 && !inLeague.has(L.n)) continue
      const role = pn === 1 ? ((V.role || {})[L.n] || 'player') : (pn === L.pro && !(pn !== 1 && (V.role || {})[L.n] === 'commissioner') ? 'commissioner' : 'player')
      T.league_members.push({ id: mid(L.n, pn), league_id: lid(L.n), profile_id: uid(pn), role, index_current: person(pn).index,
        joined_at: '2026-08-01T18:00:00Z', marker: null, suspended_at: null, agreed_seasons: L.season ? [L.season.number] : [] })
    }
    for (const q of L.squads) {
      T.squads.push({ id: qid(L.n, q.n), season_id: sid(L.n, 1), league_id: lid(L.n), name: q.name, color: q.color, captain_member_id: mid(L.n, q.captain) })
      for (const pn of q.members) if (pn !== 1 || inLeague.has(L.n)) T.squad_members.push({ squad_id: qid(L.n, q.n), member_id: mid(L.n, pn) })
    }
    if (L.season && L.settings.buyin_cents) for (const pn of members) {
      if (pn === 1 && !inLeague.has(L.n)) continue
      T.buy_ins.push({ season_id: sid(L.n, 1), member_id: mid(L.n, pn), paid: pn !== 5, amount_cents: L.settings.buyin_cents })
    }
  }
  /* the Pro of a league Avery runs is Avery; demote the cast's pro there */
  for (const m of T.league_members) {
    const L = leagues.find((x) => lid(x.n) === m.league_id)
    if (m.profile_id !== W.me && (V.role || {})[L.n] === 'commissioner') m.role = 'player'
  }

  /* ---- rounds and the scoring views ---- */
  let rounds = buildRounds()
  if (V.rounds === 'none') rounds = rounds.filter((r) => r.person !== 1)
  if (V.rounds === 'one') { const mine = rounds.filter((r) => r.person === 1); rounds = rounds.filter((r) => r.person !== 1).concat(mine.slice(0, 1)) }
  if (V.photo === 'none') rounds.forEach((r) => { r.photo_path = null })
  T.rounds = rounds.map((r) => ({ id: r.id, profile_id: r.profile_id, gross: r.gross, rating: r.rating, slope: r.slope, differential: r.differential,
    index_at_post: r.index_at_post, played_on: r.played_on, course_label: r.course_label, holes_played: r.holes_played, photo_path: r.photo_path,
    api_course_id: r.api_course_id, created_at: r.created_at, tee_name: r.tee_name, par: r.par }))
  T.v_rounds_ranked = []
  for (const L of leagues) {
    if (!L.season) continue
    const allowance = L.settings.handicap_allowance
    for (const m of T.league_members.filter((x) => x.league_id === lid(L.n))) {
      const mine = T.rounds.filter((r) => r.profile_id === m.profile_id && r.played_on >= L.season.starts_on && r.played_on <= L.season.ends_on)
      const byMonth = {}
      for (const r of mine) (byMonth[r.played_on.slice(0, 7)] ||= []).push(r)
      for (const list of Object.values(byMonth)) {
        const scored = list.map((r) => ({ r, pvi: pviOf(r, allowance) })).sort((a, b) => b.pvi - a.pvi)
        scored.forEach(({ r, pvi }, i) => T.v_rounds_ranked.push({
          round_id: r.id, season_id: sid(L.n, 1), league_id: lid(L.n), member_id: m.id, profile_id: m.profile_id,
          pvi, points: pointsOf(pvi), band: bandOf(pvi), month_rank: i + 1, floor_credit: 1, played_on: r.played_on,
          index_at_post: r.index_at_post, holes_played: r.holes_played, gross: r.gross, course_label: r.course_label,
        }))
      }
    }
  }
  const cap = (L) => L.settings.counting_cap
  T.v_individual_standings = []
  T.v_squad_standings = []
  for (const L of leagues) {
    if (!L.season) continue
    for (const m of T.league_members.filter((x) => x.league_id === lid(L.n))) {
      const rr = T.v_rounds_ranked.filter((x) => x.member_id === m.id)
      const counting = rr.filter((x) => cap(L) == null || x.month_rank <= cap(L))
      T.v_individual_standings.push({ season_id: sid(L.n, 1), league_id: lid(L.n), member_id: m.id, profile_id: m.profile_id,
        points: counting.reduce((a, x) => a + x.points, 0), rounds_posted: rr.length })
    }
    for (const q of T.squads.filter((x) => x.season_id === sid(L.n, 1))) {
      const ids = T.squad_members.filter((x) => x.squad_id === q.id).map((x) => x.member_id)
      const pts = T.v_individual_standings.filter((x) => ids.includes(x.member_id)).reduce((a, x) => a + x.points, 0)
      T.v_squad_standings.push({ season_id: q.season_id, squad_id: q.id, points: pts })
    }
  }
  /* the ledger: one floor deduction, so a receipt has something to show */
  T.season_adjustments = [
    { id: 'fa000000-0000-4000-8000-000000000001', season_id: sid(1, 1), squad_id: qid(1, 1), member_id: mid(1, 5), month: '2026-08-01',
      kind: 'floor', points: -3, reason: 'August floor: one round of two', created_by: null, created_at: '2026-09-01T07:10:00Z' },
    { id: 'fa000000-0000-4000-8000-000000000002', season_id: sid(1, 1), squad_id: null, member_id: null, month: '2026-08-01',
      kind: 'month_closed', points: 0, reason: 'sentinel', created_by: null, created_at: '2026-09-01T07:10:01Z' },
  ].filter(() => inLeague.has(1))
  T.v_squad_standings.forEach((s) => { s.points += T.season_adjustments.filter((a) => a.squad_id === s.squad_id).reduce((a, x) => a + x.points, 0) })
  T.week_clashes = inLeague.has(1) ? [{ id: 'fb000000-0000-4000-8000-000000000001', season_id: sid(1, 1), week_no: 8, a_member: mid(1, 1), b_member: mid(1, 4),
    opened_at: W.at(-1, 7, 0), settled_at: null, winner_member: null, a_best: 1.3, b_best: 0.4 }] : []
  /* the weekly snapshots the cron records, DERIVED: each squad's counting
     points from the rounds played up to that week's end (ledger rows dated
     inside it included), ranked -- so the season story and the movement
     labels read the same history the table does */
  T.standings_snapshots = []
  const L1 = leagues.find((x) => x.n === 1)
  if (inLeague.has(1) && L1 && L1.season) {
    const squads1 = T.squads.filter((q) => q.season_id === sid(1, 1))
    for (let w = 1; w <= 7; w++) {
      const cut = addDays(L1.season.starts_on, w * 7 - 1)
      const pts = squads1.map((q) => {
        const ids = T.squad_members.filter((x) => x.squad_id === q.id).map((x) => x.member_id)
        const rr = T.v_rounds_ranked.filter((x) => x.season_id === sid(1, 1) && ids.includes(x.member_id) && x.played_on <= cut && (cap(L1) == null || x.month_rank <= cap(L1)))
        const adj = T.season_adjustments.filter((a) => a.squad_id === q.id && a.kind !== 'month_closed' && String(a.created_at).slice(0, 10) <= cut)
        return { squad_id: q.id, points: rr.reduce((a, x) => a + x.points, 0) + adj.reduce((a, x) => a + x.points, 0) }
      }).sort((a, b) => b.points - a.points || a.squad_id.localeCompare(b.squad_id))
      T.standings_snapshots.push({ season_id: sid(1, 1), week_no: w, captured_at: `${addDays(L1.season.starts_on, w * 7)}T07:10:00-07:00`,
        standings: pts.map((x, i) => ({ ...x, rank: i + 1 })) })
    }
  }
  /* a month rank computed over the whole month can rank a round against one
     played after the snapshot; the snapshot is a fixture of the table's
     shape, not a replay of the cron -- close enough for a capture, and never
     contradicting who leads now */

  /* ---- the board ---- */
  T.posts = []; T.post_kudos = []; T.post_comments = []
  let pn = 1
  for (const r of T.rounds) {
    for (const m of T.league_members.filter((x) => x.profile_id === r.profile_id)) {
      const L = leagues.find((x) => lid(x.n) === m.league_id)
      if (!L.season || r.played_on < L.season.starts_on) continue
      const who = person(PEOPLE.find((p) => uid(p.n) === r.profile_id).n)
      T.posts.push({ id: pid(pn++), league_id: m.league_id, profile_id: r.profile_id, kind: 'round', member_id: m.id,
        body: `${who.name.split(' ')[0].toUpperCase()} POSTED ${r.gross} AT ${r.course_label.split(' · ')[0].toUpperCase()}`,
        created_at: r.created_at, round_id: r.id, live_round_id: null, scheduled_round_id: null })
    }
  }
  if (inLeague.has(1)) {
    T.posts.push({ id: pid(900), league_id: lid(1), profile_id: uid(2), kind: 'announce', member_id: mid(1, 2), body: 'Week 8: floors close Tuesday. Post what you played.', created_at: W.at(-2, 18, 5), round_id: null, live_round_id: null, scheduled_round_id: null })
    T.posts.push({ id: pid(901), league_id: lid(1), profile_id: uid(3), kind: 'chat', member_id: mid(1, 3), body: 'Anyone up for Saguaro Flats on Saturday? Tee sheet opens Wednesday.', created_at: W.at(-1, 12, 40), round_id: null, live_round_id: null, scheduled_round_id: null })
    /* the board's moment says what the table says: whoever leads now */
    const lead = T.v_squad_standings.filter((x) => x.season_id === sid(1, 1)).sort((a, b) => b.points - a.points)[0]
    const leadName = lead ? (T.squads.find((q) => q.id === lead.squad_id) || {}).name : null
    if (leadName) T.posts.push({ id: pid(902), league_id: lid(1), profile_id: null, kind: 'moment', member_id: null, body: `${leadName.toUpperCase()} LEAD THE TABLE INTO WEEK 8`, created_at: W.at(-1, 20, 0), round_id: null, live_round_id: null, scheduled_round_id: null })
    const myPost = T.posts.find((p) => p.kind === 'round' && p.profile_id === W.me)
    if (myPost) {
      T.post_kudos.push({ post_id: myPost.id, member_id: mid(1, 2), emoji: '🔥', created_at: W.at(0, 7, 5) }, { post_id: myPost.id, member_id: mid(1, 3), emoji: '👏', created_at: W.at(0, 7, 20) })
      T.post_comments.push({ id: 'fc000000-0000-4000-8000-000000000001', post_id: myPost.id, member_id: mid(1, 4), body: 'Clean card. Back nine was the difference.', created_at: W.at(0, 8, 2) })
    }
  }
  T.forfeits = []
  T.live_rounds = []; T.live_round_players = []
  T.round_holes = []; T.round_comments = []
  T.invites = []
  T.push_subscriptions = []
  T.app_flags = [{ key: 'scan', value: { enabled: true, daily_cap: 3, reason: null } }]

  /* ---- courses (the provider cache) ---- */
  T.api_courses = []; T.api_course_tees = []; T.api_course_holes = []
  let teeId = 1
  for (const c of COURSES) {
    T.api_courses.push({ id: c.id, club_name: c.club, course_name: c.course, city: c.city, state: c.state })
    for (const t of c.tees) {
      const tid = teeId++
      T.api_course_tees.push({ id: tid, course_id: c.id, tee_name: t.tee, gender: t.gender, course_rating: t.rating, slope_rating: t.slope, number_of_holes: t.holes, total_yards: t.yards })
      for (let h = 1; h <= t.holes; h++) T.api_course_holes.push({ tee_id: tid, hole_number: h, par: PARS18[h - 1], handicap: SI18[h - 1], yardage: t.yards ? Math.round(t.yards / t.holes) : null })
    }
  }

  /* ---- events ---- */
  T.events = []; T.event_teams = []; T.event_players = []; T.event_sessions = []; T.event_duels = []; T.v_event_scoreboard = []; T.event_major_cards = []

  /* ---- RPC handlers: every module under ./rpc ---- */
  W.handlers = {}
  return W
}

export async function loadHandlers(W) {
  const dir = join(HERE, 'rpc')
  let files = []
  try { files = readdirSync(dir).filter((f) => f.endsWith('.mjs')).sort() } catch { files = [] }
  for (const f of files) {
    const mod = await import(pathToFileURL(join(dir, f)).href)
    const install = mod.default
    if (typeof install !== 'function') continue
    const h = install(W) || {}
    for (const [k, v] of Object.entries(h)) W.handlers[k] = v
  }
  return W
}

/* ------------------------------------------------------------ projection */
export function project(W, table, row, tree) {
  const out = {}
  for (const item of tree) {
    if (item.star) { for (const [k, v] of Object.entries(row)) if (typeof v !== 'object' || v === null || Array.isArray(v)) out[k] = v; continue }
    if (!item.embed) { out[item.alias] = row[item.col] === undefined ? null : row[item.col]; continue }
    const rel = REL[`${table}.${item.target}`] || guessRel(W, table, item.target, row)
    const target = W.tables[item.target] || []
    if (!rel) { out[item.alias] = null; continue }
    if (rel.one) {
      const key = rel.key || 'id'
      const t = target.find((x) => row[rel.one] != null && String(x[key]) === String(row[rel.one]))
      out[item.alias] = t ? project(W, item.target, t, item.inner) : null
    } else {
      out[item.alias] = target.filter((x) => String(x[rel.many]) === String(row.id)).map((t) => project(W, item.target, t, item.inner))
    }
  }
  return out
}
function guessRel(W, from, target, row) {
  const singular = target.replace(/ies$/, 'y').replace(/s$/, '')
  if (row[singular + '_id'] !== undefined) return { one: singular + '_id' }
  const fs = from.replace(/ies$/, 'y').replace(/s$/, '')
  return { many: fs + '_id' }
}

/* -------------------------------------------------------- the responder API */
export function worldApi(W) {
  const session = sessionFor(W)
  return {
    session,
    async auth(what, { method, body }) {
      if (W.errors.auth && W.errors.auth[what.split('?')[0]]) return W.errors.auth[what.split('?')[0]]
      if (what.startsWith('user')) return session ? { body: session.user } : { status: 401, body: { code: 401, msg: 'no session' } }
      if (what.startsWith('token')) {
        if (!session) return { status: 400, body: { error: 'invalid_grant', error_description: 'fixture: no session' } }
        /* a refresh answers with a fresh year-long session for the same user */
        const fresh = sessionFor({ ...W, V: { ...W.V, sessionTtl: 86400 * 365 } })
        return { body: fresh }
      }
      if (what.startsWith('otp')) return { body: {} }
      if (what.startsWith('verify')) return { status: 403, body: { code: 403, error_code: 'otp_expired', msg: 'Token has expired or is invalid' } }
      if (what.startsWith('logout')) return { status: 204, raw: { status: 204, body: '' } }
      return GAP
    },
    async storage(path, { method, body }) {
      /* signed URLs point at the storage host itself, then answered below with
         a generated image; nothing is fetched from the bucket */
      if (/^object\/sign\//.test(path) && method === 'POST') {
        const bucketPath = path.replace(/^object\/sign\//, '')
        if (body && Array.isArray(body.paths)) {
          return { body: body.paths.map((p) => ({ path: p, signedURL: `/object/sign/${bucketPath}/${p}?token=fixture`, error: null })) }
        }
        return { body: { signedURL: `/object/sign/${bucketPath}?token=fixture` } }
      }
      /* an upload (the composer's photo, a shared card's public copy) is
         accepted and remembered; nothing leaves this machine */
      if (/^object\/(?!sign\/|public\/|authenticated\/|list\/)/.test(path) && (method === 'POST' || method === 'PUT')) {
        const key = path.replace(/^object\//, '')
        ;(W.uploads ||= []).push(key)
        return { body: { Key: key, Id: 'fixture-upload-' + W.uploads.length } }
      }
      if (/^object\//.test(path) && method === 'DELETE') return { body: [] }
      if (/^object\/(sign|public|authenticated)\//.test(path) || /^render\/image\//.test(path)) {
        if (W.flags.brokenPhotos || /broken/.test(path)) return { status: 404, raw: { status: 404, contentType: 'application/json', body: '{"error":"not_found"}' } }
        return { raw: { status: 200, contentType: 'image/svg+xml', body: fixturePhotoSvg(path) } }
      }
      return GAP
    },
    async fn(name, { body }) {
      const h = W.handlers['fn:' + name.split('?')[0]]
      if (h) return h(body)
      return GAP
    },
    async rpc(name, args) {
      if (W.errors.rpc && W.errors.rpc[name]) return W.errors.rpc[name]
      const h = W.handlers[name]
      if (!h) return GAP
      const v = await h(args || {}, W)
      /* a handler may answer the way the SQL raises: { __error, status, code } */
      if (v && typeof v === 'object' && !Array.isArray(v) && typeof v.__error === 'string') return v
      return v === undefined ? GAP : { __value: v }
    },
    async table(name, { params } = {}) {
      /* a failure scoped to one query shape: { table, match(queryString) => bool, error } */
      const qs = new URLSearchParams(params || []).toString()
      for (const w of (W.errors.when || [])) if (w.table === name && (!w.match || w.match(decodeURIComponent(qs)))) return w.error
      if (W.errors.table && W.errors.table[name]) return W.errors.table[name]
      const rows = W.tables[name]
      if (!rows) return GAP
      return rows
    },
    project(name, row, select) { return project(W, name, row, parseSelect(select)) },
    async write(table, { method, body }) {
      if (table === 'client_events') return Array.isArray(body) ? body : [body || {}]
      if (W.errors.write && W.errors.write[table]) return W.errors.write[table]
      const h = W.handlers['write:' + table]
      if (h) return h(method, body)
      return GAP
    },
  }
}

function b64url(o) { return Buffer.from(JSON.stringify(o)).toString('base64url') }
export function sessionFor(W) {
  if (!W.V.session) return null
  const p = PEOPLE[0]
  /* `sessionTtl` (seconds) lets a probe hand the client a session that is
     about to expire, so the refresh path runs against the world */
  const ttl = W.V.sessionTtl != null ? W.V.sessionTtl : 86400 * 365
  const exp = Math.floor(Date.parse(CAPTURE_NOW) / 1000) + ttl
  const token = b64url({ alg: 'HS256', typ: 'JWT' }) + '.' + b64url({ sub: uid(1), role: 'authenticated', aud: 'authenticated', exp, iat: exp - 86400 * 365, email: p.email, session_id: 'fixture-session' }) + '.fixture-signature-not-valid'
  const user = { id: uid(1), aud: 'authenticated', role: 'authenticated', email: p.email, email_confirmed_at: '2026-03-01T19:00:00Z',
    app_metadata: { provider: 'email', providers: ['email'] }, user_metadata: {}, created_at: '2026-03-01T19:00:00Z', updated_at: '2026-09-01T19:00:00Z' }
  return { access_token: token, token_type: 'bearer', expires_in: ttl, expires_at: exp, refresh_token: 'fixture-refresh-token', user }
}

/* a quiet, obviously-synthetic "photograph": a course-green gradient with
   contour lines and the word FIXTURE -- never a real image */
export function fixturePhotoSvg(seed = '') {
  let h = 0; for (const ch of String(seed)) h = (h * 31 + ch.charCodeAt(0)) >>> 0
  const hue = 95 + (h % 50)
  return `<svg xmlns="http://www.w3.org/2000/svg" width="1200" height="800" viewBox="0 0 1200 800">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="hsl(${hue},32%,38%)"/><stop offset="1" stop-color="hsl(${hue + 20},40%,22%)"/></linearGradient></defs>
<rect width="1200" height="800" fill="url(#g)"/>
<g fill="none" stroke="rgba(255,255,255,.18)" stroke-width="3">${Array.from({ length: 9 }, (_, i) => `<ellipse cx="${760 + (h % 90)}" cy="${300 + (h % 70)}" rx="${80 + i * 70}" ry="${50 + i * 44}"/>`).join('')}</g>
<text x="60" y="740" font-family="Helvetica,Arial" font-size="44" fill="rgba(255,255,255,.55)" letter-spacing="8">FIXTURE PHOTO</text></svg>`
}
