/* Cup Season · ten-capture RPC answers for HOME and the SOCIAL surfaces
 * (WX lane, helper WX-A, 2026-09-28).
 *
 * Every handler below is a JS port of the LATEST SQL definition of that RPC
 * (the migration is named beside it), evaluated over the synthetic world
 * (tests/fixtures/ten/world.mjs). Nothing is typed in as a finished figure:
 * points, ranks, gaps, forms and records are all computed from
 * W.tables.rounds / v_rounds_ranked / v_*_standings, so every number a
 * capture shows traces back to the rounds that produced it (spec §16).
 *
 * The social graph this file owns -- buddies, one pending request each way,
 * a named rivalry, a round-thread notification, a bag -- is written to
 * W.tables (friendships, rivalry_names, social_notifications, bag_items) so
 * any later helper reads the same facts. Variants that have none of it
 * (brand_new, one_round, rounds_no_league, no_card) get honest empties.
 *
 * A state can opt into extra shapes through the world's flags
 * (`world: { flags: {...} }` in a state, or W.flags in `prepare`):
 *   homeState: '<id>'   home_dispatch answers that Home-state PAYLOAD from
 *                       tests/fixtures/ten/home-states.synthetic.json, date
 *                       tokens resolved the way the web hatch resolves them
 *   friends: true|false force the social graph on or off for any variant
 *   inviteEvent: true   one pending event invitation from a buddy (my_invites;
 *                       the dispatch reads whatever my_invites answers, so a
 *                       sibling's `invite` flag shows up on Home the same way)
 *
 * Test-only. Only synthetic cast members appear here (tests/fixtures/ten/cast.mjs). */
import { readFileSync } from 'node:fs'
import { addDays } from '../cast.mjs'

const U = (block, n) => `${block}-0000-4000-8000-${String(n).padStart(12, '0')}`
/* id blocks of this module's own rows: fd1x (module 10), clear of the cast's
   f1..fc blocks and of the sibling modules' fd2x..fd4x / fe4x */
const fid = (n) => U('fd110000', n)     /* friendships */
const nid = (n) => U('fd120000', n)     /* social_notifications */
const bid = (n) => U('fd130000', n)     /* bag_items */
const iid = (n) => U('fd140000', n)     /* member_invites */

const DOW3 = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
const MON3 = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec']
const MONTH = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
const DAY = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']

/* ---------------------------------------------------------------- dates */
const parts = (iso) => String(iso).slice(0, 10).split('-').map(Number)
const utc = (iso) => { const [y, m, d] = parts(iso); return Date.UTC(y, m - 1, d) }
const dd = (a, b) => Math.round((utc(b) - utc(a)) / 864e5)          /* b - a, in days */
const dow = (iso) => new Date(utc(iso)).getUTCDay()
const weekOf = (iso) => addDays(String(iso).slice(0, 10), -((dow(iso) + 6) % 7))   /* date_trunc('week') = Monday */
const monthStart = (iso) => String(iso).slice(0, 7) + '-01'
const monthEnd = (iso) => { const [y, m] = parts(iso); return addDays(`${m === 12 ? y + 1 : y}-${String(m === 12 ? 1 : m + 1).padStart(2, '0')}-01`, -1) }
const r1 = (x) => Math.round(x * 10) / 10
const firstname = (s) => (String(s || '').trim().split(' ')[0]) || 'Someone'   /* public.firstname */
const ordinal = (n) => { const v = n % 100; return n + (['th', 'st', 'nd', 'rd'][(v - 20) % 10] || ['th', 'st', 'nd', 'rd'][v] || 'th') }
const fm = (x) => String(r1(Number(x))).replace(/\.0$/, '')            /* to_char(x,'FM999990.9') with the dot trimmed */

/* the web hatch's own token resolver (index.html csResolveFixtureDates), in en-US */
function resolveTokens(text, today) {
  return String(text).replace(/@(today|eyebrow)([+-]\d+)?/g, (_, kind, off) => {
    const d = addDays(today, parseInt(off || '0', 10))
    if (kind === 'today') return d
    const [, m, day] = parts(d)
    return `${DOW3[dow(d)]} · ${MON3[m - 1]} ${day}`.toUpperCase()
  })
}

