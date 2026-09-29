/* Cup Season · ten-capture fixtures, WX-B: You, the record, receipts, the
 * composer and the share artifacts (WX lane, 2026-09-28).
 *
 * Every answer here is DERIVED from the synthetic world (W.tables, built by
 * world.mjs from cast.mjs) with the arithmetic of the SQL it stands in for --
 * the latest `create or replace function public.<name>` under
 * supabase/migrations wins, and each handler names the file it follows. No
 * figure is typed in: a points figure is a row of `v_rounds_ranked`, a place
 * is a rank over `v_individual_standings` / `v_squad_standings`, an award is
 * `rederive_achievements()` run over `rounds`.
 *
 * Rows this module adds to the world (its own scope only):
 *   round_holes           -- strokes for Avery's 84 (Mesquite Wash, Black) and
 *                            83 (Whispering Fixture Pines, the long tee), summing
 *                            to the gross the round carries (round_scorecard's seal)
 *   achievements          -- rederive_achievements() over the viewer's rounds
 *   posted_round_comments -- D391 round-keyed comments (the real table is
 *                            post_comments with round_id set and post_id null;
 *                            kept apart so no direct post_comments read sees them)
 *   shares, share_cleanup, share_attempts -- the round links (D385)
 * Ids use the cast's UUID style with this module's own blocks: fd20… comments,
 * fe20… share tokens / attempts, f6000000-…-0000000009NN for rounds posted
 * during a capture.
 *
 * Test-only. Never served (tests/ is outside stamp-version.sh's allowlist). */

