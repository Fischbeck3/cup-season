/* Cup Season · ten-capture fixtures, WX-D: LINKS · SETUP · SCHEDULE · COURSES · SETTINGS.
 *
 * The answers behind the signed-out landings (/?share=, /?claim=, /?join=,
 * /?p=, /?plan=), the covenant, the schedule and its plans, the kept-course
 * record and the course search, and the settings sheet's reads. Every shape
 * is the one the latest migration returns (cited per function below), and
 * every value is derived from the synthetic world (tests/fixtures/ten/world.mjs
 * and cast.mjs) where the world holds it: a golfer's name is their profile's,
 * a band is the band table's, a course card is the api_* cache's.
 *
 * TWO KINDS OF HANDLER. Functions this module owns are defined outright. A
 * function another module may own (the social and home reads a desk or a sheet
 * of mine happens to touch) is FILLED only when nothing before this module
 * answered it (or only 00-defaults' honest-empty placeholder did), so loading
 * last never overrides a sibling's richer fixture. A handful WRAP the previous
 * handler and add only what one of my states switches on with a world flag.
 *
 * World flags this module reads (a state sets them with `world: { flags }`):
 *   scheduleEmpty · my_schedule answers [] (the empty calendar)
 *   invite        · my_invites carries Blake's invitation to North Grove
 *   brokenPhotos  · (world.mjs) every storage object answers 404
 *
 * Nothing here returns an error: a state that needs the server's raise (a dead
 * claim token) injects it with `world.errors.rpc`, as the harness requires. */
import { SHARE, CLAIM, JOIN, INVITE, PLAN, COURSE, tok } from '../links-setup/ids.mjs'

const PLACEHOLDER = /^\(\)\s*=>\s*(\[\]|null|0)$/