export default function install(W) {
  const T = W.tables
  const { uid, lid, mid } = W.ids
  const ME = W.me
  const TODAY = W.today
  const V = W.V || {}
  const signedIn = !!V.session
  const carded = V.card !== false

  /* ------------------------------------------------------ the social graph */
  const graphOn = W.flags.friends !== undefined ? !!W.flags.friends
    : signedIn && carded && ['member', 'pro', 'pro_setup'].includes(W.variant)
  T.friendships = !graphOn ? [] : [
    { id: fid(1), requester: uid(1), addressee: uid(2), status: 'accepted', created_at: '2026-06-02T18:04:00-07:00' },
    { id: fid(2), requester: uid(3), addressee: uid(1), status: 'accepted', created_at: '2026-06-09T07:40:00-07:00' },
    { id: fid(3), requester: uid(1), addressee: uid(4), status: 'accepted', created_at: '2026-07-11T19:15:00-07:00' },
    { id: fid(4), requester: uid(8), addressee: uid(1), status: 'accepted', created_at: '2026-08-03T12:02:00-07:00' },
    { id: fid(5), requester: uid(1), addressee: uid(10), status: 'accepted', created_at: '2026-09-07T16:30:00-07:00' },
    /* one waiting on me (Kit has no league and no rounds: a pure buddy request) */
    { id: fid(6), requester: uid(11), addressee: uid(1), status: 'pending', created_at: W.at(-1, 19, 30) },
    /* one I sent that has not been answered */
    { id: fid(7), requester: uid(1), addressee: uid(6), status: 'pending', created_at: W.at(-3, 9, 10) },
  ]
  T.rivalry_names = !graphOn ? [] : [
    { pair_low: uid(1), pair_high: uid(4), name: 'The Fixture Derby', named_by: uid(4), created_at: '2026-08-24T08:00:00-07:00' },
  ]
  T.mutes = []
  T.social_notify_prefs = []

  /* ---------------------------------------------------------- lookups */
  const prof = (id) => T.profiles.find((p) => p.id === id) || null
  const liveProfile = (id) => { const p = prof(id); return p && !p.deleted_at ? p : null }
  const rounds = () => T.rounds.filter((r) => !r.voided)
  const roundById = (id) => T.rounds.find((r) => r.id === id) || null
  const leagueOf = (id) => T.leagues.find((l) => l.id === id) || null
  const settingsOf = (id) => T.league_settings.find((s) => s.league_id === id) || {}
  const membersOf = (leagueId) => T.league_members.filter((m) => m.league_id === leagueId)
  const myMemberships = () => T.league_members.filter((m) => m.profile_id === ME)
  const myMemberIn = (leagueId) => T.league_members.find((m) => m.league_id === leagueId && m.profile_id === ME) || null
  const isMember = (leagueId) => !!myMemberIn(leagueId)
  const activeSeason = (leagueId) => T.seasons.filter((s) => s.league_id === leagueId && ['active', 'cup_final'].includes(s.status))
    .sort((a, b) => b.starts_on.localeCompare(a.starts_on))[0] || null
  const accepted = (a, b) => T.friendships.some((f) => f.status === 'accepted' && ((f.requester === a && f.addressee === b) || (f.requester === b && f.addressee === a)))
  const friendsOf = (v) => T.friendships.filter((f) => f.status === 'accepted' && (f.requester === v || f.addressee === v)).map((f) => (f.requester === v ? f.addressee : f.requester))
  const leagueMatesOf = (v) => { const ls = new Set(T.league_members.filter((m) => m.profile_id === v).map((m) => m.league_id)); return T.league_members.filter((m) => ls.has(m.league_id)).map((m) => m.profile_id) }
  const eventMatesOf = (v) => { const es = new Set((T.event_players || []).filter((p) => p.profile_id === v).map((p) => p.event_id)); return (T.event_players || []).filter((p) => es.has(p.event_id)).map((p) => p.profile_id) }
  const shareLeague = (a, b) => leagueMatesOf(a).includes(b)
  const shareEvent = (a, b) => eventMatesOf(a).includes(b)
  const muted = (a, b) => a !== b && T.mutes.some((m) => (m.muter === a && m.muted === b) || (m.muter === b && m.muted === a))
  /* _social_circle: me · accepted buddies · league mates · event mates (first relation wins) */
  const circle = (v) => {
    const out = new Map([[v, 'me']])
    for (const p of friendsOf(v)) if (!out.has(p)) out.set(p, 'friend')
    for (const p of leagueMatesOf(v)) if (!out.has(p)) out.set(p, 'league')
    for (const p of eventMatesOf(v)) if (!out.has(p)) out.set(p, 'event')
    return out
  }
  /* the Tour-Card gate (L-37 / D150): self, buddy, shared league or event, or discoverable = everyone */
  /* TEN / W6 · the column is TEXT ('everyone' | 'friends' | 'nobody', 20260712010000);
     the world stored `true`, which no real row can hold */
  const discoverable = (p) => p && p.discoverable === 'everyone'
  const cardVisible = (v, p) => p === v || accepted(v, p) || shareLeague(v, p) || shareEvent(v, p) || discoverable(prof(p))
  const apiCourse = (id) => (T.api_courses || []).find((c) => String(c.id) === String(id)) || null
  const courseKey = (r) => { if (r.api_course_id == null || r.api_course_id === '') return null; const c = apiCourse(r.api_course_id); return c ? (c.club_name + (c.course_name && c.course_name !== c.club_name ? ' ' + c.course_name : '')).toLowerCase().trim() : String(r.course_label || '').split(' · ')[0].toLowerCase().trim() }
  const courseName = (r) => { if (r.api_course_id == null || r.api_course_id === '') return null; const c = apiCourse(r.api_course_id); return c ? (c.club_name + (c.course_name && c.course_name !== c.club_name ? ' — ' + c.course_name : '')).trim() : String(r.course_label || '').split(' · ')[0].trim() }
  const person = (id) => { const p = liveProfile(id); return p ? { id: p.id, name: p.display_name, marker: p.marker, handle: p.handle } : null }   /* _social_person */
  const rrOf = (roundId) => T.v_rounds_ranked.filter((x) => x.round_id === roundId)
  /* the allowance lens, one row per round (tour_card / bag_of): best points, then best pvi */
  const lensOf = (profileId) => {
    const by = new Map()
    for (const x of T.v_rounds_ranked.filter((y) => y.profile_id === profileId && y.pvi != null)) {
      const cur = by.get(x.round_id)
      if (!cur || x.points > cur.points || (x.points === cur.points && x.pvi > cur.pvi)) by.set(x.round_id, x)
    }
    return [...by.values()]
  }

  /* ------------------------------------------------ home_feed / home_stories */
  /* home_feed: 20261020090000_one_round_one_number.sql (unpatched since: its
     "under 80" still compares the gross whatever the holes played -- see the
     report). home_stories: 20260908090000 as patched by 20261129090000 (S12:
     the milestone and its "never before" window need eighteen holes). */
  function circleRounds(days, eighteenRule) {
    const ids = new Set(circle(ME).keys())
    const all = rounds().filter((r) => ids.has(r.profile_id))
    const byPid = new Map()
    for (const r of all) (byPid.get(r.profile_id) || byPid.set(r.profile_id, []).get(r.profile_id)).push(r)
    const out = []
    for (const list of byPid.values()) {
      list.sort((a, b) => a.played_on.localeCompare(b.played_on) || a.id.localeCompare(b.id))
      let priorBest = null, priorSub80 = false
      list.forEach((r, i) => {
        out.push({ r, rn: i + 1, priorBest, priorSub80 })
        if (r.differential != null) priorBest = priorBest == null ? r.differential : Math.min(priorBest, r.differential)
        if (r.gross < 80 && (!eighteenRule || r.holes_played === 18)) priorSub80 = true
      })
    }
    const floor = addDays(TODAY, -Math.max(1, days || 21))
    return out.filter((x) => x.r.played_on >= floor)
      .sort((a, b) => b.r.created_at.localeCompare(a.r.created_at) || b.r.id.localeCompare(a.r.id)).slice(0, 40)
  }
  function homeFeed(days) {
    return circleRounds(days, false).filter((x) => x.r.differential != null).map(({ r, rn, priorBest, priorSub80 }) => {
      const p = prof(r.profile_id)
      /* min(playing_index) - differential = the lowest pvi the round scored
         under (D324: the receipt's own number); the raw index with no league */
      const lens = rrOf(r.id).map((x) => x.pvi)
      return {
        round_id: r.id, profile_id: r.profile_id, golfer: p.display_name, marker: p.marker, handle: p.handle, gross: r.gross,
        pvi: r.index_at_post != null ? (lens.length ? Math.min(...lens) : r1(r.index_at_post - r.differential)) : null,
        played_on: r.played_on, created_at: r.created_at, course: r.course_label,
        is_pr: rn > 1 && priorBest != null && r.differential < priorBest, is_first: rn === 1,
        is_sub80: r.gross < 80 && !priorSub80, is_me: r.profile_id === ME, photo_path: r.photo_path || null,
      }
    })
  }
  function homeStories(days) {
    return circleRounds(days, true).map(({ r, rn, priorBest, priorSub80 }) => {
      const p = prof(r.profile_id)
      return {
        round_id: r.id, profile_id: r.profile_id, golfer: p.display_name, marker: p.marker, handle: p.handle, gross: r.gross,
        pvi: r.index_at_post != null && r.differential != null ? r1(r.index_at_post - r.differential) : null,
        played_on: r.played_on, created_at: r.created_at, course: r.course_label,
        is_pr: rn > 1 && priorBest != null && r.differential != null && r.differential < priorBest, is_first: rn === 1,
        is_sub80: r.gross < 80 && r.holes_played === 18 && !priorSub80, is_me: r.profile_id === ME,
        photo_path: r.photo_path || null, has_rating: r.differential != null,
      }
    })
  }

  /* --------------------------------------------------------- home_clash */
  /* 20260831160000_home_lead_and_clash_beats.sql */
  function homeClash(leagueId) {
    const meM = myMemberIn(leagueId); if (!meM) return null
    const se = activeSeason(leagueId); if (!se) return null
    const local = TODAY
    const wc = (T.week_clashes || []).filter((c) => c.season_id === se.id && !c.settled_at && (c.a_member === meM.id || c.b_member === meM.id)
      && addDays(se.starts_on, 7 * (c.week_no - 1)) <= local && addDays(se.starts_on, 7 * (c.week_no - 1) + 6) >= local)
      .sort((a, b) => b.week_no - a.week_no)[0]
    if (!wc) return null
    const ws = addDays(se.starts_on, 7 * (wc.week_no - 1)), we = addDays(ws, 6)
    const them = wc.a_member === meM.id ? wc.b_member : wc.a_member
    const cap = settingsOf(leagueId).counting_cap
    const best = (memberId) => {
      const x = T.v_rounds_ranked.filter((y) => y.season_id === se.id && y.member_id === memberId && y.month_rank <= (cap == null ? 999 : cap) && y.played_on >= ws && y.played_on <= we)
        .sort((a, b) => b.points - a.points || b.pvi - a.pvi || a.played_on.localeCompare(b.played_on))[0]
      if (!x) return null
      const r = roundById(x.round_id)
      return { round_id: x.round_id, played_on: x.played_on, points: x.points, pvi: x.pvi, gross: r ? r.gross : null }
    }
    const tm = T.league_members.find((m) => m.id === them) || {}
    const tp = prof(tm.profile_id) || {}
    const pa = (T.league_members.find((m) => m.id === wc.a_member) || {}).profile_id, pb = (T.league_members.find((m) => m.id === wc.b_member) || {}).profile_id
    const rn = T.rivalry_names.find((x) => x.pair_low === [pa, pb].sort()[0] && x.pair_high === [pa, pb].sort()[1])
    return { week_no: wc.week_no, ends_on: we, days_left: dd(local, we), closes_today: we === local, them_name: tp.display_name || null,
      them_marker: tm.marker || tp.marker || null, mine: best(meM.id), theirs: best(them), rivalry: rn ? rn.name : null }
  }

  /* -------------------------------------------------------- league_pulse */
  /* 20261030090000_the_pulse_says_who_joined_and_who_has_a_bye.sql */
  function leaguePulse(leagueId) {
    if (!isMember(leagueId)) return []
    const se = activeSeason(leagueId); if (!se) return []
    const mo = monthStart(TODAY), me2 = monthEnd(TODAY)
    const ps = settingsOf(leagueId).participation_floor
    const floor = ps == null ? 2 : ps
    const partial = se.starts_on > mo || se.ends_on < me2
    return membersOf(leagueId).map((lm) => {
      const p = prof(lm.profile_id)
      const credits = T.v_rounds_ranked.filter((x) => x.member_id === lm.id && x.season_id === se.id && monthStart(x.played_on) === mo).reduce((a, x) => a + (x.floor_credit || 0), 0)
      return { profile_id: p.id, display_name: p.display_name, marker: p.marker, credits, floor, at_floor: credits >= floor, is_me: p.id === ME,
        partial, joined_this_month: monthStart(String(lm.joined_at).slice(0, 10)) === mo,
        bye_available: !(T.season_adjustments || []).some((b) => b.season_id === se.id && b.member_id === lm.id && b.kind === 'bye') }
    }).sort((a, b) => (a.at_floor === b.at_floor ? 0 : a.at_floor ? 1 : -1) || a.credits - b.credits || a.display_name.localeCompare(b.display_name))
  }

  /* ---------------------------------------------------------- my_invites */
  /* 20261115090000_season_two_is_a_re_up.sql. The world keeps no invitations;
     `flags.inviteEvent` stages one event invitation from a buddy. */
  function myInvites() {
    if (!signedIn || !W.flags.inviteEvent) return []
    return [{ id: iid(1), kind: 'event', container_id: W.ids.eid(901), container_name: 'The Fixture Showdown', inviter: 'Harper Examplar',
      starts_on: W.iso(12), created_at: W.at(-1, 18, 12), event_kind: 'ryder', buy_in: 0, season_number: null, reup: false }]
  }
  /* native_home embeds my_invites() and my_schedule(): read through the
     world's CURRENT answer, so a sibling module that stages a plan or an
     invitation shows up in the dispatch exactly as the server would compose it */
  const composed = (name, args, fallback) => {
    try { const h = W.handlers[name]; const v = h ? h(args, W) : fallback(); return Array.isArray(v) ? v : [] } catch (_) { return [] }
  }

  /* ---------------------------------------------------------- native_home */
  /* 20261019090000_the_card_knows_where_it_has_been.sql -- the `me` half of
     home_dispatch. Nothing here is its own RPC on the web. */
  function seasonJson(L, se) {
    const s = settingsOf(L.id)
    const d = TODAY
    const total = Math.max(1, Math.ceil(dd(se.starts_on, se.ends_on) / 7))
    return { id: se.id, number: se.number, starts_on: se.starts_on, ends_on: se.ends_on, status: se.status, timezone: 'America/Phoenix', grace_hours: 36,
      champion_squad_id: se.champion_squad_id || null, champion_member_id: se.champion_member_id || null,
      points_king_member_id: se.points_king_member_id || null, tiebreak_rung: se.tiebreak_rung || null,
      week_no: Math.max(1, Math.min(total, Math.floor(dd(se.starts_on, d) / 7) + 1)), weeks_total: total,
      week_ends_on: addDays(se.starts_on, Math.floor(Math.max(0, dd(se.starts_on, d)) / 7) * 7 + 6),
      days_to_first_tee: se.starts_on > d ? dd(d, se.starts_on) : null, days_left: Math.max(0, dd(d, se.ends_on)),
      final_opens_on: (s.finish || 'cup_final') === 'cup_final' ? addDays(se.ends_on, -27) : null }
  }
  function standingJson(L, se, meM, solo) {
    let rows
    if (!solo) {
      const sm = T.squad_members.find((x) => x.member_id === meM.id && T.squads.some((q) => q.id === x.squad_id && q.season_id === se.id))
      if (!sm) return null
      rows = T.v_squad_standings.filter((x) => x.season_id === se.id).map((x) => ({ key: x.squad_id, points: x.points, name: (T.squads.find((q) => q.id === x.squad_id) || {}).name || '' }))
      rows.sort((a, b) => b.points - a.points || a.name.localeCompare(b.name))
      const i = rows.findIndex((x) => x.key === sm.squad_id); if (i < 0) return null
      const up = rows[i - 1], dn = rows[i + 1]
      return { rank: i + 1, of: rows.length, points: rows[i].points, leader_squad_id: rows[0].key, leader_member_id: null, leader_points: rows[0].points,
        gap_to_leader: rows[0].points - rows[i].points, gap_to_next: up ? up.points - rows[i].points : null, leader_name: rows[0].name,
        runner_up_name: rows[1] ? rows[1].name : null, runner_up_points: rows[1] ? rows[1].points : null,
        next_up: up ? { name: up.name, points: up.points } : null, next_down: dn ? { name: dn.name, points: dn.points } : null, _key: sm.squad_id }
    }
    rows = T.v_individual_standings.filter((x) => x.season_id === se.id).map((x) => ({ key: x.member_id, points: x.points, name: (prof(x.profile_id) || {}).display_name || '' }))
    rows.sort((a, b) => b.points - a.points || a.name.localeCompare(b.name))
    const i = rows.findIndex((x) => x.key === meM.id); if (i < 0) return null
    const up = rows[i - 1], dn = rows[i + 1]
    return { rank: i + 1, of: rows.length, points: rows[i].points, leader_squad_id: null, leader_member_id: rows[0].key, leader_points: rows[0].points,
      gap_to_leader: rows[0].points - rows[i].points, gap_to_next: up ? up.points - rows[i].points : null, leader_name: firstname(rows[0].name),
      runner_up_name: rows[1] ? firstname(rows[1].name) : null, runner_up_points: rows[1] ? rows[1].points : null,
      next_up: up ? { name: firstname(up.name), points: up.points } : null, next_down: dn ? { name: firstname(dn.name), points: dn.points } : null, _key: meM.id }
  }
  /* prev_rank from the latest snapshot's `standings->'squads'` / `->'individuals'` */
  function prevRank(se, key, solo) {
    const snap = (T.standings_snapshots || []).filter((s) => s.season_id === se.id).sort((a, b) => b.week_no - a.week_no || String(b.captured_at).localeCompare(String(a.captured_at)))[0]
    const list = snap && snap.standings && !Array.isArray(snap.standings) ? (solo ? snap.standings.individuals : snap.standings.squads) : null
    if (!Array.isArray(list)) return null
    const nm = (e) => solo ? ((prof((T.league_members.find((m) => m.id === e.member_id) || {}).profile_id) || {}).display_name || '') : ((T.squads.find((q) => q.id === e.squad_id) || {}).name || '')
    const sorted = list.slice().sort((a, b) => Number(b.points) - Number(a.points) || nm(a).localeCompare(nm(b)))
    const i = sorted.findIndex((e) => (solo ? e.member_id : e.squad_id) === key)
    return i < 0 ? null : i + 1
  }
  function nativeHome() {
    const p = prof(ME); if (!p) return null
    const mine = rounds().filter((r) => r.profile_id === ME).sort((a, b) => b.played_on.localeCompare(a.played_on) || b.created_at.localeCompare(a.created_at))
    const withIdx = mine.filter((r) => r.index_at_post != null)
    const lr = mine[0] || null
    const profile = { id: p.id, display_name: p.display_name, handle: p.handle, marker: p.marker, city: p.city, home_course: p.home_course,
      index_current: p.index_current, index_prev: withIdx[4] ? withIdx[4].index_at_post : null, index_engine: p.index_current,
      index_source: p.index_source, photo_path: p.photo_path, rounds_count: mine.length, member_since: p.created_at, is_founder: false,
      last_round_on: lr ? lr.played_on : null, last_gross: lr ? lr.gross : null, last_round_id: lr ? lr.id : null,
      days_since_round: lr ? dd(lr.played_on, TODAY) : null }
    const phaseOrd = { season: 0, draft: 1, setup: 2 }
    const mems = myMemberships().slice().sort((a, b) => {
      const la = leagueOf(a.league_id), lb = leagueOf(b.league_id)
      return ((phaseOrd[la.phase] ?? 3) - (phaseOrd[lb.phase] ?? 3)) || String(b.joined_at).localeCompare(String(a.joined_at)) || la.id.localeCompare(lb.id)
    })
    const memberships = mems.map((lm) => {
      const L = leagueOf(lm.league_id), s = settingsOf(L.id), solo = s.structure === 'solo'
      const pro = membersOf(L.id).find((m) => m.role === 'commissioner')
      const proName = pro ? (prof(pro.profile_id) || {}).display_name : null
      const se = T.seasons.filter((x) => x.league_id === L.id).sort((a, b) => (['active', 'cup_final'].includes(b.status) - ['active', 'cup_final'].includes(a.status)) || b.starts_on.localeCompare(a.starts_on))[0] || null
      let season = null, squad = null, standing = null, pulse = null, buyIn = null, clash = null
      if (se) {
        season = seasonJson(L, se)
        if (!solo) {
          const sm = T.squad_members.find((x) => x.member_id === lm.id && T.squads.some((q) => q.id === x.squad_id && q.season_id === se.id))
          const q = sm && T.squads.find((x) => x.id === sm.squad_id)
          squad = q ? { id: q.id, name: q.name, color: q.color } : null
        }
        standing = standingJson(L, se, lm, solo)
        if (standing) { standing.prev_rank = prevRank(se, standing._key, solo); delete standing._key }
        const pr = leaguePulse(L.id).find((x) => x.is_me)
        pulse = pr ? { credits: pr.credits, floor: pr.floor, at_floor: pr.at_floor, partial: pr.partial } : null
        if (['active', 'cup_final'].includes(se.status)) clash = homeClash(L.id)
      }
      if ((s.buyin_cents || 0) > 0) {
        const bi = (T.buy_ins || []).filter((b) => se && b.season_id === se.id)
        const paid = bi.filter((b) => b.paid && membersOf(L.id).some((m) => m.id === b.member_id))
        buyIn = { paid: !!(bi.find((b) => b.member_id === lm.id) || {}).paid, note: s.buy_in_note || null, due_on: s.buy_in_due_on || null,
          players: Math.max(membersOf(L.id).length, 1), paid_count: paid.length, collected_cents: paid.reduce((a, b) => a + (b.amount_cents || 0), 0) }
      }
      return { league_id: L.id, name: L.name, code: L.code, phase: L.phase, sandbox: L.sandbox, role: lm.role, member_id: lm.id,
        marker: lm.marker || p.marker, commissioner_name: proName,
        settings: { structure: s.structure, preset: s.preset, counting_cap: s.counting_cap, participation_floor: s.participation_floor,
          floor_penalty: s.floor_penalty, handicap_allowance: s.handicap_allowance, buyin_cents: s.buyin_cents, payout_champ: s.payout_champ,
          payout_runnerup: s.payout_runnerup, payout_king: s.payout_king, finish: s.finish, locked_at: s.locked_at },
        season, squad, standing, pulse, buy_in: buyIn,
        roster: membersOf(L.id).filter((m) => !m.suspended_at).length, members: membersOf(L.id).length,
        pro_name: proName ? firstname(proName) : null, last_season: null, clash }
    })
    /* the tee sheet two weeks out, as my_schedule answers it */
    const upcoming = composed('my_schedule', { p_from: TODAY, p_to: addDays(TODAY, 14) }, () => [])
    const events = (T.events || []).filter((e) => ['setup', 'live'].includes(e.status) && (e.created_by === ME || (T.event_players || []).some((x) => x.event_id === e.id && x.profile_id === ME)))
      .map((e) => ({ id: e.id, name: e.name, kind: e.kind, status: e.status, starts_on: e.starts_on, league_id: e.league_id || null,
        my_team_slot: null, is_organizer: e.created_by === ME }))
    const scan = (T.app_flags || []).find((f) => f.key === 'scan')
    return { profile, memberships, invites: composed('my_invites', {}, myInvites), live_round: null, upcoming_rounds: upcoming, events, open_duels: [],
      flags: { ios: null, scan: scan ? scan.value : null }, generated_at: W.now }
  }

  /* -------------------------------------------------------- home_dispatch */
  /* 20261024090000_the_loop_has_a_closing_act.sql, with 20261102090000's
     capability gate + `context`, and 20261115090000's re-up sentence. */
  let fixtures = null
  function homeStatePayload(id) {
    if (!fixtures) fixtures = JSON.parse(resolveTokens(readFileSync(new URL('../home-states.synthetic.json', import.meta.url), 'utf8'), TODAY))
    const st = (fixtures.states || []).find((s) => s.id === id)
    return st ? st.payload : undefined
  }
  function homeDispatch(args) {
    if (W.flags.homeState) return homeStatePayload(W.flags.homeState)
    const days = Math.max(1, Number(args.p_days) || 21)
    const caps = Array.isArray(args.p_caps) ? args.p_caps : []
    const me = nativeHome()
    if (!me) return { me: null, items: [], generated_at: W.now }
    const items = []
    const nRounds = me.profile.rounds_count
    const nFriends = friendsOf(ME).length
    /* M11 · the season with the nearest dated thing */
    let nearest = null, best = null
    for (const m of me.memberships) {
      const se = m.season; if (!se) continue
      const when = se.week_ends_on || se.ends_on
      if (when && (best == null || when < best)) { best = when; nearest = m.league_id }
    }
    /* invitations (band 1, a buddy's weight) -- "See the terms", never "Join" */
    for (const e of me.invites) {
      items.push({ key: 'invite:' + e.id, tier: 'closing', band: 1000, mods: 12, mod_reason: 'M6 12 (a buddy asked)',
        subject: e.inviter ? firstname(e.inviter) : 'A golfer', human_subject: !!e.inviter, eyebrow: 'AN INVITATION',
        headline: e.reup ? `Season ${e.season_number || ''} of ${e.container_name || 'your league'} is on. Same rules, fresh table.`
          : `${e.inviter ? firstname(e.inviter) : 'A golfer'} put you on ${e.container_name || 'a season'}.`,
        standfirst: 'See the terms before you are in.', action: 'See the terms',
        route: { kind: 'invite', id: e.container_id, pane: e.kind }, league_id: e.kind === 'league' ? e.container_id : null,
        suppress: [], spine: 'ember', at: e.created_at })
    }
    /* a buddy request waiting, answered on the Golfers list */
    for (const f of T.friendships.filter((x) => x.addressee === ME && x.status === 'pending').sort((a, b) => b.created_at.localeCompare(a.created_at)).slice(0, 3)) {
      const nm = firstname((prof(f.requester) || {}).display_name)
      items.push({ key: 'friend:' + f.requester, tier: 'closing', band: 1000, mods: 8, mod_reason: 'M8 8 (recent)', subject: nm, human_subject: true,
        eyebrow: 'A BUDDY REQUEST', headline: `${nm} wants to be golf buddies.`, standfirst: null, action: 'Answer it',
        route: { kind: 'people', id: f.requester }, league_id: null, suppress: [], spine: 'ember', at: f.created_at })
    }
    for (const m of me.memberships) {
      const se = m.season, st = m.standing, cl = m.clash, pu = m.pulse, bi = m.buy_in
      /* the weekly clash */
      if (cl) {
        const them = cl.them_name ? firstname(cl.them_name) : 'your opponent'
        const left = cl.days_left || 0, close = !!cl.closes_today, idle = !cl.mine && !cl.theirs
        const when = close ? 'today' : left === 1 ? 'tomorrow' : `in ${left} days`
        let band, head, stand, act, route
        /* AW2-05 · 20261211100000 (root's ruling): the idle words hold on every day, the last included;
           never "both in" when neither has posted. D216's yield is the band alone. */
        if (idle) { band = left > 1 && !close ? 600 : 1000; head = `Your clash with ${them} is open.`; stand = `Best round of the week takes it. The week closes ${when}.`; act = 'Add my round'; route = { kind: 'composer' } }
        else if (cl.theirs && !cl.mine) { band = 1000; head = `${them} posted ${cl.theirs.gross != null ? cl.theirs.gross : 'a round'}${cl.theirs.played_on ? ' on ' + DOW3[dow(cl.theirs.played_on)] : ''}.`; stand = `That is the number, and the week closes ${when}.`; act = 'Add my round'; route = { kind: 'composer' } }
        else if (cl.mine && !cl.theirs) { band = 1000; head = `${them} has ${close ? 'today' : left === 1 ? 'one day' : left + ' days'} to answer your ${cl.mine.gross != null ? cl.mine.gross : 'round'}.`; stand = 'Your round is the number to beat.'; act = 'See the receipt'; route = cl.mine.round_id ? { kind: 'receipt', id: cl.mine.round_id } : { kind: 'season', id: m.league_id } }
        else { band = 1000; head = `You and ${them} are both in.`; stand = `The week closes ${when}. Best round takes it.`; act = 'See the receipt'; route = cl.mine && cl.mine.round_id ? { kind: 'receipt', id: cl.mine.round_id } : { kind: 'season', id: m.league_id } }
        const clock = Math.max(0, 30 - left * 10)
        let mods = (band === 1000 ? clock : 0) + 24
        let why = (band === 1000 ? `M1 ${clock} (the clock) + ` : '') + 'M4 24 (an opponent)'
        const up = st && st.next_up && st.next_up.name, dn = st && st.next_down && st.next_down.name
        if (up && firstname(cl.them_name) === up) { mods += 30; why += ' + M3 30 (he is the man above me)' }
        else if (dn && firstname(cl.them_name) === dn) { mods += 30; why += ' + M3 30 (she is the row below me)' }
        if (m.league_id === nearest) { mods += 5; why += ' + M11 5 (the nearest season)' }
        items.push({ key: `clash:${m.league_id}:${cl.week_no}`, tier: band === 1000 ? 'closing' : 'coming', band, mods: Math.min(99, mods), mod_reason: why,
          subject: them, human_subject: true, eyebrow: `${(cl.rivalry || m.name).toUpperCase()} · THE CLASH`,   /* AW2-05 · 20261211100000: the clock is said once, in a sentence */
          headline: head, standfirst: stand, action: act, route, league_id: m.league_id,
          suppress: cl.mine ? ['my_last_round'] : [], spine: 'ember', at: cl.ends_on })
      }
      /* the month floor: squads only, never a partial month, inside three days of the month's end */
      if (pu && m.settings.structure !== 'solo' && (pu.floor || 0) > 0 && !pu.partial && (pu.credits || 0) < (pu.floor || 0) && dd(TODAY, monthEnd(TODAY)) <= 3) {
        const [, mo] = parts(TODAY)
        items.push({ key: 'floor:' + m.league_id, tier: 'closing', band: 1000, mods: 70, mod_reason: 'M1 30 (the month) + M2 40 (me)', subject: 'you', human_subject: true,
          eyebrow: `${MONTH[mo - 1].toUpperCase()} CLOSES ${DOW3[dow(monthEnd(TODAY))].toUpperCase()}`,
          headline: `You are ${fm((pu.floor || 0) - (pu.credits || 0))} short of the minimum.`,
          standfirst: m.squad && m.squad.name ? `The ${m.squad.name} carry the penalty, not you.` : null,
          action: 'Add my round', route: { kind: 'composer' }, league_id: m.league_id, suppress: [], spine: 'ember', at: null })
      }
      /* BAND 2 · my rank moved since Sunday */
      if (st && se && se.status === 'active' && st.prev_rank != null && st.prev_rank !== st.rank) {
        items.push({ key: 'move:' + m.league_id, tier: 'changed', band: 800, mods: 60, mod_reason: 'M2 40 (me) + M8 20 (this week)', subject: 'you', human_subject: true,
          eyebrow: `${m.name.toUpperCase()} · WEEK ${se.week_no}`,
          headline: st.prev_rank > st.rank ? `You moved up ${st.prev_rank - st.rank} since Sunday.` : 'You were passed since Sunday.',
          standfirst: st.next_up && st.next_up.name ? `${st.next_up.name} is the next one up.` : null,
          action: 'See the table', route: { kind: 'season', id: m.league_id, pane: 'table' }, league_id: m.league_id, suppress: [], spine: 'gold', at: null })
      }
      /* BAND 3 · the first tee */
      if (se && se.days_to_first_tee != null) {
        const n = se.days_to_first_tee, [, mo, day] = parts(se.starts_on)
        items.push({ key: 'firsttee:' + m.league_id, tier: n <= 3 ? 'closing' : 'coming', band: n <= 3 ? 1000 : 600, mods: 14, mod_reason: 'M8 14 (a dated thing)',
          subject: m.pro_name || 'you', human_subject: true, eyebrow: `FIRST TEE ${DOW3[dow(se.starts_on)].toUpperCase()} ${MON3[mo - 1].toUpperCase()} ${day}`,
          headline: `${m.name} starts in ${n}${n === 1 ? ' day.' : ' days.'}`,
          standfirst: 'Rounds you post before then still build your number — they just do not score yet.',
          action: 'Open the season', route: { kind: 'season', id: m.league_id }, league_id: m.league_id, suppress: [], spine: 'ember', at: se.starts_on })
      }
      /* BAND 5 · the chapter */
      if (st && se && ['active', 'cup_final'].includes(se.status) && st.leader_name) {
        items.push({ key: 'chapter:' + m.league_id, tier: 'chapter', band: 200, mods: m.league_id === nearest ? 5 : 0,
          mod_reason: m.league_id === nearest ? 'M11 5 (the nearest season)' : 'none', subject: st.leader_name, human_subject: true,
          eyebrow: `${m.name.toUpperCase()} · WEEK ${se.week_no} OF ${se.weeks_total}`,
          headline: st.rank === 1 ? 'You are the one to catch.' : `${st.leader_name} is the one to catch.`,
          standfirst: (se.days_left || 0) > 0 ? `${se.days_left} days still to play.` : null,
          action: 'Open the season', route: { kind: 'season', id: m.league_id }, league_id: m.league_id, suppress: [], spine: 'mut', at: null })
      }
      /* BAND 5b / 6 · a finished season (none in this world unless a helper adds one) */
      if (m.last_season && m.last_season.champion_name && (!se || se.status !== 'active')) {
        const mineWin = m.last_season.champion_is_me === true
        items.push({ key: 'lastseason:' + m.league_id, tier: 'chapter', band: 200, mods: 0, mod_reason: 'none', subject: mineWin ? 'you' : m.last_season.champion_name, human_subject: true,
          eyebrow: `${m.name.toUpperCase()} · SEASON COMPLETE`, headline: mineWin ? 'You took the last one.' : `${m.last_season.champion_name} took the last one.`,
          standfirst: m.last_season.my_rank != null && m.last_season.of != null ? `You finished ${ordinal(m.last_season.my_rank)} of ${m.last_season.of}.` : null,
          action: 'See how it ended', route: { kind: 'season', id: m.league_id }, league_id: m.league_id, suppress: [], spine: 'gold', at: m.last_season.ended_on })
      }
      if (se && se.status === 'complete') {
        const pro = m.role === 'commissioner'
        items.push({ key: 'runitback:' + m.league_id, tier: 'opportunity', band: 100, mods: bi && bi.note ? 6 : 0, mod_reason: 'none',
          subject: pro ? 'you' : (m.pro_name || 'the Pro'), human_subject: true, eyebrow: m.name.toUpperCase(),
          headline: pro ? 'The next season starts when you say it does.' : `The next season starts when ${m.pro_name || 'the Pro'} says it does.`, standfirst: null,
          action: pro ? 'Run it back' : `Ask ${m.pro_name || 'the Pro'} to run it back`, route: { kind: 'season', id: m.league_id }, league_id: m.league_id, suppress: [], spine: 'mut', at: null })
      }
      /* v2 / D257 · the plan you need (solo seasons with a counting cap only) */
      if (st && se && se.status === 'active' && m.settings.structure === 'solo' && st.rank != null && (st.of || 0) >= 2 && m.settings.counting_cap != null && m.settings.counting_cap > 0) {
        const cap = m.settings.counting_cap
        const inMonth = T.v_rounds_ranked.filter((x) => x.member_id === m.member_id && x.season_id === se.id && monthStart(x.played_on) === monthStart(TODAY) && x.month_rank <= cap)
        const used = inMonth.length, worst = used ? Math.min(...inMonth.map((x) => x.points)) : null
        const gain = used < cap ? 12 : (worst != null ? 12 - worst : null)          /* round_worth: a top-band round against the slot it would take */
        if (used < cap && gain != null && gain > 0) {
          const wkl = Math.max(0, (se.weeks_total || 0) - (se.week_no || 0))
          const when2 = wkl === 0 ? 'in the last week' : wkl === 1 ? 'with one week left' : `with ${wkl} weeks left`
          let head = null, sub = null, who = null
          if (st.rank > 1 && st.next_up && st.next_up.name && st.gap_to_next != null && st.gap_to_next > 0 && gain >= st.gap_to_next) {
            who = firstname(st.next_up.name); head = `You are ${fm(st.gap_to_next)} back of ${who} ${when2}.`
            sub = `One counting round in the top band closes it — your best ${cap} count this month and you have ${used}.`
          } else if (st.rank === 1 && st.next_down && st.next_down.name && st.next_down.points != null) {
            const gap = (st.points || 0) - st.next_down.points
            if (gap > 0 && gap <= 12) { who = firstname(st.next_down.name); head = `You are ${fm(gap)} clear of ${who} ${when2}.`; sub = `One more counting round is worth up to ${fm(gain)} — your best ${cap} count this month and you have ${used}.` }
          }
          if (head) items.push({ key: 'need:' + m.league_id, tier: 'coming', band: 600, mods: 70, mod_reason: 'M2 40 (me) + M3 30 (the row beside me)', subject: who, human_subject: true,
            eyebrow: `${m.name.toUpperCase()} · WEEK ${se.week_no}`, headline: head, standfirst: sub, action: 'Put a round on the schedule',
            route: { kind: 'declare' }, league_id: m.league_id, suppress: [], spine: 'mut', at: se.week_ends_on })
        }
      }
    }
    /* BAND 3 · a plan on the sheet (the ME strip owns NEXT, so no time twice) */
    for (const e of me.upcoming_rounds) {
      if ((e.my_rsvp || '') === 'out' || !(e.mine || e.tagged_me) || !e.play_on) continue
      const d = dd(TODAY, e.play_on); if (d < 0 || d > 8) continue
      const who = firstname(e.display_name), inN = Math.max(0, Number(e.rsvp_in || 0))
      const [, mo, day] = parts(e.play_on)
      const word = d === 0 ? 'today' : d === 1 ? 'tomorrow' : d <= 6 ? DAY[dow(e.play_on)] : `${MON3[mo - 1]} ${day}`
      const tee = e.tee_time ? (() => { const [h, mi] = String(e.tee_time).split(':').map(Number); return `${((h + 11) % 12) + 1}:${String(mi).padStart(2, '0')} tee` })() : null
      const sf = [tee, inN > 1 ? `${inN} of you in` : null].filter(Boolean).join(' · ')
      items.push({ key: 'plan:' + e.id, tier: d <= 3 ? 'closing' : 'coming', band: d <= 3 ? 1000 : 600, mods: Math.min(99, Math.max(0, 20 - d * 2) + 12),
        mod_reason: `M8 ${Math.max(0, 20 - d * 2)} (a dated thing) + M6 12 (a buddy)`, subject: e.mine ? 'you' : who, human_subject: true,
        eyebrow: DOW3[dow(e.play_on)].toUpperCase() + (e.course_label ? ' · ' + String(e.course_label).toUpperCase() : ''),
        headline: e.mine ? `You have a round ${['today', 'tomorrow'].includes(word) ? word : 'on ' + word}.` : `${who} has you down for ${word}.`,
        standfirst: sf ? sf + '.' : null, action: e.my_rsvp ? 'Open the plan' : 'Say you\'re in', route: { kind: 'plan', id: e.id },
        league_id: null, suppress: [], spine: 'ember', at: e.play_on })
    }
    /* BAND 3b · after the golf (D345; only for a client that names afterplan.v1) */
    if (args.p_today && caps.includes('afterplan.v1')) {
      const seen = new Set()
      const plans = (T.scheduled_rounds || []).filter((sr) => sr.play_on >= addDays(TODAY, -3) && sr.play_on <= addDays(TODAY, -1)
        && (sr.profile_id === ME || (sr.tagged || []).includes(ME))
        && !(T.round_rsvp || []).some((x) => x.round_id === sr.id && x.profile_id === ME && x.status === 'out')
        && !(T.plan_followups || []).some((f) => f.scheduled_round_id === sr.id && f.profile_id === ME && (f.answer === 'didnt_play' || (f.snooze_until || TODAY) > TODAY))
        && !rounds().some((rd) => rd.profile_id === ME && rd.played_on === sr.play_on && (sr.course_id == null || rd.api_course_id == null || String(rd.api_course_id) === String(sr.course_id))))
        .sort((a, b) => b.play_on.localeCompare(a.play_on) || String(a.tee_time || '99').localeCompare(String(b.tee_time || '99')))
      for (const sr of plans) {
        if (seen.has(sr.play_on)) continue; seen.add(sr.play_on)
        const ago = dd(sr.play_on, TODAY), dw = ago === 1 ? 'yesterday' : DAY[dow(sr.play_on)]
        items.push({ key: 'afterplan:' + sr.id, tier: 'changed', band: 800, mods: Math.max(0, 8 - ago * 2), mod_reason: `M8 ${Math.max(0, 8 - ago * 2)} (a dated thing)`,
          subject: 'you', human_subject: true, eyebrow: DOW3[dow(sr.play_on)].toUpperCase() + (sr.course_label ? ' · ' + sr.course_label.toUpperCase() : ''),
          headline: sr.profile_id === ME ? `You planned a round for ${dw}.` : `${firstname((prof(sr.profile_id) || {}).display_name) || 'A golfer'} had you on the plan for ${dw}.`,
          standfirst: 'Nothing posted yet.', action: 'Add my round', route: { kind: 'composer' },
          context: { plan_id: sr.id, play_on: sr.play_on, course_label: sr.course_label || null, course_id: sr.course_id || null, tee_time: sr.tee_time || null },
          league_id: null, suppress: [], spine: 'ember', at: sr.play_on })
      }
    }
    /* BAND 4 · the circle: one item, the freshest round that is not mine */
    const s = homeStories(days).filter((x) => !x.is_me && x.gross != null).sort((a, b) => b.created_at.localeCompare(a.created_at))[0]
    if (s) {
      const g = firstname(s.golfer)
      items.push({ key: 'story:' + s.round_id, tier: 'circle', band: 400, mods: 12, mod_reason: 'M6 12 (a buddy)', subject: g, human_subject: true,
        eyebrow: 'AROUND YOUR BUDDIES', headline: `${g} posted ${s.gross}${s.course ? ' at ' + s.course : ''}.`,
        standfirst: s.is_pr ? 'A personal best.' : s.is_sub80 ? 'Under 80 for the first time.' : s.is_first ? 'Their first posted round.'
          : !s.has_rating ? 'No rating on that one, so it builds a number and nothing else.' : null,
        action: 'See the round', route: { kind: 'receipt', id: s.round_id }, league_id: null, suppress: [],
        spine: s.is_pr || s.is_sub80 ? 'gold' : 'mut', at: s.created_at })
    }
    /* BAND 6 · the door worth walking through, on a real shape only */
    if (nRounds === 0) {
      items.push({ key: 'first_round', tier: 'opportunity', band: 100, mods: 40, mod_reason: 'M2 40 (me)', subject: 'you', human_subject: true,
        eyebrow: 'NEW HERE', headline: 'Your first round is the only thing missing.',
        standfirst: 'Add one you already played — course, score, done. Your number starts building at three.',
        action: 'Add my round', route: { kind: 'composer' }, league_id: null, suppress: [], spine: 'ember', at: null })
    } else if (nFriends === 0) {
      /* the server's own string: "1 ROUNDS IN" for one round is what it prints */
      items.push({ key: 'find_golfers', tier: 'opportunity', band: 100, mods: 40, mod_reason: 'M2 40 (me)', subject: 'you', human_subject: true,
        eyebrow: `${nRounds} ROUNDS IN`, headline: 'Your number is yours, and nobody has seen it.',
        standfirst: 'The golfers you already play with are the ones worth adding.',
        action: 'Find golfers', route: { kind: 'people' }, league_id: null, suppress: [], spine: 'mut', at: null })
    }
    /* G1 the fence · score order · G2 the veto · G5 the cap */
    const live = items.filter((x) => x.route && x.route.kind)
      .sort((a, b) => (b.band + b.mods) - (a.band + a.mods) || String(b.at || '').localeCompare(String(a.at || '')) || a.key.localeCompare(b.key))
    const B = { closing: '1', changed: '2', coming: '3', circle: '4', chapter: '5' }
    const reason = (e) => `B${B[e.tier] || '6'} ${e.band} + ${e.mods} (${e.mod_reason || 'none'}) = ${e.band + e.mods}`
    const out = []
    const li = live.findIndex((x) => x.human_subject)
    let sup = []
    if (li >= 0) { const e = live[li]; sup = e.suppress || []; out.push({ ...e, rank: 1, score: e.band + e.mods, rank_reason: reason(e) + ' · lead (the veto is satisfied)' }) }
    for (const e of live) {
      if (out.length >= 5) break
      if (out.some((o) => o.key === e.key)) continue
      out.push({ ...e, rank: out.length + 1, score: e.band + e.mods, rank_reason: reason(e) })
    }
    return { me, items: out, lead_suppress: sup, generated_at: W.now }
  }

  /* ------------------------------------------------------ notifications */
  /* 20261207090000_the_round_keeps_its_conversation.sql. One unread
     'own_round' note: Devon's comment on my round (the world's board comment
     on that round's post, which is a row of the round's one conversation). */
  const myRoundPost = graphOn ? T.posts.find((p) => p.kind === 'round' && p.profile_id === ME && (T.post_comments || []).some((c) => c.post_id === p.id)) : null
  const cmt = myRoundPost ? T.post_comments.find((c) => c.post_id === myRoundPost.id) : null
  T.social_notifications = !cmt ? [] : [{
    id: nid(1), recipient: ME, actor: (T.league_members.find((m) => m.id === cmt.member_id) || {}).profile_id, kind: 'own_round',
    round_id: myRoundPost.round_id, comment_id: cmt.id, created_at: cmt.created_at, read_at: null,
  }]
  const liveNotes = () => T.social_notifications.filter((n) => n.recipient === ME && liveProfile(n.actor) && !muted(ME, n.actor) && roundById(n.round_id))
  const unread = () => liveNotes().filter((n) => !n.read_at).length
  function myNotifications(args) {
    const lim = Math.min(Math.max(Number(args.p_limit) || 30, 1), 50)
    let list = liveNotes().sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id))
    if (args.p_before) list = list.filter((n) => n.created_at < args.p_before || (args.p_before_id && n.created_at === args.p_before && n.id < args.p_before_id))
    const page = list.slice(0, lim), more = list.length > lim
    return { ok: true, unread: unread(), items: page.map((n) => {
      const r = roundById(n.round_id), c = (T.post_comments || []).find((x) => x.id === n.comment_id) || {}
      return { id: n.id, kind: n.kind, created_at: n.created_at, read: !!n.read_at, read_at: n.read_at, actor: person(n.actor),
        round_id: n.round_id, comment_id: n.comment_id, excerpt: c.body ? String(c.body).slice(0, 140) : null, course_name: courseName(r),
        round_owner_name: (prof(r.profile_id) || {}).display_name || null,
        link: { kind: 'round_comment', round_id: n.round_id, comment_id: n.comment_id, web: `/?round=${n.round_id}&comment=${n.comment_id}` } }
    }), next_before: more ? page[page.length - 1].created_at : null, next_before_id: more ? page[page.length - 1].id : null }
  }

  /* -------------------------------------------------- posted_rounds_social */
  /* 20261208090000_a_course_keeps_its_circle.sql */
  function threadCount(roundId) {
    const myLeagues = new Set(myMemberships().map((m) => m.league_id))
    const own = (T.post_comments || []).filter((c) => c.round_id === roundId && !c.post_id && !c.hidden_at)
    const board = (T.post_comments || []).filter((c) => { const p = T.posts.find((x) => x.id === c.post_id); return p && p.round_id === roundId && !p.hidden_at && !c.hidden_at && p.league_id && myLeagues.has(p.league_id) })
    const author = (c) => c.profile_id || (T.league_members.find((m) => m.id === c.member_id) || {}).profile_id
    return own.concat(board).filter((c) => liveProfile(author(c)) && !muted(ME, author(c))).length
  }
  function postedRoundsSocial(args) {
    const ids = [...new Set((args.p_rounds || []).map(String))].slice(0, 60)
    const circ = circle(ME)
    const vis = ids.map(roundById).filter((r) => r && !r.voided && liveProfile(r.profile_id) && (r.profile_id === ME || (circ.has(r.profile_id) && !muted(ME, r.profile_id))))
    return { items: vis.map((r) => {
      let course = null
      if (r.api_course_id != null) {
        const at = new Map()
        for (const x of rounds().filter((y) => String(y.api_course_id) === String(r.api_course_id) && circ.has(y.profile_id) && liveProfile(y.profile_id) && (y.profile_id === ME || !muted(ME, y.profile_id)))) {
          const cur = at.get(x.profile_id); if (!cur || x.played_on > cur.last_on) at.set(x.profile_id, { pid: x.profile_id, last_on: x.played_on, rel: circ.get(x.profile_id) })
        }
        const faces = [...at.values()].filter((a) => a.pid !== ME)
          .sort((a, b) => ((b.rel === 'friend') - (a.rel === 'friend')) || b.last_on.localeCompare(a.last_on) || a.pid.localeCompare(b.pid)).slice(0, 3).map((a) => person(a.pid))
        course = { api_course_id: r.api_course_id, name: courseName(r), circle_golfers: at.size, faces }
      }
      return { round_id: r.id, comment_count: threadCount(r.id), can_comment: true, thread_state: 'none', course }
    }) }
  }

  /* ---------------------------------------------------------- my_friends */
  /* 20260715210000_former_member_gone.sql */
  function myFriends() {
    return T.friendships.filter((f) => f.requester === ME || f.addressee === ME).map((f) => {
      const p = liveProfile(f.requester === ME ? f.addressee : f.requester); if (!p) return null
      return { friendship_id: f.id, profile_id: p.id, handle: p.handle, display_name: p.display_name, city: p.city, marker: p.marker,
        index_current: p.index_current, status: f.status, incoming: f.addressee === ME }
    }).filter(Boolean).sort((a, b) => ((b.status === 'pending') - (a.status === 'pending')) || a.display_name.localeCompare(b.display_name))
  }

  /* -------------------------------------------------------- friends_board */
  /* 20260917090000_the_record_between_two_golfers.sql (R5) */
  function friendsBoard(args) {
    const days = Math.max(Number(args.p_days) || 30, 1)
    const from = addDays(TODAY, -days)
    const ids = [ME, ...friendsOf(ME)]
    const rows = ids.map(liveProfile).filter(Boolean).map((p) => {
      const mine = rounds().filter((r) => r.profile_id === p.id)
      const inWin = mine.filter((r) => r.differential != null && r.index_at_post != null && r.played_on >= from)
      const figs = inWin.map((r) => r.index_at_post - r.differential)
      const last = mine.map((r) => r.played_on).sort().pop() || null
      return { profile_id: p.id, display_name: p.display_name, handle: p.handle, marker: p.marker, index_current: p.index_current,
        rounds_30d: inWin.length, beats_30d: figs.filter((x) => x >= 1).length,
        avg_vs_number_30d: figs.length ? r1(figs.reduce((a, x) => a + x, 0) / figs.length) : null,
        best_vs_number_30d: figs.length ? r1(Math.max(...figs)) : null, last_round_on: last, is_me: p.id === ME }
    })
    const rankBy = (cmp) => { const s = rows.slice().sort(cmp); return (r) => { const i = s.findIndex((x) => cmp(x, r) === 0); return i + 1 } }
    const form = (a, b) => b.beats_30d - a.beats_30d || b.rounds_30d - a.rounds_30d || ((b.avg_vs_number_30d ?? -1e9) - (a.avg_vs_number_30d ?? -1e9)) || a.display_name.localeCompare(b.display_name)
    const idx = (a, b) => ((a.index_current ?? 1e9) - (b.index_current ?? 1e9)) || a.display_name.localeCompare(b.display_name)
    const rf = rankBy(form), ri = rankBy(idx)
    return rows.map((r) => ({ ...r, rank_by_form: rf(r), rank_by_index: ri(r) })).sort((a, b) => a.rank_by_form - b.rank_by_form || a.display_name.localeCompare(b.display_name))
      .map(({ is_me, ...r }) => ({ ...r, is_me }))
  }

  /* ------------------------------------------- rivalries and the record */
  const sharedSeasons = (opp) => {
    const out = new Set()
    for (const lm of myMemberships()) if (membersOf(lm.league_id).some((m) => m.profile_id === opp && opp !== ME)) for (const s of T.seasons.filter((x) => x.league_id === lm.league_id)) out.add(s.id)
    return out
  }
  const weekly = (profileId, seasons) => {
    const m = new Map()
    for (const x of T.v_rounds_ranked.filter((y) => y.profile_id === profileId && (!seasons || seasons.has(y.season_id)))) {
      const k = x.season_id + '|' + weekOf(x.played_on)
      m.set(k, Math.max(m.has(k) ? m.get(k) : -1e9, x.pvi))
    }
    return m
  }
  const rivalryName = (opp) => { const [lo, hi] = [ME, opp].sort(); const r = T.rivalry_names.find((x) => x.pair_low === lo && x.pair_high === hi); return r ? r.name : null }
  /* my_rivalries: 20260716210000_named_rivalries.sql */
  function myRivalries() {
    const opps = [...new Set(myMemberships().flatMap((lm) => membersOf(lm.league_id).map((m) => m.profile_id)))].filter((p) => p !== ME)
    const mine = weekly(ME)
    const out = []
    for (const opp of opps) {
      const ss = sharedSeasons(opp)
      const theirs = weekly(opp, ss)
      const byWk = new Map()
      for (const [k, op] of theirs) { if (!mine.has(k)) continue; const wk = k.split('|')[1]; const cur = byWk.get(wk) || { my: -1e9, op: -1e9 }; byWk.set(wk, { my: Math.max(cur.my, mine.get(k)), op: Math.max(cur.op, op) }) }
      let w = 0, l = 0, t = 0
      for (const x of byWk.values()) { if (x.my > x.op) w++; else if (x.my < x.op) l++; else t++ }
      if (w + l + t < 1) continue
      const p = liveProfile(opp); if (!p) continue
      out.push({ opponent: opp, display_name: p.display_name, handle: p.handle, marker: p.marker, wins: w, losses: l, ties: t, meetings: w + l + t,
        lead: w > l ? 'up' : w < l ? 'down' : 'even', duel_wins: 0, duel_losses: 0, duel_halves: 0, rivalry_name: rivalryName(opp) })
    }
    return out.sort((a, b) => b.meetings - a.meetings || b.wins - a.wins || a.display_name.localeCompare(b.display_name))
  }
  /* rivalry_weeks: 20260716010000_rivalries.sql */
  function rivalryWeeks(args) {
    const opp = args.p_opponent, ss = sharedSeasons(opp)
    const byWk = (pid) => { const m = new Map(); for (const x of T.v_rounds_ranked.filter((y) => y.profile_id === pid && ss.has(y.season_id))) { const k = weekOf(x.played_on); m.set(k, Math.max(m.has(k) ? m.get(k) : -1e9, x.pvi)) } return m }
    const m = byWk(ME), o = byWk(opp)
    return [...m.keys()].filter((k) => o.has(k)).sort().reverse().map((wk) => ({ wk, my_pvi: m.get(wk), opp_pvi: o.get(wk),
      winner: m.get(wk) > o.get(wk) ? 'me' : m.get(wk) < o.get(wk) ? 'them' : 'halve' }))
  }
  /* head_to_head: 20260917090000_the_record_between_two_golfers.sql (R4) */
  const BASIS = {
    season_weeks: { basis: 'the better round against your playing HCP in a week you both posted', source: 'v_rounds_ranked' },
    clashes: { basis: 'the weekly clash the season opened and settled', source: 'week_clashes' },
    played_together: { basis: 'the better card against your playing HCP on a day you were both out', source: 'round_players' },
    live_games: { basis: 'the better card against your playing HCP in a round you both scored live', source: 'live_rounds' },
    duels: { basis: 'a Ryder clash, settled', source: 'event_duels' },
    callouts: { basis: 'a head-to-head with a field of two', source: 'event_duels' },
  }
  function headToHead(args) {
    const opp = args.p_opponent
    if (!opp || opp === ME || !cardVisible(ME, opp)) return { visible: false }
    const op = liveProfile(opp); if (!op) return { visible: false }
    const leagueNames = myMemberships().filter((lm) => membersOf(lm.league_id).some((m) => m.profile_id === opp)).map((lm) => leagueOf(lm.league_id).name).sort()
    const ss = sharedSeasons(opp)
    const meetings = []
    /* facet 1 · season weeks — W7-002 (20261212090000): a week both posted is
       ONE meeting, however many seasons the two share; each golfer's figure is
       their best across those seasons, as myRivalries collapses them above */
    const perWeek = (m) => { const out = new Map(); for (const [k, v] of m) { const wk = k.split('|')[1]; out.set(wk, Math.max(out.has(wk) ? out.get(wk) : -1e9, v)) } return out }
    const wm = perWeek(weekly(ME, ss)), wo = perWeek(weekly(opp, ss))
    for (const [wk, mp] of wm) if (wo.has(wk)) { const o = wo.get(wk); meetings.push({ on: wk, settled: true, won: mp > o ? true : mp < o ? false : null, facet: 'season_weeks', heuristic: false, confirmed: true }) }
    /* facet 2 · settled clashes */
    const memIds = new Map(T.league_members.filter((m) => m.profile_id === ME || m.profile_id === opp).map((m) => [m.id, m.profile_id]))
    for (const c of (T.week_clashes || []).filter((x) => x.settled_at && memIds.has(x.a_member) && memIds.has(x.b_member) && memIds.get(x.a_member) !== memIds.get(x.b_member))) {
      meetings.push({ on: String(c.opened_at).slice(0, 10), settled: true, won: c.winner_member == null ? null : memIds.get(c.winner_member) === ME, facet: 'clashes', heuristic: false, confirmed: true })
    }
    /* facet 3 · played together: no tags exist in this world; the same-day/same-course heuristic, labelled */
    const mineR = rounds().filter((r) => r.profile_id === ME), oppR = rounds().filter((r) => r.profile_id === opp)
    const days = [...new Set(mineR.filter((a) => courseKey(a) && oppR.some((b) => b.played_on === a.played_on && courseKey(b) === courseKey(a))).map((a) => a.played_on))]
    for (const d of days) {
      const fig = (list) => { const v = list.filter((r) => r.played_on === d && r.differential != null && r.index_at_post != null).map((r) => r.index_at_post - r.differential); return v.length ? Math.max(...v) : null }
      const a = fig(mineR), b = fig(oppR)
      meetings.push({ on: d, settled: a != null && b != null, won: a == null || b == null ? null : a > b ? true : a < b ? false : null, facet: 'played_together', heuristic: true, confirmed: false })
    }
    meetings.sort((a, b) => b.on.localeCompare(a.on))
    const facets = {}
    for (const f of Object.keys(BASIS)) {
      const ms = meetings.filter((m) => m.facet === f); if (!ms.length) continue
      facets[f] = { wins: ms.filter((m) => m.settled && m.won === true).length, losses: ms.filter((m) => m.settled && m.won === false).length,
        ties: ms.filter((m) => m.settled && m.won === null).length, meetings: ms.length, unsettled: ms.filter((m) => !m.settled).length,
        confirmed: ms.filter((m) => m.confirmed && !m.heuristic).length, unconfirmed: ms.filter((m) => !m.confirmed && !m.heuristic).length,
        heuristic: ms.filter((m) => m.heuristic).length, first_on: ms.map((m) => m.on).sort()[0], last_on: ms.map((m) => m.on).sort().pop(), ...BASIS[f] }
    }
    const settled = meetings.filter((m) => m.settled)
    const w = settled.filter((m) => m.won === true).length, l = settled.filter((m) => m.won === false).length, t = settled.filter((m) => m.won === null).length
    const decided = settled.filter((m) => m.won !== null)
    let streak = null
    if (decided.length) { let n = 0; for (const m of decided) { if (m.won === decided[0].won) n++; else break } if (n >= 2) streak = { who: decided[0].won ? 'me' : 'them', n } }
    return { visible: true, opponent: { id: op.id, display_name: op.display_name, handle: op.handle, marker: op.marker }, league: leagueNames[0] || null,
      record: { wins: w, losses: l, ties: t, total: meetings.length }, lead: w > l ? 'up' : w < l ? 'down' : 'even',
      since: meetings.length ? meetings.map((m) => m.on).sort()[0] : null, streak,
      last_five: settled.slice(0, 5).map((m) => ({ on: m.on, won: m.won, facet: m.facet })), rivalry_name: rivalryName(opp), facets }
  }

  /* --------------------------------------------------------- search_golfers */
  /* 20261210090000_reach_needs_a_relationship.sql */
  function searchGolfers(args) {
    const q = String(args.p_q || '').trim()
    if (q.length < 2) return []
    const needle = q.replace('@', '').toLowerCase()
    const circ = circle(ME)
    return T.profiles.filter((p) => p.id !== ME && !p.deleted_at && p.handle
      && (p.handle.toLowerCase().includes(needle) || p.display_name.toLowerCase().includes(q.toLowerCase())) && discoverable(p))
      .map((p) => {
        const f = T.friendships.find((x) => (x.requester === p.id && x.addressee === ME) || (x.requester === ME && x.addressee === p.id))
        const known = circ.has(p.id) || (f && f.status === 'pending' && f.addressee === ME)
        const rel = !f ? 'none' : f.status === 'accepted' ? 'friend' : f.requester === ME ? 'requested' : 'incoming'
        return { p, rel, known, row: { profile_id: p.id, handle: p.handle, display_name: p.display_name, city: known ? p.city : null,
          home_course: known ? p.home_course : null, marker: p.marker, index_current: known ? p.index_current : null, rel } }
      })
      .sort((a, b) => ((b.rel === 'friend') - (a.rel === 'friend')) || (shareLeague(ME, b.p.id) - shareLeague(ME, a.p.id))
        || (b.p.handle.toLowerCase().startsWith(needle) - a.p.handle.toLowerCase().startsWith(needle)) || a.p.display_name.localeCompare(b.p.display_name))
      .slice(0, 10).map((x) => x.row)
  }

  /* ------------------------------------------------------------ tour_card */
  /* 20261019090000_the_card_knows_where_it_has_been.sql */
  function tourCard(args) {
    const t = args.p_profile
    if (!t || !cardVisible(ME, t)) return { visible: false }
    const p = liveProfile(t); if (!p) return { visible: false }
    const mine = rounds().filter((r) => r.profile_id === t)
    const withDiff = mine.filter((r) => r.differential != null)
    const lens = lensOf(t)
    const career = { rounds: withDiff.length, best: withDiff.length ? Math.min(...withDiff.map((r) => r.differential)) : null,
      avg_vs_index: withDiff.filter((r) => r.index_at_post != null).length ? r1(withDiff.filter((r) => r.index_at_post != null).reduce((a, r) => a + (r.index_at_post - r.differential), 0) / withDiff.filter((r) => r.index_at_post != null).length) : null,
      avg_pvi: lens.length ? r1(lens.reduce((a, x) => a + x.pvi, 0) / lens.length) : null, best_pvi: lens.length ? Math.max(...lens.map((x) => x.pvi)) : null }
    const best = mine.filter((r) => r.gross != null && (r.holes_played || 18) === 18).sort((a, b) => a.gross - b.gross || b.played_on.localeCompare(a.played_on))[0]
    if (best) career.best_round = { gross: best.gross, course_label: best.course_label || null, played_on: best.played_on, differential: best.differential }
    const recent = mine.slice().sort((a, b) => b.played_on.localeCompare(a.played_on) || b.created_at.localeCompare(a.created_at)).slice(0, 5)
      .map((r) => ({ played_on: r.played_on, course_label: r.course_label, gross: r.gross, differential: r.differential, holes_played: r.holes_played,
        beat: r.differential != null && r.index_at_post != null ? (r.index_at_post - r.differential) >= 1 : null }))
    let vs = null
    if (t !== ME) {
      const ss = sharedSeasons(t)
      const wk = (pid) => { const m = new Map(); for (const x of T.v_rounds_ranked.filter((y) => y.profile_id === pid && ss.has(y.season_id))) { const k = weekOf(x.played_on); m.set(k, Math.max(m.has(k) ? m.get(k) : -1e9, x.pvi)) } return m }
      const a = wk(ME), b = wk(t); let w = 0, l = 0, ti = 0
      for (const [k, mp] of a) if (b.has(k)) { const o = b.get(k); if (mp > o) w++; else if (mp < o) l++; else ti++ }
      vs = { wins: w, losses: l, ties: ti }
    }
    const group = (list) => { const m = new Map(); for (const r of list) { const k = courseKey(r); if (!k) continue; const g = m.get(k) || { name: courseName(r), n: 0, last: null, cid: r.api_course_id }; g.n++; if (!g.last || r.played_on > g.last) g.last = r.played_on; m.set(k, g) } return m }
    const cg = group(withDiff)
    const courses = [...cg.values()].sort((a, b) => b.n - a.n || a.name.localeCompare(b.name)).map((g) => ({ name: g.name, rounds: g.n, last_played: g.last, api_course_id: g.cid }))
    let shared = []
    if (t !== ME) {
      const a = group(rounds().filter((r) => r.profile_id === ME)), b = group(mine)
      shared = [...a.entries()].filter(([k]) => b.has(k)).map(([k, g]) => ({ name: b.get(k).name || g.name, mine: g.n, theirs: b.get(k).n }))
        .sort((x, y) => y.theirs - x.theirs || x.name.localeCompare(y.name))
    }
    return { visible: true, profile: { id: p.id, display_name: p.display_name, handle: p.handle, marker: p.marker, city: p.city, home_course: p.home_course,
      index_current: p.index_current, member_since: p.created_at, is_me: p.id === ME }, career, trophies: [], case: [], recent, vs_you: vs, courses, shared_courses: shared }
  }

  /* --------------------------------------------------------------- bag_of */
  /* 20261006090000_whats_in_the_bag.sql. Avery keeps a bag with one recent
     change, so the "since" line has rounds behind it; nobody else has a bag. */
  T.bag_items = !(signedIn && carded) ? [] : [
    ['club', 'Driver', 'Fixture Driver 10.5°', '2026-09-10', true],
    ['club', '3 wood', 'Fixture 3-wood 15°', '2026-03-01', true],
    ['club', 'Hybrid', 'Fixture 4-hybrid 22°', '2026-03-01', true],
    ['club', 'Irons', 'Fixture irons 5–PW', '2026-03-01', true],
    ['club', 'Wedge', 'Fixture wedge 52°', '2026-03-01', true],
    ['club', 'Wedge', 'Fixture wedge 58°', '2026-03-01', true],
    ['club', 'Putter', 'Fixture blade putter', '2026-03-01', true],
    ['ball', null, 'Fixture Tour ball', '2026-03-01', true],
    ['club', 'Driver', 'Fixture Driver 9° (retired)', '2026-03-01', false, '2026-09-10'],
  ].map(([kind, slot, label, added, inBag, removed], i) => ({ id: bid(i + 1), profile_id: ME, kind, slot, label, added_on: added, in_bag: inBag,
    removed_on: removed || null, position: i, created_at: `${added}T12:00:00-07:00` }))
  function bagOf(args) {
    const t = args.p_profile || ME
    if (!signedIn || !t || !liveProfile(t) || !cardVisible(ME, t)) return { visible: false }
    const items = T.bag_items.filter((b) => b.profile_id === t)
    const clubs = items.filter((b) => b.kind === 'club' && b.in_bag).sort((a, b) => a.position - b.position).map((b) => ({ id: b.id, slot: b.slot, label: b.label, added_on: b.added_on }))
    const side = items.filter((b) => b.kind === 'club' && !b.in_bag).sort((a, b) => String(b.removed_on || '').localeCompare(String(a.removed_on || '')) || a.position - b.position)
      .map((b) => ({ id: b.id, slot: b.slot, label: b.label, added_on: b.added_on, removed_on: b.removed_on }))
    const ball = items.find((b) => b.kind === 'ball' && b.in_bag)
    let since = null
    const newest = items.filter((b) => b.kind === 'club' && b.in_bag && b.added_on).sort((a, b) => b.added_on.localeCompare(a.added_on) || b.created_at.localeCompare(a.created_at))[0]
    if (newest) {
      const prior = items.filter((b) => b.in_bag && b.added_on && b.id !== newest.id).map((b) => b.added_on).sort()[0]
      if (prior && prior < newest.added_on) {
        const n = rounds().filter((r) => r.profile_id === t && r.played_on >= newest.added_on).length
        const lens = lensOf(t).filter((x) => x.played_on >= newest.added_on)
        if (n > 0) since = { id: newest.id, slot: newest.slot, label: newest.label, added_on: newest.added_on, rounds: n, beat: lens.length ? lens.filter((x) => x.pvi >= 1).length : null }
      }
    }
    return { visible: true, is_me: t === ME, profile_id: t, clubs, sideline: side, ball: ball ? { id: ball.id, label: ball.label, added_on: ball.added_on } : null, since }
  }

  /* ------------------------------------------------------------- handlers */
  const guard = (fn, empty) => (args, w) => (signedIn ? fn(args || {}, w) : empty)
  return {
    home_dispatch: (args) => signedIn ? homeDispatch(args || {}) : { me: null, items: [], generated_at: W.now },
    home_clash: guard((a) => homeClash(a.p_league), null),
    home_feed: guard((a) => homeFeed(Number(a.p_days) || 21), []),
    league_pulse: guard((a) => leaguePulse(a.p_league), []),
    my_invites: guard(() => myInvites(), []),
    notification_badge: guard(() => ({ unread: unread() }), { unread: 0 }),
    my_notifications: (args) => signedIn ? myNotifications(args || {}) : { ok: false, reason: 'signed_out' },
    /* a write: nothing is persisted between captures, so this answers what the
       server would say after marking the rows read, and leaves the world as it was */
    mark_notifications_read: guard((a) => ({ ok: true, unread: a.p_all ? 0 : Math.max(0, unread() - liveNotes().filter((n) => !n.read_at && (a.p_ids || []).includes(n.id)).length) }), null),
    social_notify_prefs: guard(() => ({ own_round: true, replies: true, followed: true }), null),
    my_friends: guard(() => myFriends(), []),
    friends_board: guard((a) => friendsBoard(a), []),
    my_rivalries: guard(() => myRivalries(), []),
    head_to_head: guard((a) => headToHead(a), { visible: false }),
    rivalry_weeks: guard((a) => rivalryWeeks(a), []),
    search_golfers: guard((a) => searchGolfers(a), []),
    /* no live round in this world, so nobody has been seated beside me */
    recent_partners: guard(() => [], []),
    /* the reunion whisper needs three shared cards a year or more back: none here */
    last_round_with: guard(() => [], []),
    posted_rounds_social: guard((a) => postedRoundsSocial(a), { items: [] }),
    founder_id: () => null,
    my_mutes: guard(() => T.mutes.filter((m) => m.muter === ME).map((m) => m.muted), []),
    tour_card: guard((a) => tourCard(a), { visible: false }),
    bag_of: guard((a) => bagOf(a), { visible: false }),
  }
}