export default function install(W) {
  const T = W.tables
  const { uid, rid } = W.ids
  const { r1, bandOf, pointsOf, PARS18, SI18 } = W.cast
  const me = W.me
  /* what earlier modules (00-, 10-) answer, so a share token this module did
     not mint still reaches whoever minted it */
  const prevShareInfo = W.handlers.share_info || null
  const U = (block, n) => `${block}-0000-4000-8000-${String(n).padStart(12, '0')}`
  const cmt = (n) => U('fd200000', n)
  const tok = (n) => U('fe200000', n)

  /* ------------------------------------------------------------ lookups */
  const round = (id) => T.rounds.find((r) => r.id === id) || null
  const prof = (id) => T.profiles.find((p) => p.id === id) || null
  const league = (id) => T.leagues.find((l) => l.id === id) || null
  const settings = (id) => T.league_settings.find((s) => s.league_id === id) || null
  const season = (id) => T.seasons.find((s) => s.id === id) || null
  const member = (id) => T.league_members.find((m) => m.id === id) || null
  const leaguesOf = (pid) => new Set(T.league_members.filter((m) => m.profile_id === pid).map((m) => m.league_id))
  const sharesLeague = (a, b) => { const la = leaguesOf(a); return T.league_members.some((m) => m.profile_id === b && la.has(m.league_id)) }
  const friends = (a, b) => (T.friendships || []).some((f) => f.status === 'accepted' && ((f.requester === a && f.addressee === b) || (f.requester === b && f.addressee === a)))
  const inCircle = (v, o) => v === o || friends(v, o) || sharesLeague(v, o)
  /* round_card / round_scorecard / round_holes_of: yours, or someone you share a league with */
  const cardVisible = (r) => !!r && (r.profile_id === me || sharesLeague(me, r.profile_id))
  /* _posted_round_visible: yours, or in your circle */
  const postedVisible = (r) => !!r && inCircle(me, r.profile_id)
  /* _social_person */
  const person = (id) => { const p = prof(id); return p ? { id: p.id, name: p.display_name, marker: p.marker, handle: p.handle } : null }
  /* course_name_of(api_id, label): the club (— course when it differs), or the label's head */
  const courseName = (apiId, label) => {
    if (apiId == null || String(apiId).trim() === '') return null
    const c = T.api_courses.find((x) => String(x.id) === String(apiId))
    if (c) return (c.club_name + (c.course_name && c.course_name !== c.club_name ? ' — ' + c.course_name : '')).trim()
    return String(label || '').split(' · ')[0].trim()
  }
  const allowanceOf = (lid) => (settings(lid) || {}).handicap_allowance ?? 100
  const month = (iso) => String(iso || '').slice(0, 7)

  /* ------------------------------------------- rows this module owns */
  /* round_holes: an 18-hole card that sums to the round's gross. Bogeys on the
     hardest holes first (stroke index 1, 2, …), then one birdie and one double
     that cancel, so the card reads like a round and still adds up. */
  function cardFor(gross, pars, sis, birdieOn, doubleOn) {
    const s = pars.slice()
    let extra = gross - s.reduce((a, b) => a + b, 0)
    const order = sis.map((si, i) => [si, i]).sort((a, b) => a[0] - b[0]).map((x) => x[1])
    for (let k = 0; extra > 0; k = (k + 1) % order.length) { s[order[k]]++; extra-- }
    if (birdieOn != null && doubleOn != null && s[birdieOn] === pars[birdieOn] && s[doubleOn] === pars[doubleOn] + 1) { s[birdieOn]--; s[doubleOn]++ }
    return s
  }
  T.round_holes = T.round_holes || []
  const addCard = (r, birdie, dbl) => {
    if (!r || r.holes_played !== 18 || T.round_holes.some((h) => h.round_id === r.id)) return
    cardFor(r.gross, PARS18, SI18, birdie, dbl).forEach((strokes, i) => T.round_holes.push({ round_id: r.id, hole_number: i + 1, strokes }))
  }
  const mine = T.rounds.filter((r) => r.profile_id === me)
  addCard(mine.find((r) => r.id === rid(1)), 15, 1)   /* 84 at Mesquite Wash · Black: a birdie on 16, a double on 2 */
  addCard(mine.find((r) => r.id === rid(3)), 2, 10)   /* 83 at Whispering Fixture Pines · the long tee */

  /* achievements: rederive_achievements() (20260902173000) over the viewer's rounds */
  T.achievements = T.achievements || []
  function rederive(pid) {
    const rs = T.rounds.filter((r) => r.profile_id === pid).sort((a, b) => a.played_on.localeCompare(b.played_on) || a.id.localeCompare(b.id))
    const has = (k) => T.achievements.some((a) => a.profile_id === pid && a.kind === k)
    const add = (kind, label, r, meta) => { if (!has(kind)) T.achievements.push({ profile_id: pid, kind, label, earned_on: r.played_on, round_id: r.id, meta }) }
    if (rs[0]) add('first_round', 'First round posted', rs[0], { gross: rs[0].gross })
    for (const t of [100, 90, 80]) {
      const r = rs.find((x) => x.holes_played === 18 && x.gross != null && x.gross < t)
      if (r) add('sub_' + t, 'Broke ' + t, r, { gross: r.gross })
    }
    const best = rs.filter((r) => r.differential != null).sort((a, b) => a.differential - b.differential || b.played_on.localeCompare(a.played_on) || a.id.localeCompare(b.id))[0]
    if (best) add('personal_best', 'Personal best', best, { diff: best.differential })
  }
  rederive(me)

  /* D391 round-keyed comments on Avery's latest round (the one carrying a photo) */
  T.posted_round_comments = T.posted_round_comments || []
  const r1st = round(rid(1))
  if (r1st && r1st.profile_id === me && T.league_members.some((m) => m.profile_id === uid(2) && leaguesOf(me).has(m.league_id))) {
    T.posted_round_comments.push(
      { id: cmt(1), round_id: r1st.id, parent_id: null, root_id: null, profile_id: uid(2), body: 'That photo belongs on the clubhouse wall. Which hole?', created_at: W.at(0, 8, 31), hidden_at: null },
      { id: cmt(2), round_id: r1st.id, parent_id: cmt(1), root_id: cmt(1), profile_id: me, body: 'The par-3 16th. Only birdie of the day.', created_at: W.at(0, 9, 4), hidden_at: null })
  }

  /* D385 round links. S1 and S2 are live links Avery made (one with the photo,
     one without); S4 is the earlier link on the same photo round, withdrawn when
     the photo consent changed, its public copies already confirmed gone; S3 is
     Indigo's own link (the long name). */
  T.shares = T.shares || []; T.share_cleanup = T.share_cleanup || []; T.share_attempts = T.share_attempts || []
  const addShare = (n, r, include_photo, opts = {}) => {
    if (!r) return
    T.shares.push({ token: tok(n), kind: 'round', ref_id: r.id, created_by: r.profile_id, include_photo, revoked: !!opts.revoked,
      completed_at: opts.revoked && !opts.completed ? null : W.at(-(opts.daysAgo || 0), 20, 45), created_at: W.at(-(opts.daysAgo || 0), 20, 44),
      has_jpg: !!(include_photo && r.photo_path && !opts.revoked), has_png: !opts.revoked })
  }
  addShare(4, round(rid(1)), true, { revoked: true, completed: true, daysAgo: 1 })
  addShare(1, round(rid(1)), true, { daysAgo: 0 })
  addShare(2, round(rid(3)), false, { daysAgo: 12 })
  const indigo = T.rounds.filter((r) => r.profile_id === uid(9)).sort((a, b) => b.played_on.localeCompare(a.played_on))[0]
  addShare(3, indigo, false, { daysAgo: 6 })
  if (T.shares.some((s) => s.token === tok(4))) {
    T.share_cleanup.push({ token: tok(4), owner_id: me, kind: 'round', ref_id: rid(1), status: 'completed', attempts: 1, last_error: null,
      requested_at: W.at(-1, 21, 2), next_attempt_at: null, completed_at: W.at(-1, 21, 3) })
  }

  /* ---------------------------------------------------- derivations */
  /* the season a round is stamped with at post time (post_round, 20260910090000):
     an active season containing the date first, then the one closing soonest */
  function seasonStamp(pid, played) {
    const ls = leaguesOf(pid)
    return T.seasons
      .filter((s) => ls.has(s.league_id) && ['active', 'cup_final', 'complete'].includes(s.status) && played >= s.starts_on && played <= s.ends_on)
      .sort((a, b) => (b.status === 'active') - (a.status === 'active') || a.ends_on.localeCompare(b.ends_on) || a.id.localeCompare(b.id))[0] || null
  }
  const playingIndex = (r, lid) => (r.index_at_post == null ? null : r1(r.index_at_post * allowanceOf(lid) / 100))
  function contributions(r, viewer) {
    return T.v_rounds_ranked
      .filter((x) => x.round_id === r.id && x.profile_id === r.profile_id)
      .filter((x) => r.profile_id === viewer || T.league_members.some((m) => m.league_id === x.league_id && m.profile_id === viewer && !m.left_at))
      .map((x) => {
        const L = league(x.league_id), st = settings(x.league_id), s = season(x.season_id)
        return { league_id: x.league_id, league_name: L ? L.name : null, season_id: x.season_id, season_number: s ? s.number : null,
          member_id: x.member_id, points: x.points, month_rank: x.month_rank, counting_cap: st ? st.counting_cap : null,
          structure: st ? st.structure : null, month: month(x.played_on), playing_index: playingIndex(r, x.league_id), pvi: x.pvi }
      })
      .sort((a, b) => String(a.league_name).localeCompare(String(b.league_name)) || (a.season_number || 0) - (b.season_number || 0))
  }
  /* rank() over points desc -- a tie shares its place */
  const rankIn = (rows, key, unit) => { const me_ = rows.find((x) => x[key] === unit); return me_ ? 1 + rows.filter((x) => x.points > me_.points).length : null }

  function threadRows(roundId) {
    const out = []
    for (const c of T.posted_round_comments.filter((c) => c.round_id === roundId && !c.hidden_at)) {
      out.push({ id: c.id, parent_id: c.parent_id, root_id: c.root_id, author: c.profile_id, body: c.body, created_at: c.created_at, origin: 'round' })
    }
    const mineL = leaguesOf(me)
    for (const p of T.posts.filter((p) => p.round_id === roundId && p.league_id && mineL.has(p.league_id) && !p.hidden_at)) {
      for (const c of T.post_comments.filter((c) => c.post_id === p.id && !c.hidden_at)) {
        const m = member(c.member_id)
        if (m) out.push({ id: c.id, parent_id: null, root_id: null, author: m.profile_id, body: c.body, created_at: c.created_at, origin: 'board' })
      }
    }
    return out.filter((x) => prof(x.author))
  }
  /* _round_tee: exactly one cached tee layout at the round's (rating, slope) */
  function roundTee(r) {
    if (r.api_course_id == null) return null
    const cand = T.api_course_tees.filter((t) => String(t.course_id) === String(r.api_course_id) && t.course_rating === r.rating && t.slope_rating === r.slope)
    const layouts = new Set(cand.map((t) => `${t.tee_name.toLowerCase()}:${t.gender}:${t.number_of_holes}`))
    if (!cand.length || layouts.size !== 1) return null
    const t = cand[0]
    return { tee_name: t.tee_name, tee_key: `${t.tee_name.toLowerCase()}:${t.gender}:${t.number_of_holes}@${Number(r.rating).toFixed(1)}/${r.slope}` }
  }

  /* recompute the scoring views for one profile after a round lands, with
     world.mjs's own arithmetic (pviOf / pointsOf / bandOf, month ranks by PvI,
     the counting cap, the ledger) -- a posted round changes nothing else */
  function rescore(pid) {
    const pvi = (r, allowance) => r1(r.index_at_post * allowance / 100 - r.differential)
    for (const m of T.league_members.filter((x) => x.profile_id === pid)) {
      const s = T.seasons.find((x) => x.league_id === m.league_id)
      if (!s) continue
      const allowance = allowanceOf(m.league_id)
      for (let i = T.v_rounds_ranked.length - 1; i >= 0; i--) if (T.v_rounds_ranked[i].member_id === m.id) T.v_rounds_ranked.splice(i, 1)
      const rs = T.rounds.filter((r) => r.profile_id === pid && r.played_on >= s.starts_on && r.played_on <= s.ends_on)
      const byMonth = {}
      for (const r of rs) (byMonth[month(r.played_on)] ||= []).push(r)
      for (const list of Object.values(byMonth)) {
        list.map((r) => ({ r, v: pvi(r, allowance) })).sort((a, b) => b.v - a.v).forEach(({ r, v }, i) => T.v_rounds_ranked.push({
          round_id: r.id, season_id: s.id, league_id: m.league_id, member_id: m.id, profile_id: pid, pvi: v, points: pointsOf(v), band: bandOf(v),
          month_rank: i + 1, floor_credit: 1, played_on: r.played_on, index_at_post: r.index_at_post, holes_played: r.holes_played, gross: r.gross, course_label: r.course_label }))
      }
      const cap = (settings(m.league_id) || {}).counting_cap
      const rr = T.v_rounds_ranked.filter((x) => x.member_id === m.id)
      const st = T.v_individual_standings.find((x) => x.member_id === m.id && x.season_id === s.id)
      if (st) { st.points = rr.filter((x) => cap == null || x.month_rank <= cap).reduce((a, x) => a + x.points, 0); st.rounds_posted = rr.length }
      for (const q of T.squads.filter((x) => x.season_id === s.id)) {
        const ids = T.squad_members.filter((x) => x.squad_id === q.id).map((x) => x.member_id)
        const row = T.v_squad_standings.find((x) => x.squad_id === q.id)
        if (row) row.points = T.v_individual_standings.filter((x) => ids.includes(x.member_id)).reduce((a, x) => a + x.points, 0)
          + T.season_adjustments.filter((a) => a.squad_id === q.id).reduce((a, x) => a + x.points, 0)
      }
    }
  }

  /* W1 (2026-09-28): the live fixture's finish lands rounds too; it rescores
     them with this same arithmetic so a finished card has its league verdict */
  W.rescore = rescore

  /* round_epilogue (20260910090000): the stamped season's lens, what the round
     earned, and the solo table's movement with the round in and out */
  function epilogue(roundId) {
    const r = round(roundId)
    if (!r || r.profile_id !== me) return null
    const lens = r.season_id ? T.v_rounds_ranked.find((x) => x.round_id === r.id && x.season_id === r.season_id) : null
    const earned = T.achievements.filter((a) => a.profile_id === me && a.round_id === r.id)
      .sort((a, b) => ['personal_best', 'sub_80', 'sub_90', 'sub_100', 'first_round'].indexOf(a.kind) - ['personal_best', 'sub_80', 'sub_90', 'sub_100', 'first_round'].indexOf(b.kind))
      .map((a) => ({ kind: a.kind, label: a.label }))
    let before = null, after = null, of = null, passed = [], gap = null
    if (r.season_id) {
      const s = season(r.season_id), st = settings(s.league_id), cap = st.counting_cap ?? 999
      const members = T.league_members.filter((m) => m.league_id === s.league_id)
      const rows = T.v_rounds_ranked.filter((x) => x.season_id === s.id)
      const tally = members.map((m) => {
        const mine_ = rows.filter((x) => x.member_id === m.id)
        const after_ = mine_.filter((x) => x.month_rank <= cap).reduce((a, x) => a + x.points, 0)
        const without = mine_.filter((x) => x.round_id !== r.id)
        const byMonth = {}
        for (const x of without) (byMonth[month(x.played_on)] ||= []).push(x)
        let before_ = 0
        for (const list of Object.values(byMonth)) list.sort((a, b) => b.points - a.points || b.pvi - a.pvi || b.played_on.localeCompare(a.played_on)).forEach((x, i) => { if (i + 1 <= cap) before_ += x.points })
        return { member_id: m.id, name: (prof(m.profile_id) || {}).display_name || '', after: after_, before: before_ }
      })
      const rk = (key) => tally.slice().sort((a, b) => b[key] - a[key] || a.name.localeCompare(b.name)).map((t, i, arr) => ({ t, rk: 1 + arr.findIndex((u) => u[key] === t[key] && u.name === t.name) }))
      const ra = new Map(rk('after').map((x) => [x.t.member_id, x.rk])), rb = new Map(rk('before').map((x) => [x.t.member_id, x.rk]))
      const mm = members.find((m) => m.profile_id === me)
      if (mm && (st.season_format || 'points') !== 'squads') {
        before = rb.get(mm.id); after = ra.get(mm.id); of = members.length
        passed = tally.filter((t) => t.member_id !== mm.id && rb.get(t.member_id) < before && ra.get(t.member_id) > after).map((t) => t.name.split(' ')[0])
        const ahead = tally.filter((t) => ra.get(t.member_id) < after)
        gap = ahead.length ? Math.min(...ahead.map((t) => t.after)) - tally.find((t) => t.member_id === mm.id).after : null
      }
    }
    return { gross: r.gross, holes: r.holes_played, pvi: lens ? lens.pvi : null, points: lens ? lens.points : null, month_rank: lens ? lens.month_rank : null,
      earned, rivals: [], season_id: r.season_id || null, rank_before: before, rank_after: after, of, passed, gap_to_next_after: gap, played_with: [] }
  }

  /* ---------------------------------------------- the round links (D385) */
  const liveShare = (roundId, owner = me) => T.shares.find((s) => s.kind === 'round' && s.ref_id === roundId && s.created_by === owner && !s.revoked) || null
  let mintN = 100
  const mint = (fields) => { const s = { token: tok(++mintN), revoked: false, created_at: W.at(0, 9, 30), completed_at: null, has_jpg: false, has_png: false, ...fields }; T.shares.push(s); return s }

  /* ================================================================ RPCs */
  return {
    /* 20260917093000_a_card_carries_its_case.sql */
    career_record: () => {
      const tr = (T.trophies || []).filter((t) => t.profile_id === me)
      const n = (f) => tr.filter(f).length
      const rs = T.rounds.filter((r) => r.profile_id === me).map((r) => r.played_on).sort()
      const pays = (T.season_payouts || []).filter((p) => p.profile_id === me)
      const mySeasons = T.seasons.filter((s) => leaguesOf(me).has(s.league_id) && s.status === 'complete')
      return {
        cups: n((t) => t.kind === 'league' && t.placement === 'winner'), runner_ups: n((t) => t.kind === 'league' && t.placement === 'runner_up'),
        crowns: n((t) => t.placement === 'points_king'), majors: n((t) => t.kind === 'major' && t.placement === 'winner'),
        events: n((t) => t.kind === 'event' && t.placement === 'winner'), trophies: tr.length,
        earnings_cents: pays.reduce((a, p) => a + (p.cents || 0), 0), seasons_done: new Set(pays.map((p) => p.season_id)).size,
        seasons_played: mySeasons.length, first_round_on: rs[0] || null, leagues: T.league_members.filter((m) => m.profile_id === me).length,
      }
    },
    /* 20260713200000_trophies.sql -- no season in this world is complete, so the case holds no hardware */
    my_trophies: () => (T.trophies || []).filter((t) => t.profile_id === me).sort((a, b) => String(b.season_year || '').localeCompare(String(a.season_year || ''))),
    /* 20260902173000_what_a_deleted_round_leaves_behind.sql */
    my_achievements: () => T.achievements.filter((a) => a.profile_id === me)
      .sort((a, b) => b.earned_on.localeCompare(a.earned_on) || a.kind.localeCompare(b.kind))
      .map((a) => ({ kind: a.kind, label: a.label, earned_on: a.earned_on, meta: a.meta, round_id: a.round_id })),
    /* 20261123090000_the_record_names_the_champion.sql -- one row per season the golfer said yes to */
    my_league_record: () => {
      const rows = []
      for (const lm of T.league_members.filter((m) => m.profile_id === me)) {
        const L = league(lm.league_id), st = settings(lm.league_id)
        for (const s of T.seasons.filter((x) => x.league_id === lm.league_id && (lm.agreed_seasons || []).includes(x.number))) {
          const solo = st.structure === 'solo'
          const sq = T.squads.find((q) => q.season_id === s.id && T.squad_members.some((x) => x.squad_id === q.id && x.member_id === lm.id)) || null
          const ind = T.v_individual_standings.filter((x) => x.season_id === s.id)
          const sqs = T.v_squad_standings.filter((x) => x.season_id === s.id)
          const unitRows = solo ? ind : sqs, key = solo ? 'member_id' : 'squad_id', unit = solo ? lm.id : (sq && sq.id)
          const mineRow = unitRows.find((x) => x[key] === unit)
          rows.push({
            league_id: L.id, league_name: L.name, phase: L.phase, sandbox: L.sandbox, structure: st.structure, season_id: s.id, number: s.number,
            status: s.status, starts_on: s.starts_on, ends_on: s.ends_on, squad_name: sq ? sq.name : null,
            place: unit ? rankIn(unitRows, key, unit) : null,
            of: solo ? ind.length : T.squads.filter((q) => q.season_id === s.id).length,
            tied: s.status !== 'complete' && !!mineRow && unitRows.some((x) => x[key] !== unit && x.points === mineRow.points),
            won: false, runner_up: false, king: false,
            points: (ind.find((x) => x.member_id === lm.id) || {}).points ?? null,
          })
        }
      }
      return rows.sort((a, b) => String(b.starts_on).localeCompare(String(a.starts_on)) || a.league_name.localeCompare(b.league_name))
    },
    /* 20260829090000_leagueless_live_rounds.sql -- live rounds where the viewer is a known guest: none in this world */
    my_visitor_rounds: () => [],

    /* 20261104090000_the_round_that_counts_explained.sql */
    round_card: ({ p_round, p_league }) => {
      const r = round(p_round)
      if (!cardVisible(r)) return null
      const contrib = contributions(r, me)
      const lens = p_league ? contrib.find((c) => c.league_id === p_league) || null : contrib.length === 1 ? contrib[0] : null
      const pvi = lens ? lens.pvi : (r.index_at_post != null && r.differential != null ? r1(r.index_at_post - r.differential) : null)
      return {
        id: r.id, gross: r.gross, holes_played: r.holes_played, played_on: r.played_on, course_label: r.course_label,
        rating: r.rating, slope: r.slope, nine_rating: r.holes_played === 9 ? r.rating : null, differential: r.differential,
        index_at_post: r.index_at_post, index_provisional: false, provisional_round: null,
        playing_index: lens ? lens.playing_index : null, pvi, band: pvi == null ? null : bandOf(pvi),
        points: lens ? lens.points : null, month_rank: lens ? lens.month_rank : null, counting_cap: lens ? lens.counting_cap : null,
        league_id: lens ? lens.league_id : null, season_id: lens ? lens.season_id : null, member_id: lens ? lens.member_id : null,
        contributions: contrib, source: 'quick', attested: false, photo_path: r.photo_path, live_round_id: null,
        profile_id: r.profile_id, golfer: (prof(r.profile_id) || {}).display_name || null, is_mine: r.profile_id === me, played_with: [],
      }
    },
    /* same file -- one golfer's rounds under one season's rule, one month */
    counting_rounds: ({ p_member, p_season, p_month }) => {
      const lm = member(p_member)
      if (!lm || !(lm.profile_id === me || leaguesOf(me).has(lm.league_id))) return null
      const L = league(lm.league_id), st = settings(lm.league_id), s = T.seasons.find((x) => x.id === p_season && x.league_id === lm.league_id)
      if (!s) return null
      const rounds = T.v_rounds_ranked.filter((x) => x.member_id === lm.id && x.season_id === s.id && (!p_month || month(x.played_on) === p_month))
        .sort((a, b) => b.played_on.localeCompare(a.played_on) || a.month_rank - b.month_rank)
        .map((x) => { const ro = round(x.round_id) || {}; return { round_id: x.round_id, played_on: x.played_on, holes_played: x.holes_played, gross: ro.gross,
          course_label: ro.course_label, pvi: x.pvi, points: x.points, month_rank: x.month_rank, month: month(x.played_on),
          counting: st.counting_cap == null || st.counting_cap <= 0 || x.month_rank <= st.counting_cap } })
      const p = prof(lm.profile_id)
      return { league_id: L.id, league_name: L.name, season_id: s.id, season_number: s.number, member_id: lm.id, golfer: p.display_name,
        is_me: p.id === me, cap: st.counting_cap, structure: st.structure, month: p_month || null, rounds }
    },
    /* 20261011090000_the_card_a_round_actually_has.sql */
    round_scorecard: ({ p_round }) => {
      const r = round(p_round)
      if (!cardVisible(r)) return null
      const n = r.holes_played === 9 ? 9 : 18
      const hs = T.round_holes.filter((h) => h.round_id === r.id && h.hole_number >= 1 && h.hole_number <= n).sort((a, b) => a.hole_number - b.hole_number)
      const sum = hs.reduce((a, h) => a + h.strokes, 0)
      if (hs.length !== n || hs[0].hole_number !== 1 || hs[n - 1].hole_number !== n || sum !== r.gross) return null
      let pars = null, sis = null, yards = null, teeName = null, source = null
      if (n === 18 && r.api_course_id != null) {
        const holesOf = (t) => T.api_course_holes.filter((h) => h.tee_id === t.id && h.hole_number >= 1 && h.hole_number <= 18).sort((a, b) => a.hole_number - b.hole_number)
        const pinned = T.api_course_tees.filter((t) => String(t.course_id) === String(r.api_course_id) && t.course_rating === r.rating && t.slope_rating === r.slope && holesOf(t).filter((h) => h.par != null).length === 18)
        if (pinned.length === 1) {
          const hh = holesOf(pinned[0]); pars = hh.map((h) => h.par); sis = hh.map((h) => h.handicap); yards = hh.map((h) => h.yardage); teeName = pinned[0].tee_name; source = 'tee'
        } else {
          const all = T.api_course_tees.filter((t) => String(t.course_id) === String(r.api_course_id)).map(holesOf).filter((hh) => hh.filter((h) => h.par != null).length === 18)
          const pk = new Set(all.map((hh) => hh.map((h) => h.par).join(',')))
          if (pk.size === 1) {
            pars = all[0].map((h) => h.par); source = 'course'
            const sk = new Set(all.filter((hh) => hh.every((h) => h.handicap != null)).map((hh) => hh.map((h) => h.handicap).join(',')))
            if (sk.size === 1) sis = all.find((hh) => hh.every((h) => h.handicap != null)).map((h) => h.handicap)
          }
        }
      }
      const strip = (o) => Object.fromEntries(Object.entries(o).filter(([, v]) => v != null))
      const sumOf = (a, lo, hi) => a.slice(lo - 1, hi).reduce((x, y) => x + y, 0)
      const st = hs.map((h) => h.strokes)
      return strip({
        round_id: r.id, holes_played: n, gross: r.gross, course_label: r.course_label, played_on: r.played_on, tee_name: teeName, par_source: source,
        holes: st.map((s, i) => strip({ hole: i + 1, par: pars ? pars[i] : null, si: sis ? sis[i] : null, yards: yards ? yards[i] : null, strokes: s })),
        par_out: pars ? sumOf(pars, 1, 9) : null, par_in: pars ? sumOf(pars, 10, 18) : null, par_total: pars ? sumOf(pars, 1, n) : null,
        out: sumOf(st, 1, Math.min(9, n)), inn: n === 18 ? sumOf(st, 10, 18) : null, total: r.gross,
      })
    },
    /* 20260827130300_round_holes_of.sql (the client's missing-function fallback) */
    round_holes_of: ({ p_round }) => {
      const r = round(p_round)
      if (!cardVisible(r)) return []
      return T.round_holes.filter((h) => h.round_id === r.id).sort((a, b) => a.hole_number - b.hole_number).map((h) => ({ hole_number: h.hole_number, strokes: h.strokes }))
    },
    /* 20261107090000_a_round_reads_its_own_holes.sql -- known only for a round out of a live round with verified pars; none here */
    round_tally: () => ({ known: false, eagles: 0, birdies: 0 }),
    /* 20260910090000_a_round_is_posted_by_the_server.sql */
    round_epilogue: ({ p_round }) => epilogue(p_round),

    /* 20261207090000_the_round_keeps_its_conversation.sql */
    posted_round_thread: ({ p_round, p_focus }) => {
      const r = round(p_round)
      if (!postedVisible(r)) return { ok: false, reason: 'not_visible' }
      const t = threadRows(r.id)
      const newest = t.slice().sort((a, b) => b.created_at.localeCompare(a.created_at) || b.id.localeCompare(a.id)).slice(0, 200).map((x) => x.id)
      const f = p_focus ? t.find((x) => x.id === p_focus) : null
      const want = new Set([...newest, ...(f ? [f.id, f.parent_id, f.root_id] : [])].filter(Boolean))
      const byId = new Map(t.map((x) => [x.id, x]))
      const tee = roundTee(r)
      return {
        ok: true,
        round: { id: r.id, owner: person(r.profile_id), is_mine: r.profile_id === me, gross: r.gross, holes: r.holes_played, played_on: r.played_on,
          course: { api_course_id: r.api_course_id, name: courseName(r.api_course_id, r.course_label), label: r.course_label,
            tee_name: tee ? tee.tee_name : null, tee_key: tee ? tee.tee_key : null }, photo_path: r.photo_path },
        can_comment: true, comment_block_reason: null,
        thread: { state: 'none', following: false, muted: false },
        notify_prefs: { own_round: true, replies: true, followed: true },
        count: t.length,
        page: { newest: newest.length, limit: 200, truncated: t.length > newest.length, focus_id: f ? f.id : null },
        comments: t.filter((x) => want.has(x.id)).sort((a, b) => a.created_at.localeCompare(b.created_at) || a.id.localeCompare(b.id)).map((x) => {
          const parent = x.parent_id ? byId.get(x.parent_id) : null
          return { id: x.id, round_id: r.id, parent_id: x.parent_id, root_id: x.root_id,
            reply_to: parent && parent.origin === 'round' ? { id: parent.id, name: (prof(parent.author) || {}).display_name || null } : null,
            author: person(x.author), body: x.body, created_at: x.created_at, origin: x.origin, is_mine: x.author === me, can_reply: x.origin === 'round' }
        }),
      }
    },
    /* 20261208090000_a_course_keeps_its_circle.sql */
    posted_rounds_social: ({ p_rounds }) => {
      const ids = [...new Set((p_rounds || []).map(String))].slice(0, 60)
      const vis = ids.map(round).filter(postedVisible)
      const circle = [...new Set(T.profiles.map((p) => p.id))].filter((pid) => inCircle(me, pid))
      return { items: vis.map((vr) => {
        let course = null
        if (vr.api_course_id != null) {
          const at = circle.map((pid) => {
            const rs = T.rounds.filter((x) => x.profile_id === pid && String(x.api_course_id) === String(vr.api_course_id))
            return rs.length ? { pid, last_on: rs.map((x) => x.played_on).sort().pop(), rel: pid === me ? 'me' : friends(me, pid) ? 'friend' : 'league' } : null
          }).filter(Boolean)
          const faces = at.filter((a) => a.pid !== me).sort((a, b) => (b.rel === 'friend') - (a.rel === 'friend') || b.last_on.localeCompare(a.last_on) || a.pid.localeCompare(b.pid)).slice(0, 3).map((a) => person(a.pid))
          course = { api_course_id: vr.api_course_id, name: courseName(vr.api_course_id, vr.course_label), circle_golfers: at.length, faces }
        }
        return { round_id: vr.id, comment_count: threadRows(vr.id).length, can_comment: true, thread_state: 'none', course }
      }) }
    },

    /* 20261202090000_one_share_one_attempt.sql */
    round_share_status: ({ p_round }) => {
      const r = round(p_round)
      if (!(r && r.profile_id === me) && !T.shares.some((s) => s.kind === 'round' && s.ref_id === p_round && s.created_by === me)) return null
      const live = T.shares.find((s) => s.kind === 'round' && s.ref_id === p_round && s.created_by === me && !s.revoked && s.completed_at)
      const open = T.share_cleanup.filter((c) => c.status !== 'completed' && T.shares.some((s) => s.token === c.token && s.kind === 'round' && s.ref_id === p_round && s.created_by === me))
        .sort((a, b) => b.requested_at.localeCompare(a.requested_at))
      return { token: live ? live.token : null, include_photo: live ? live.include_photo : null, cleanup_pending: open.length > 0,
        cleanup: open.map((c) => ({ token: c.token, status: c.status, last_error: c.last_error, next_attempt_at: c.next_attempt_at })),
        preparing: T.share_attempts.some((a) => a.ref_id === p_round && a.owner_id === me && a.state === 'prepared') }
    },
    prepare_round_share: ({ p_round, p_include_photo, p_attempt }) => {
      const prior = T.share_attempts.find((a) => a.attempt_id === p_attempt)
      if (prior) return { token: prior.token, created: prior.created, include_photo: prior.include_photo, state: prior.state, active: T.shares.some((s) => s.token === prior.token && !s.revoked) }
      const r = round(p_round)
      if (!r || r.profile_id !== me) return null
      const photo = !!p_include_photo && !!r.photo_path
      const live = liveShare(r.id)
      if (live && live.completed_at && live.include_photo === photo) {
        T.share_attempts.push({ attempt_id: p_attempt, owner_id: me, ref_id: r.id, token: live.token, created: false, include_photo: photo, state: 'prepared' })
        return { token: live.token, created: false, include_photo: photo, state: 'prepared', active: true }
      }
      if (live) live.revoked = true
      const s = mint({ kind: 'round', ref_id: r.id, created_by: me, include_photo: photo })
      T.share_attempts.push({ attempt_id: p_attempt, owner_id: me, ref_id: r.id, token: s.token, created: true, include_photo: photo, state: 'prepared' })
      return { token: s.token, created: true, include_photo: photo, state: 'prepared', active: true, rotated: !!live }
    },
    finish_round_share: ({ p_attempt, p_completed }) => {
      const a = T.share_attempts.find((x) => x.attempt_id === p_attempt && x.owner_id === me)
      if (!a) return null
      const s = T.shares.find((x) => x.token === a.token)
      if (a.state === 'prepared') {
        if (p_completed) { a.state = 'completed'; if (a.created && s && !s.revoked) s.completed_at = s.completed_at || W.at(0, 9, 31) }
        else { a.state = 'cancelled'; if (a.created && s && !s.revoked && !s.completed_at) s.revoked = true }
      }
      return { attempt: a.attempt_id, state: a.state, token: a.token, created: a.created, active: !!s && !s.revoked && !!s.completed_at,
        cleanup_pending: T.share_cleanup.some((c) => c.token === a.token && c.status !== 'completed') }
    },
    /* 20260921100000_the_plan_link.sql (create_share: one live token per artifact) */
    create_share: ({ p_kind, p_ref }) => {
      const live = T.shares.find((s) => s.kind === p_kind && s.ref_id === p_ref && s.created_by === me && !s.revoked)
      return (live || mint({ kind: p_kind, ref_id: p_ref, created_by: me, include_photo: null, completed_at: W.at(0, 9, 30) })).token
    },
    /* 20261117090000_shared_card_consent.sql -- the storage policy's pre-check: the golfer's own live round token */
    can_drop_share_copy: ({ p_name }) => { const t = String(p_name || '').replace(/\.(png|jpg)$/, ''); return T.shares.some((s) => s.token === t && s.created_by === me && !s.revoked) },
    /* 20261206090000_withdrawal_can_finish.sql */
    withdraw_round_shares: ({ p_round }) => {
      const r = round(p_round)
      if (!(r && r.profile_id === me) && !T.shares.some((s) => s.kind === 'round' && s.ref_id === p_round && s.created_by === me)) return []
      for (const s of T.shares.filter((x) => x.kind === 'round' && x.ref_id === p_round && x.created_by === me && !x.revoked)) s.revoked = true
      for (const s of T.shares.filter((x) => x.kind === 'round' && x.ref_id === p_round && x.created_by === me && x.revoked)) {
        if (!T.share_cleanup.some((c) => c.token === s.token)) T.share_cleanup.push({ token: s.token, owner_id: me, kind: 'round', ref_id: p_round, status: 'pending', attempts: 0, last_error: null, requested_at: W.at(0, 9, 32), next_attempt_at: W.at(0, 9, 32), completed_at: null })
      }
      return T.shares.filter((x) => x.kind === 'round' && x.ref_id === p_round && x.created_by === me).sort((a, b) => a.created_at.localeCompare(b.created_at)).map((s) => s.token)
    },
    /* 20261201090000_a_withdrawn_photo_is_gone.sql */
    my_share_cleanup: () => T.share_cleanup.filter((c) => c.owner_id === me).sort((a, b) => b.requested_at.localeCompare(a.requested_at)).map((c) => ({
      token: c.token, kind: c.kind, ref_id: c.ref_id, status: c.status, attempts: c.attempts, last_error: c.last_error, requested_at: c.requested_at,
      next_attempt_at: c.status !== 'completed' ? c.next_attempt_at : null, completed_at: c.completed_at, paths: [c.token + '.jpg', c.token + '.png'] })),
    confirm_share_cleanup: ({ p_token }) => {
      const c = T.share_cleanup.find((x) => x.token === p_token && x.owner_id === me)
      if (!c) return null
      const s = T.shares.find((x) => x.token === p_token)
      const n = s ? (s.has_jpg ? 1 : 0) + (s.has_png ? 1 : 0) : 0
      if (n === 0) { c.status = 'completed'; c.completed_at = c.completed_at || W.at(0, 9, 33); c.last_error = null }
      else { c.status = 'error'; c.attempts++; c.last_error = n + (n === 1 ? ' public copy is' : ' public copies are') + ' still stored' }
      return { token: c.token, status: c.status, remaining: n, last_error: c.last_error }
    },
    /* 20260921100000_the_plan_link.sql, the round branch -- anon and signed in alike.
       Every dead path (made up, revoked, a voided round) answers null (D57). A token
       this module did not mint is handed to whatever answered before it. */
    share_info: (args, W_) => {
      const s = T.shares.find((x) => x.token === args.p_token)
      if (!s) return prevShareInfo ? prevShareInfo(args, W_) : null
      if (s.revoked || s.kind !== 'round') return null
      const r = round(s.ref_id)
      if (!r) return null
      const p = prof(r.profile_id) || {}
      const st = seasonStamp(r.profile_id, r.played_on)
      const lens = st ? T.v_rounds_ranked.find((x) => x.round_id === r.id && x.season_id === st.id) : null
      return { kind: 'round', name: p.display_name || 'A golfer', marker: p.marker || null, gross: r.gross, holes: r.holes_played,
        course: r.course_label, played_on: r.played_on, pvi: lens ? lens.pvi : null, points: lens ? lens.points : null, photo: !!s.has_jpg }
    },
    /* 20260828160000 -- fire-and-forget funnel breadcrumb; void */
    log_growth_event: () => null,

    /* 20261021090000_idempotent_phone_rounds.sql over post_round (20260910090000):
       the round is inserted, the scoring views re-derive for the poster, the
       board fans it out, and the epilogue rides back in the same answer */
    post_round_once: ({ p_request_id, p_payload, p_hole_scores }) => {
      W.postReceipts = W.postReceipts || {}
      if (W.postReceipts[p_request_id]) return W.postReceipts[p_request_id]
      const pl = p_payload || {}
      const holes = Number(pl.holes_played) === 9 ? 9 : 18
      const gross = Number(pl.gross), rating = Number(pl.rating), slope = Number(pl.slope)
      const nine = holes === 9 ? Number(pl.nine_rating) : null
      const label = String(pl.course_label || '').trim()
      const played = pl.played_on || W.iso(0)
      if (!(gross >= 18 && gross <= 200 && rating >= 25 && rating <= 90 && slope >= 55 && slope <= 155 && label && played <= W.iso(0))) return undefined
      const course = pl.api_course_id != null && T.api_courses.some((c) => String(c.id) === String(pl.api_course_id)) ? pl.api_course_id : null
      const photo = pl.photo_path && String(pl.photo_path).startsWith(me + '/') ? pl.photo_path : null
      const st = seasonStamp(me, played)
      const sq = st ? T.squads.find((q) => q.season_id === st.id && T.squad_members.some((x) => x.squad_id === q.id && (member(x.member_id) || {}).profile_id === me)) : null
      const idx = (prof(me) || {}).index_current
      const diff = holes === 9 ? r1((gross - nine) * 113 / slope * 2) : r1((gross - rating) * 113 / slope)
      const n = 900 + T.rounds.filter((r) => r.id.startsWith('f6000000') && /9\d\d$/.test(r.id)).length + 1
      const r = { id: rid(n), profile_id: me, gross, rating, slope, differential: diff, index_at_post: idx, played_on: played, course_label: label,
        holes_played: holes, photo_path: photo, api_course_id: course, created_at: W.at(0, 9, 30), tee_name: label.split(' · ')[1] || null,
        par: holes === 9 ? 36 : 72, season_id: st ? st.id : null }
      T.rounds.push(r)
      ;(p_hole_scores || []).forEach((s, i) => T.round_holes.push({ round_id: r.id, hole_number: i + 1, strokes: s }))
      rescore(me)
      rederive(me)
      for (const m of T.league_members.filter((x) => x.profile_id === me)) {
        const s = T.seasons.find((x) => x.league_id === m.league_id)
        if (!s || played < s.starts_on || played > s.ends_on) continue
        const p = prof(me)
        T.posts.push({ id: U('f7000000', 800 + n), league_id: m.league_id, profile_id: me, kind: 'round', member_id: m.id,
          body: `${p.display_name.split(' ')[0].toUpperCase()} POSTED ${gross} AT ${label.split(' · ')[0].toUpperCase()}`, created_at: r.created_at, round_id: r.id, live_round_id: null, scheduled_round_id: null })
      }
      const resp = { round: { id: r.id, season_id: st ? st.id : null, league_id: st ? st.league_id : null, league_name: st ? league(st.league_id).name : null,
        squad: sq ? sq.name : null, played_on: played, gross, holes_played: holes, course_label: label, api_course_id: course, photo_path: photo,
        counts: !!st, tagged: 0 }, epilogue: epilogue(r.id) }
      W.postReceipts[p_request_id] = resp
      return resp
    },
    /* 20261027090000_a_post_can_be_asked_about.sql */
    round_post_status: ({ p_request_id }) => (W.postReceipts || {})[p_request_id] || null,
  }
}