export default function install(W) {
  const T = W.tables
  const { uid, lid, mid, sid } = W.ids
  const ME = W.me
  const V = W.V || {}
  const out = {}
  const prev = (k) => W.handlers[k]
  const absent = (k) => { const f = W.handlers[k]; return typeof f !== 'function' || PLACEHOLDER.test(String(f).trim()) }
  const fill = (k, fn) => { if (absent(k)) out[k] = fn }

  /* ------------------------------------------------------------ helpers */
  const prof = (id) => T.profiles.find((p) => p.id === id) || null
  const firstname = (s) => String(s || '').trim().split(/\s+/)[0] || null
  const course = (id) => T.api_courses.find((c) => String(c.id) === String(id)) || null
  const teesOf = (cid) => T.api_course_tees.filter((t) => String(t.course_id) === String(cid))
  const holesOf = (teeId) => T.api_course_holes.filter((h) => h.tee_id === teeId).sort((a, b) => a.hole_number - b.hole_number)
  const parTotal = (t) => holesOf(t.id).reduce((a, h) => a + (h.par || 0), 0) || null
  /* the picker's own label: `club — course · tee` when they differ (index.html
     attachCourseSearch: courseLabel + ' · ' + tee_name) */
  const courseName = (c) => (c.club_name && c.course_name && c.club_name !== c.course_name) ? `${c.club_name} — ${c.course_name}` : (c.course_name || c.club_name)
  const pickerLabel = (cid, tee) => { const c = course(cid); return c ? courseName(c) + (tee ? ` · ${tee}` : '') : null }
  const myMemberships = () => T.league_members.filter((m) => m.profile_id === ME && !m.left_at)
  const sharesLeague = (pid) => pid !== ME && myMemberships().some((a) => T.league_members.some((b) => b.league_id === a.league_id && b.profile_id === pid && !b.left_at))
  const inAnyLeague = (pid) => T.league_members.some((m) => m.profile_id === pid)
  const monthOf = (iso) => String(iso).slice(0, 7)

  /* ================================================================ LINKS */
  /* share_info · 20260921100000_the_plan_link.sql:98. A round card is the
     round's facts plus the band of the season it was posted into; every other
     kind is its own branch. Payload keys exactly as jsonb_build_object writes
     them (round: nulls kept; the others: jsonb_strip_nulls). */
  const stripNulls = (o) => Object.fromEntries(Object.entries(o).filter(([, v]) => v !== null && v !== undefined))
  const latestRound = (n, pick = 0) => T.rounds.filter((r) => r.profile_id === uid(n)).sort((a, b) => (a.played_on < b.played_on ? 1 : -1))[pick] || null
  const ranked = (r, seasonId) => T.v_rounds_ranked.find((x) => x.round_id === r.id && (!seasonId || x.season_id === seasonId)) || null
  function roundCard(r, over = {}) {
    if (!r) return null
    const p = prof(r.profile_id)
    const rr = ranked(r, sid(1, 1)) || ranked(r)
    return { kind: 'round', name: p ? p.display_name : 'A golfer', marker: p ? p.marker : null, gross: r.gross, holes: r.holes_played,
      course: r.course_label, played_on: r.played_on, pvi: rr ? rr.pvi : null, points: rr ? rr.points : null, photo: false, ...over }
  }
  /* X38 · D397 · HELD with 20261214090000: a stranger holding a person link
     reads the stranger shape of D394 (a name, a marker, rounds played). No
     index, no best, no dated course rounds. */
  function personCard(n) {
    const p = prof(uid(n)); if (!p) return null
    const mine = T.rounds.filter((r) => r.profile_id === p.id)
    return stripNulls({ kind: 'person', name: p.display_name, marker: p.marker, rounds_n: mine.length })
  }
  const SHARES = () => {
    const devon = latestRound(4), blake = latestRound(2), jules = latestRound(10), casey = latestRound(3)
    const s1 = T.seasons.find((s) => s.id === sid(1, 1))
    const squads = T.squads.filter((q) => q.season_id === sid(1, 1))
    const recapRows = squads.map((q) => ({ name: q.name, points: (T.v_squad_standings.find((x) => x.squad_id === q.id) || { points: 0 }).points }))
      .sort((a, b) => b.points - a.points).slice(0, 5)
    const plan = PLANS.find((p) => p.id === PLAN.taggedMe), past = PLANS.find((p) => p.id === PLAN.past)
    const planCard = (p) => stripNulls({ kind: 'plan', host: firstname(prof(uid(p.host)).display_name) || 'A golfer', marker: prof(uid(p.host)).marker,
      play_on: p.play_on, tee: p.tee_time ? p.tee_time.slice(0, 5) : null, course: planLabel(p),
      who: p.tagged.filter((n) => (p.rsvp[n] || 'in') !== 'out').map((n) => prof(uid(n)).display_name).sort().map(firstname),
      /* W7-001 [A2-schedule-1 · X42] · HELD with 20261213090000: who is IN is an explicit yes */
      who_in: p.tagged.filter((n) => p.rsvp[n] === 'in').map((n) => prof(uid(n)).display_name).sort().map(firstname) })
    return {
      [SHARE.round]: roundCard(devon),
      [SHARE.roundPhoto]: roundCard(blake, { photo: true }),
      /* the longest name in the cast on the longest course label, a front nine */
      [SHARE.roundLong]: roundCard(latestRound(9), { holes: 9, gross: 49,
        course: 'The Championship Course at Whispering Fixture Pines Country Club · Tournament Tips (Championship Black)' }),
      /* untrusted copy: markup must arrive as text (esc) and never execute */
      [SHARE.roundEscaped]: roundCard(casey, { name: 'Casey <img src=x onerror="window.__tenInjected=1"> Placeholder',
        course: 'Mesquite Wash & "Sons" <North> (fixture)' }),
      /* posted outside any season: share_info returns pvi/points null */
      [SHARE.roundNoBand]: roundCard(jules, { pvi: null, points: null }),
      [SHARE.roundBroken]: roundCard(latestRound(8), { photo: true }),
      [SHARE.settlement]: { kind: 'settlement', game: 'match', course: pickerLabel(COURSE.wash, 'Black'), played_on: W.iso(-2),
        /* X38 · D397 · HELD with 20261214090000: the game stays public, who
           pays whom does not (no `transfers`) */
        result: stripNulls({ side_a: 'Blake & Devon', side_b: 'Casey & Gray', status: '3&2', winner: '0', stake: '10',
          /* one result, told once: the cells close the match 3 up with 2 to play
             on 16 (3&2, the status), never earlier — 7 won, 4 lost, 5 halved.
             Hole 14 was a win, which made the strip 4&2 against its own
             status (critique B). */
          holes: { n: 18, played: 16, closed: 16, hot: '0', legend: 'Blake & Devon',
            cells: ['0', 'h', '1', '0', '0', 'h', '1', '0', 'h', '0', '1', '0', 'h', 'h', '1', '0'] } }),
        players: [{ name: 'Blake Sample', gross: 81 }, { name: 'Devon Testwell', gross: 78 }, { name: 'Casey Placeholder', gross: 92 }, { name: 'Gray Dummett', gross: 88 }] },
      [SHARE.recap]: s1 ? stripNulls({ kind: 'recap', league: 'North Grove (fixture)', starts_on: s1.starts_on, ends_on: s1.ends_on, status: s1.status, rows: recapRows }) : null,
      [SHARE.person]: personCard(2),
      [SHARE.personNew]: personCard(11),
      [SHARE.plan]: plan ? planCard(plan) : null,
      [SHARE.planPast]: past ? planCard(past) : null,
    }
  }
  out.share_info = (a) => { const v = SHARES()[String(a.p_token || '')]; return v === undefined ? null : v }

  /* redeem_share · 20261023090000_a_plan_day_is_the_golfers.sql. Runs only on
     the ask sheet's yes, which no state taps; answered so a tap never gaps. */
  out.redeem_share = (a) => {
    const t = String(a.p_token || '')
    if (t === SHARE.person || t === SHARE.personNew) return { kind: 'person', result: 'requested' }
    if (t === SHARE.plan) return { kind: 'plan', result: 'requested', seat: 'in' }
    if (t === SHARE.planPast) return { kind: 'plan', result: 'requested', seat: 'past' }
    return { kind: null }
  }

  /* the claim seats. A tee-sheet guest seat is a live_round_players row with a
     claim_token and no member; a scan partner is a scan_claims row. Kept here,
     not in W.tables, so no other capture's live_rounds read changes. */
  const SEATS = {
    [CLAIM.valid]:     { round: tok(111), me: tok(121), status: 'final', claimed: false, guest_name: 'Kit', gross: 91, strokes: 18, course: pickerLabel(COURSE.wash, 'Black'), finished: W.iso(-1), game: 'skins' },
    [CLAIM.used]:      { round: tok(112), me: tok(122), status: 'final', claimed: true, guest_name: 'Kit', gross: 88, strokes: 18, course: pickerLabel(COURSE.flats, 'White'), finished: W.iso(-9), game: 'none' },
    [CLAIM.abandoned]: { round: tok(113), me: tok(123), status: 'abandoned', claimed: false, guest_name: 'Kit', gross: null, strokes: 6, course: pickerLabel(COURSE.sandbox, 'Gold'), finished: null, game: 'wolf' },
    [CLAIM.setup]:     { round: tok(114), me: tok(124), status: 'setup', claimed: false, guest_name: 'Kit', gross: null, strokes: 0, course: pickerLabel(COURSE.long, 'Tournament Tips (Championship Black)'), finished: null, game: 'match' },
  }
  const SCANS = {
    [CLAIM.scan]: { guest_name: 'Kit Specimen', gross: 94, course_label: pickerLabel(COURSE.sandbox, 'Gold'), played_on: W.iso(-3), claimed: false },
  }
  /* guest_live_state · 20261122090000_one_card_one_claim.sql: a seat whose
     round is not live (or is claimed) answers only {round:{id,status}, me}.
     An unknown token RAISES 'No such round' in the database; here it answers
     null (the client treats both as "not a guest seat") and a state that wants
     the real 400 injects it. A LIVE seat (the guest pencil) is not modelled. */
  out.guest_live_state = (a) => {
    const s = SEATS[String(a.p_token || '')]
    return s ? { round: { id: s.round, status: s.status }, me: s.me } : null
  }
  /* claim_round_info · 20260716140000_wolf_skins_claim.sql:161 — final rounds only */
  out.claim_round_info = (a) => {
    const s = SEATS[String(a.p_token || '')]
    if (!s || s.status !== 'final') return null
    return { guest_name: s.guest_name, gross: s.gross, holes_scored: s.strokes, course_label: s.course, played_on: s.finished,
      game: s.game, game_result: s.game === 'skins' ? { story: 'Kit took four skins', carry: 0 } : null, claimed: s.claimed }
  }
  /* scan_claim_info · 20260718045514_photos_scan_spine.sql:124 — raises
     'Claim link not recognized' on an unknown token (null here; see above) */
  out.scan_claim_info = (a) => { const c = SCANS[String(a.p_token || '')]; return c ? { ...c } : null }

  /* league_by_code · 20261114090000_the_door_keeps_count.sql — the name, or null */
  const leagueByCode = (code) => T.leagues.find((l) => l.code && l.code.toUpperCase() === String(code || '').trim().toUpperCase()) || null
  out.league_by_code = (a) => { const l = leagueByCode(a.p_code); return l ? l.name : null }

  /* join_covenant_info · 20261115090000_season_two_is_a_re_up.sql — nine keys
     for anyone, the six (and the season's) for a signed-in caller. */
  function covenant(code) {
    const l = leagueByCode(code); if (!l) return null
    const ls = T.league_settings.find((s) => s.league_id === l.id) || {}
    const s = T.seasons.filter((x) => x.league_id === l.id).sort((a, b) => b.number - a.number)[0] || null
    const buyin = Number(ls.buyin_cents || 0)
    const base = { name: l.name, buyin_cents: buyin, preset: ls.preset || null, floor: ls.participation_floor ?? null,
      finish: ls.finish || 'cup_final', structure: ls.structure || null,
      has_pay_note: buyin > 0, buy_in_due_on: null, phase: l.phase }
    if (!V.session) return base
    const members = T.league_members.filter((m) => m.league_id === l.id && !m.left_at && (!s || (m.agreed_seasons || []).includes(s.number)))
    const pro = T.league_members.find((m) => m.league_id === l.id && m.role === 'commissioner' && !m.left_at)
    const crew = members.filter((m) => m.role !== 'commissioner').slice(0, 6)
    const meIn = T.league_members.find((m) => m.league_id === l.id && m.profile_id === ME)
    const days = s ? Math.round((Date.UTC(...s.ends_on.split('-').map((x, i) => i === 1 ? x - 1 : +x)) - Date.UTC(...s.starts_on.split('-').map((x, i) => i === 1 ? x - 1 : +x))) / 864e5) + 1 : null
    return { ...base,
      roster: { count: members.length, pro_name: pro ? (prof(pro.profile_id) || {}).display_name || null : null,
        names: crew.map((m) => prof(m.profile_id).display_name), markers: crew.map((m) => prof(m.profile_id).marker) },
      starts_on: s ? s.starts_on : null, ends_on: s ? s.ends_on : null, weeks: days ? Math.max(1, Math.round(days / 7)) : null,
      counting_cap: ls.counting_cap ?? null, every_round_counts: ls.counting_cap == null, handicap_allowance: ls.handicap_allowance ?? null,
      split: buyin > 0 ? { champion: ls.payout_champ, runner_up: ls.payout_runnerup, points_king: ls.payout_king } : null,
      pay: { has_note: buyin > 0, due_on: null },
      season_number: s ? s.number : null, reup: !!meIn, agreed: !!(meIn && s && (meIn.agreed_seasons || []).includes(s.number)), last_season: null }
  }
  out.join_covenant_info = (a) => covenant(a.p_code)
  /* join_covenant_for_invite · 20261029090000:… — the invitee's own pending invitation only */
  out.join_covenant_for_invite = (a) => (W.flags.invite && String(a.p_invite) === INVITE.league ? covenant(JOIN.season) : null)
  /* my_invites · 20261115090000:… — Blake's invitation, only when a state asks for it */
  {
    const before = prev('my_invites')
    out.my_invites = (a, w) => {
      if (!W.flags.invite) return before ? before(a, w) : []
      const l = leagueByCode(JOIN.season)
      return [{ id: INVITE.league, kind: 'league', container_id: l.id, container_name: l.name, inviter: prof(uid(2)).display_name,
        starts_on: null, created_at: W.at(-1, 19, 40), event_kind: null, buy_in: null, season_number: 1, reup: false }]
    }
  }
  /* log_growth_event · anon, fail-closed, returns void. Every link opened logs one. */
  fill('log_growth_event', () => null)

  /* ============================================================ SCHEDULE */
  /* six plans, dated off the capture clock (Mon Sep 28). `rsvp` is round_rsvp
     (the host answered too); `comments` are round_comments rows. */
  const PLANS = [
    { id: PLAN.mine, host: 1, play_on: W.iso(2), tee_time: '07:40:00', course_id: COURSE.flats, tee: 'Blue', name: 'Wednesday dawn patrol', game: 'skins',
      note: 'Walking. Loser buys the breakfast burritos.', tagged: [2, 3], rsvp: { 1: 'in', 2: 'in', 3: 'maybe' }, created_at: W.at(-3, 20, 5),
      comments: [{ by: 2, body: 'In. I’ll grab the first tee.', at: W.at(-1, 18, 12) }, { by: 3, body: 'Maybe. Depends on the carpool.', at: W.at(-1, 19, 3) }] },
    { id: PLAN.taggedMe, host: 2, play_on: W.iso(5), tee_time: '08:10:00', course_id: COURSE.wash, tee: 'Black', name: null, game: 'match',
      note: 'Bring the good balls.', tagged: [1, 4], rsvp: { 2: 'in', 4: 'in' }, created_at: W.at(-2, 9, 30),
      comments: [{ by: 4, body: 'Blake and me against the field?', at: W.at(-1, 7, 45) }] },
    { id: PLAN.leagueMate, host: 4, play_on: W.iso(6), tee_time: null, course_id: COURSE.sandbox, tee: 'Gold', name: null, game: null,
      note: 'Looking for a fourth.', tagged: [], rsvp: { 4: 'in' }, created_at: W.at(-1, 12, 0), comments: [] },
    { id: PLAN.today, host: 3, play_on: W.iso(0), tee_time: '14:10:00', course_id: COURSE.long, tee: 'Tournament Tips (Championship Black)', name: null, game: null,
      note: null, tagged: [7], rsvp: { 3: 'in', 7: 'in' }, created_at: W.at(-4, 18, 0), comments: [] },
    { id: PLAN.nine, host: 1, play_on: W.iso(12), tee_time: null, course_id: COURSE.nine, tee: 'Forward', name: null, game: null,
      note: 'Nine after work.', tagged: [], rsvp: { 1: 'in' }, created_at: W.at(-1, 21, 0), comments: [] },
    { id: PLAN.past, host: 2, play_on: W.iso(-2), tee_time: '07:00:00', course_id: COURSE.sandbox, tee: 'Gold', name: null, game: null,
      note: null, tagged: [1], rsvp: { 2: 'in', 1: 'out' }, created_at: W.at(-8, 19, 0), comments: [] },
  ]
  function planLabel(p) { return pickerLabel(p.course_id, p.tee) }
  const planWorld = () => (W.variant === 'member' || W.variant === 'pro') && !W.flags.scheduleEmpty
  const canSee = (p) => uid(p.host) === ME || p.tagged.map(uid).includes(ME) || sharesLeague(uid(p.host))
  const visiblePlans = () => (planWorld() ? PLANS.filter(canSee) : [])
  const byId = (id) => visiblePlans().find((p) => p.id === id) || null
  /* the thread rows round_detail's comments are matched against (csPlanCommentIds) */
  if (planWorld()) PLANS.forEach((p, k) => p.comments.forEach((c, i) => T.round_comments.push({
    id: tok(500 + k * 10 + i), round_id: p.id, profile_id: uid(c.by), body: c.body, created_at: c.at })))

  /* my_schedule · 20260924093000_a_weekend_has_a_name_and_a_game.sql:177 */
  function schedRow(p) {
    const host = prof(uid(p.host)), tagged = p.tagged.map(uid)
    const names = tagged.map((id) => prof(id).display_name).sort()
    const rsvp = [{ ord: 0, profile_id: host.id, display_name: host.display_name, marker: host.marker, status: 'in' }]
      .concat(p.tagged.map((n) => { const q = prof(uid(n)); return { ord: 1, profile_id: q.id, display_name: q.display_name, marker: q.marker, status: p.rsvp[n] || 'asked' } })
        .sort((a, b) => a.display_name.localeCompare(b.display_name)))
    return { id: p.id, profile_id: host.id, display_name: host.display_name, marker: host.marker, play_on: p.play_on, course_label: planLabel(p),
      note: p.note, tee_time: p.tee_time, mine: host.id === ME, is_friend: false, shared_league: sharesLeague(host.id),
      tagged_names: names.length ? names : null, tagged_me: tagged.includes(ME), course_id: String(p.course_id),
      rsvp_in: Object.values(p.rsvp).filter((s) => s === 'in').length, my_rsvp: p.rsvp[1] || null, comment_n: p.comments.length,
      name: p.name, game: p.game, tagged_pids: tagged, rsvp }
  }
  out.my_schedule = (a) => visiblePlans()
    .filter((p) => (!a.p_from || p.play_on >= a.p_from) && (!a.p_to || p.play_on <= a.p_to))
    .sort((x, y) => (x.play_on < y.play_on ? -1 : x.play_on > y.play_on ? 1 : (x.tee_time || '99') < (y.tee_time || '99') ? -1 : 1))
    .map(schedRow)

  /* round_detail · 20261001090000_what_a_round_is_worth.sql — the plan as an
     object. `worth` is month_counters over v_rounds_ranked, per season the
     viewer plays in that covers the day. An id this module does not hold falls
     to whichever module answered before (or is a gap). */
  function worth(p) {
    const rows = []
    for (const lm of myMemberships()) {
      const l = T.leagues.find((x) => x.id === lm.league_id)
      const ls = T.league_settings.find((x) => x.league_id === lm.league_id) || {}
      const s = T.seasons.find((x) => x.league_id === lm.league_id && ['active', 'cup_final'].includes(x.status) && p.play_on >= x.starts_on && p.play_on <= x.ends_on)
      if (!l || !s) continue
      const cap = ls.counting_cap ?? null
      const c = T.v_rounds_ranked.filter((vr) => vr.member_id === lm.id && vr.season_id === s.id && monthOf(vr.played_on) === monthOf(p.play_on)
        && (cap == null || cap <= 0 || vr.month_rank <= cap))
      rows.push({ league_id: l.id, league_name: l.name, cap, used: c.length, worst: c.length ? Math.min(...c.map((x) => x.points)) : null, _ends: s.ends_on })
    }
    return rows.sort((a, b) => (a._ends < b._ends ? -1 : a._ends > b._ends ? 1 : a.league_name.localeCompare(b.league_name))).map(({ _ends, ...r }) => r)
  }
  function detail(p) {
    const host = prof(uid(p.host)), tagged = p.tagged.map(uid), c = course(p.course_id)
    const t = c ? teesOf(c.id).slice().sort((x, y) => (y.number_of_holes || 0) - (x.number_of_holes || 0) || (parTotal(y) || 0) - (parTotal(x) || 0))[0] : null
    const people = [host.id, ...tagged, ...Object.keys(p.rsvp).map((n) => uid(+n))].filter((v, i, arr) => arr.indexOf(v) === i)
    const nOf = (id) => T.profiles.findIndex((q) => q.id === id) + 1   /* profiles are the cast, in order: n = index + 1 */
    return {
      id: p.id, profile_id: host.id, owner_name: host.display_name, owner_marker: host.marker, mine: host.id === ME, tagged_me: tagged.includes(ME),
      play_on: p.play_on, tee_time: p.tee_time, note: p.note, course_label: planLabel(p), course_id: String(p.course_id), league_id: null,
      my_rsvp: p.rsvp[1] || null,
      worth: (host.id === ME || tagged.includes(ME)) ? worth(p) : [],
      course: c ? { name: c.club_name || c.course_name, city: c.city, state: c.state, lat: null, lon: null,
        rating: t ? t.course_rating : null, slope: t ? t.slope_rating : null, par: t ? parTotal(t) : null, tee: t ? t.tee_name : null } : null,
      rsvp: people.map((id) => { const q = prof(id); return { profile_id: id, name: q.display_name, marker: q.marker, status: p.rsvp[nOf(id)] || null } })
        .sort((a, b) => (a.profile_id === host.id ? -1 : b.profile_id === host.id ? 1 : a.name.localeCompare(b.name))),
      comments: p.comments.map((cm) => { const q = prof(uid(cm.by)); return { name: q.display_name, marker: q.marker, body: cm.body, mine: q.id === ME, at: cm.at } }),
    }
  }
  {
    const before = prev('round_detail')
    out.round_detail = (a, w) => { const p = byId(String(a.p_round || '')); return p ? detail(p) : (before ? before(a, w) : undefined) }
  }
  /* scratch_round · returns void: the host cancels a plan for everyone (W7-079 taps it from the plan sheet's manage bar, armed and then confirmed) */
  out.scratch_round = ({ p_id }) => { const p = byId(String(p_id || '')); if (p) p.cancelled = true; return null }
  /* set_round_rsvp · returns void (20261012090000): the viewer's own answer on a plan they are tagged in (W7-039 taps it: 'I'm in') */
  out.set_round_rsvp = ({ p_round, p_status }) => { const p = byId(String(p_round || '')); if (p && ['in', 'maybe', 'out'].includes(p_status)) p.rsvp[1] = p_status; return null }

  /* ============================================================= COURSES */
  /* my_course_books · 20261009093000_the_card_carries_its_yardage.sql — every
     course on my schedule (host or tagged, today onward) or in my rounds, with
     its rated tees and their hole cards (par, stroke index and yardage). */
  function books(limit) {
    if (!V.session) return []
    const next = {}, last = {}
    for (const p of visiblePlans()) {
      if (!p.course_id || p.play_on < W.today) continue
      if (!(uid(p.host) === ME || p.tagged.map(uid).includes(ME))) continue
      const k = String(p.course_id); if (!next[k] || p.play_on < next[k]) next[k] = p.play_on
    }
    for (const r of T.rounds) {
      if (r.profile_id !== ME || r.api_course_id == null) continue
      const k = String(r.api_course_id); if (!last[k] || r.played_on > last[k]) last[k] = r.played_on
    }
    const keys = [...new Set([...Object.keys(next), ...Object.keys(last)])].filter((k) => course(k))
    keys.sort((a, b) => ((next[a] ? 0 : 1) - (next[b] ? 0 : 1)) || (next[a] && next[b] ? (next[a] < next[b] ? -1 : next[a] > next[b] ? 1 : 0) : 0)
      || ((last[b] || '') < (last[a] || '') ? -1 : (last[b] || '') > (last[a] || '') ? 1 : 0) || a.localeCompare(b))
    const n = Math.max(1, Math.min(limit == null ? 24 : Number(limit) || 24, 60))
    return keys.slice(0, n).map((k) => {
      const c = course(k)
      const tees = teesOf(c.id).filter((t) => t.course_rating != null && t.slope_rating != null)
        .sort((x, y) => (y.number_of_holes || 0) - (x.number_of_holes || 0) || (y.course_rating || 0) - (x.course_rating || 0) || String(x.tee_name).localeCompare(String(y.tee_name)))
      return { id: String(c.id), club_name: c.club_name, course_name: c.course_name, city: c.city, state: c.state, cached_at: '2026-08-02T18:00:00+00:00',
        planned: !!next[k], played: !!last[k], next_play_on: next[k] || null, last_played_on: last[k] || null,
        tees: tees.map((t) => ({ tee_name: t.tee_name, gender: t.gender, course_rating: t.course_rating, slope_rating: t.slope_rating,
          number_of_holes: t.number_of_holes, par_total: parTotal(t), total_yards: t.total_yards,
          holes: holesOf(t.id).map((h) => ({ hole: h.hole_number, par: h.par, si: h.handicap, yards: h.yardage })) })) }
    })
  }
  out.my_course_books = (a) => books(a.p_limit)

  /* course ratings · 20261009090000_a_course_carries_a_sentence.sql. Avery has
     rated three of the courses; the community and "your golfers" figures are
     the rounded means the functions return. */
  const rated = V.session && V.rounds === 'all'
  const RATINGS = {
    [COURSE.wash]: { stars: 4.5, note: 'Greens roll true. The 14th will ruin a card.', at: W.at(-4, 20, 0), all: 4, count: 5, friends: 4, friends_count: 3,
      notes: [{ n: 2, stars: 4, note: 'Fast greens, slow pace. Worth it.' }, { n: 4, stars: 4.5, note: 'Best back nine in the valley.' }] },
    [COURSE.flats]: { stars: 3.5, note: null, at: W.at(-12, 19, 0), all: 3.5, count: 7, friends: 3.5, friends_count: 4,
      notes: [{ n: 3, stars: 3, note: 'Muni pace on a Saturday. Bring a snack.' }] },
    [COURSE.long]: { stars: 4, note: 'Bring a sleeve for the par 3s.', at: W.at(-15, 21, 0), all: 4.5, count: 3, friends: 5, friends_count: 1,
      notes: [{ n: 8, stars: 5, note: 'Tips are a monster. Play it once from the back.' }] },
    [COURSE.sandbox]: { stars: null, note: null, at: null, all: 3.5, count: 2, friends: 3.5, friends_count: 2, notes: [] },
  }
  out.my_course_ratings = () => (!rated ? [] : Object.entries(RATINGS).filter(([, r]) => r.stars != null)
    .sort(([, a], [, b]) => b.stars - a.stars || (a.at < b.at ? 1 : -1))
    .map(([id, r]) => ({ course_id: String(id), stars: r.stars, note: r.note, rated_at: r.at, all: r.all, count: r.count })))
  fill('course_rating', (a) => {
    const id = String(a.p_course_id || '').trim()
    if (!V.session || !id) return { course_id: id, rated: false }
    const r = RATINGS[id]
    if (!r) return { course_id: id, rated: false, stars: null, count: 0, friends: null, friends_count: 0, mine: null, mine_note: null, notes: [] }
    return { course_id: id, rated: r.count > 0, stars: r.all, count: r.count, friends: r.friends, friends_count: r.friends_count,
      mine: rated ? r.stars : null, mine_note: rated ? r.note : null,
      notes: r.notes.map((x) => ({ who: prof(uid(x.n)).display_name, marker: prof(uid(x.n)).marker, stars: x.stars, note: x.note })) }
  })

  /* the `courses` Edge Function (supabase/functions/courses/index.ts): search
     answers the light payload (tees without holes) from the cache; `cache`
     answers ok. The provider itself is never pretended. */
  fill('fn:courses', (body) => {
    const b = body || {}
    if (b.action === 'search') {
      const q = String(b.q || '').trim().toLowerCase()
      if (q.length < 3) return { body: { courses: [] } }
      const hits = T.api_courses.filter((c) => `${c.club_name} ${c.course_name} ${c.city}`.toLowerCase().includes(q))
      return { body: { courses: hits.map((c) => ({ id: String(c.id), club_name: c.club_name, course_name: c.course_name, city: c.city, state: c.state,
        tees: teesOf(c.id).map((t) => ({ tee_name: t.tee_name, gender: t.gender, course_rating: t.course_rating, slope_rating: t.slope_rating,
          bogey_rating: null, par_total: parTotal(t), total_yards: t.total_yards, number_of_holes: t.number_of_holes })) })) } }
    }
    if (b.action === 'cache') return { body: { ok: true, id: String(b.id || ''), from_cache: true } }
    return { status: 400, body: { error: 'unknown action' } }
  })

  /* ============================================================ SETTINGS */
  /* social_notify_prefs · 20261207090000 — three booleans, all on by default */
  out.social_notify_prefs = () => ({ own_round: true, replies: true, followed: true })
  /* set_email_recap reads with {} and writes with {p_on}: the season email is on */
  fill('set_email_recap', (a) => (a && typeof a.p_on === 'boolean' ? a.p_on : true))

  /* ============================================== FILLED SIBLING READS */
  /* posted_rounds_social · 20261208090000_a_course_keeps_its_circle.sql —
     every Home and You capture asks for it. The circle is me plus my league
     mates; a course door names up to three of them who have played it. */
  fill('posted_rounds_social', (a) => {
    if (!V.session) return { items: [] }
    const circle = new Set([ME, ...T.league_members.filter((m) => sharesLeague(m.profile_id)).map((m) => m.profile_id)])
    const ids = [...new Set((a.p_rounds || []).map(String))].slice(0, 60)
    const items = []
    for (const id of ids) {
      const r = T.rounds.find((x) => x.id === id); if (!r) continue
      const c = r.api_course_id != null ? course(r.api_course_id) : null
      let doorOf = null
      if (c) {
        const at = {}
        for (const x of T.rounds) if (String(x.api_course_id) === String(c.id) && circle.has(x.profile_id)) at[x.profile_id] = at[x.profile_id] && at[x.profile_id] > x.played_on ? at[x.profile_id] : x.played_on
        const faces = Object.entries(at).filter(([pid]) => pid !== ME).sort((p, q) => (p[1] < q[1] ? 1 : p[1] > q[1] ? -1 : p[0].localeCompare(q[0]))).slice(0, 3)
          .map(([pid]) => { const q = prof(pid); return { id: q.id, name: q.display_name, marker: q.marker, handle: q.handle } })
        doorOf = { api_course_id: String(c.id), name: courseName(c), circle_golfers: Object.keys(at).length, faces }
      }
      items.push({ round_id: r.id, comment_count: 0, can_comment: true, thread_state: 'none', course: doorOf })
    }
    return { items }
  })
  /* course_page · 20261208090000_a_course_keeps_its_circle.sql — who of the circle has played a course (me plus my league mates, as posted_rounds_social reads it).
     The viewer is listed too, best gross first, as the SQL orders it; the tee comparison is not modelled (tees: [], best: null) — the course record's own door
     (W7-052) and the circle sheet read the people only. */
  fill('course_page', (a) => {
    if (!V.session) return { ok: false, reason: 'signed_out' }
    const c = course(a.p_course_id); if (!c) return { ok: false, reason: 'no_course' }
    const circle = new Set([ME, ...T.league_members.filter((m) => sharesLeague(m.profile_id)).map((m) => m.profile_id)])
    const at = {}
    for (const x of T.rounds) if (String(x.api_course_id) === String(c.id) && circle.has(x.profile_id)) (at[x.profile_id] ||= []).push(x)
    const people = Object.entries(at).map(([pid, rs]) => {
      const q = prof(pid); rs.sort((x, y) => (x.played_on < y.played_on ? 1 : x.played_on > y.played_on ? -1 : 0))
      return { _best: Math.min(...rs.map((r) => r.gross)), person: { id: q.id, name: q.display_name, marker: q.marker, handle: q.handle }, relation: pid === ME ? 'self' : 'league',
        rounds_total: rs.length, latest_played_on: rs[0].played_on, best_in_selection: null,
        rounds: rs.map((r) => ({ round_id: r.id, played_on: r.played_on, gross: r.gross, holes: r.holes_played, tee_key: null, tee_name: r.tee_name || null, has_photo: !!r.photo_path, in_selection: false })) }
    }).sort((p, q) => p._best - q._best || p.person.name.localeCompare(q.person.name)).map(({ _best, ...p }) => p)
    return { ok: true, course: { api_course_id: String(c.id), name: courseName(c), city: c.city, state: c.state, country: null },
      scope: { key: 'circle', label: 'Your circle', best_label: 'Your circle best', note: 'From your rounds, your friends\' rounds and the rounds of the golfers in your seasons, Ryders and Majors. Not an official course record.' },
      selection: { tee_key: null, tee_name: null, holes: 18 }, tees: [], holes_options: [], unknown_tee_rounds: people.reduce((n, p) => n + p.rounds_total, 0),
      best_unavailable: null, best: null, my_best: null, people_total: people.length, people }
  })
  /* my_notifications · 20261207090000 — two comments on Avery's latest round */
  fill('my_notifications', () => {
    if (!V.session || V.rounds !== 'all') return { ok: true, unread: 0, items: [], next_before: null, next_before_id: null }
    const r = latestRound(1)
    const person = (n) => { const q = prof(uid(n)); return { id: q.id, name: q.display_name, marker: q.marker, handle: q.handle } }
    const c = course(r.api_course_id)
    return { ok: true, unread: 1, next_before: null, next_before_id: null, items: [
      { id: tok(401), kind: 'own_round', created_at: W.at(0, 8, 2), read: false, read_at: null, actor: person(4), round_id: r.id, comment_id: tok(411),
        excerpt: 'Clean card. Back nine was the difference.', course_name: c ? courseName(c) : null, round_owner_name: prof(ME).display_name,
        link: { kind: 'round_comment', round_id: r.id, comment_id: tok(411), web: `/?round=${r.id}&comment=${tok(411)}` } },
      { id: tok(402), kind: 'reply', created_at: W.at(-1, 21, 14), read: true, read_at: W.at(-1, 22, 0), actor: person(2), round_id: r.id, comment_id: tok(412),
        excerpt: 'Told you the 14th plays long.', course_name: c ? courseName(c) : null, round_owner_name: prof(ME).display_name,
        link: { kind: 'round_comment', round_id: r.id, comment_id: tok(412), web: `/?round=${r.id}&comment=${tok(412)}` } },
    ] }
  })

  /* the handles a state's prepare() may reach */
  W.linksSetup = { PLANS, SEATS, SCANS, RATINGS, visiblePlans, books }
  return out
}
