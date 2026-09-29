/* Cup Season · ten-capture: THE LIVE ROUND (WX lane, 2026-09-28).
 *
 * The tee sheet's server half, over the synthetic world, each handler named
 * for the migration it follows:
 *   start_live_round    20261012090000_the_server_says_the_sentence_the_golfer_reads.sql
 *                       -> { live_round_id, join_code, players:[{id, member_id,
 *                          guest_name, claim_token, position}] }
 *   live_join           20260830280000_d125_posted_by_and_attestation.sql (void)
 *   live_set_score      20260728120000_live_sync.sql (void; strokes clamped 1..15,
 *   live_set_wolf       a null deletes; the newer client_ts wins)
 *   live_state          20260728120000_live_sync.sql (_live_state_of: round,
 *                       players, scores with cts = epoch ms of client_ts)
 *   finish_live_round   20260921090000_a_post_can_be_homed_on_a_person.sql plus
 *                       20261105090000's identities: posted cards carry
 *                       round_id + profile_id, skipped cards profile_id
 *   abandon_live_round  (void; the round leaves `live`)
 * A round that starts here is also written to W.tables.live_rounds /
 * live_round_players / live_scores, so a reload's rehydrateLiveRound reads the
 * same round through PostgREST. A posted card becomes a `rounds` row (the
 * receipt opens it); the scoring views are not re-derived for it.
 *
 * Nothing here is a person: every seat is a cast member or a named guest the
 * state types in. Test-only. */
export default function install(W) {
  const T = W.tables
  const U = (b, n) => `${b}-0000-4000-8000-${String(n).padStart(12, '0')}`
  const lrId = (n) => U('fb600000', n), plId = (n) => U('fb610000', n), tokId = (n) => U('fb620000', n)
  T.live_rounds = T.live_rounds || []
  T.live_round_players = T.live_round_players || []
  T.live_scores = T.live_scores || []
  let nLR = T.live_rounds.length, nPL = T.live_round_players.length, nR = 0
  const prof = (id) => T.profiles.find((p) => p.id === id) || null
  const member = (id) => T.league_members.find((m) => m.id === id) || null
  const round = (id) => T.live_rounds.find((r) => r.id === id) || null
  const seats = (lr) => T.live_round_players.filter((p) => p.live_round_id === lr).sort((a, b) => a.position - b.position)
  const profileOf = (pl) => (pl.member_id ? (member(pl.member_id) || {}).profile_id : pl.guest_profile_id) || null
  const labelOf = (pl) => { const p = prof(profileOf(pl)); return p ? p.display_name : (pl.guest_name || 'A golfer') }
  const r1 = (x) => Math.round(x * 10) / 10

  function start(a) {
    if (!W.V.session) return undefined
    const id = lrId(++nLR)
    const code = 'FXLV' + String(nLR).padStart(2, '0')
    const snap = a.p_snapshot || {}
    const row = { id, league_id: a.p_league || null, status: 'live', game: a.p_game || 'none', game_config: a.p_config || {}, game_state: {},
      course_snapshot: snap, course_label: a.p_course_label || snap.label || null, join_code: code, started_by: W.me, starter_profile_id: W.me,
      started_at: W.at(0, 9, 30), api_course_id: a.p_api_course_id || null, scheduled_round_id: null }
    T.live_rounds.push(row)
    ;(a.p_players || []).forEach((p, i) => {
      const guest = !p.member_id
      T.live_round_players.push({ id: plId(++nPL), live_round_id: id, position: i, member_id: p.member_id || null,
        guest_name: guest ? (p.guest_name || null) : null, guest_index: guest ? (p.guest_index ?? null) : null,
        guest_profile_id: guest ? (p.guest_profile || null) : null, index_source: guest ? 'self' : 'engine',
        claim_token: guest && !p.guest_profile ? tokId(nPL) : null, joined_at: null, claimed_profile: null })
    })
    return { live_round_id: id, join_code: code, players: seats(id).map((p) => ({ id: p.id, member_id: p.member_id, guest_name: p.guest_name, claim_token: p.claim_token, position: p.position })) }
  }

  function setScore(a) {
    const r = round(a.p_live_round)
    if (!r) return { __error: 'No such round' }
    if (r.status !== 'live') return { __error: 'Round is not live' }
    if (!seats(r.id).some((p) => p.id === a.p_player)) return { __error: 'No such player in this round' }
    const cts = Date.parse(a.p_client_ts || W.now) || 0
    const i = T.live_scores.findIndex((s) => s.player_id === a.p_player && s.hole_number === a.p_hole)
    if (a.p_strokes == null) { if (i >= 0 && T.live_scores[i].cts < cts) T.live_scores.splice(i, 1); return null }
    const cell = { live_round_id: r.id, player_id: a.p_player, hole_number: a.p_hole, strokes: Math.min(15, Math.max(1, a.p_strokes | 0)), cts }
    if (i < 0) T.live_scores.push(cell)
    else if (T.live_scores[i].cts <= cts) T.live_scores[i] = cell
    return null
  }

  function stateOf(lr) {
    const r = round(lr)
    if (!r) return undefined
    return {
      round: { id: r.id, league_id: r.league_id, status: r.status, game: r.game, game_config: r.game_config, game_state: r.game_state,
        course_snapshot: r.course_snapshot, course_label: r.course_label, join_code: r.join_code, started_at: r.started_at },
      players: seats(lr).map((p) => { const pr = p.member_id ? prof(profileOf(p)) : null
        return { id: p.id, member_id: p.member_id, guest_name: p.guest_name, guest_index: p.guest_index, index_source: p.index_source, position: p.position,
          display_name: pr ? pr.display_name : null, index_current: pr ? pr.index_current : null } }),
      scores: T.live_scores.filter((s) => s.live_round_id === lr).map((s) => ({ player_id: s.player_id, hole: s.hole_number, strokes: s.strokes, cts: s.cts })),
    }
  }

  function finish(a) {
    const r = round(a.p_live_round)
    if (!r) return { __error: 'No such round' }
    if (r.status === 'final') return { already_final: true }
    const holes = Number((r.course_snapshot || {}).holes) === 9 ? 9 : 18
    const rating = Number((r.course_snapshot || {}).rating) || null, slope = Number((r.course_snapshot || {}).slope) || null
    const nine = holes === 9 ? Number((r.course_snapshot || {}).nine_rating) || (rating ? rating / 2 : null) : null
    const posted = [], guests = [], skipped = []
    for (const card of (a.p_cards || [])) {
      const pl = seats(r.id).find((p) => p.id === card.player_id)
      if (!pl) continue
      const pid = profileOf(pl)
      if (a.p_casual) { skipped.push({ name: labelOf(pl), profile_id: pid, reason: 'casual' }); continue }
      const strokes = (card.strokes || []).slice(0, holes)
      if (strokes.length < holes || strokes.some((s) => s == null)) { skipped.push({ name: labelOf(pl), profile_id: pid, reason: 'incomplete card' }); continue }
      if (!rating || !slope) { skipped.push({ name: labelOf(pl), profile_id: pid, reason: 'no course rating' }); continue }
      if (!pid && pl.claim_token) { guests.push({ name: pl.guest_name, claim_token: pl.claim_token }); continue }
      const gross = strokes.reduce((x, y) => x + y, 0)
      const p = prof(pid)
      const rid = U('f6000000', 700 + (++nR))
      const diff = holes === 9 ? r1(((gross - nine) * 113 / slope) * 2) : r1((gross - rating) * 113 / slope)
      T.rounds.push({ id: rid, profile_id: pid, gross, rating: holes === 9 ? nine : rating, slope, differential: diff, index_at_post: p ? p.index_current : null,
        played_on: W.today, course_label: r.course_label, holes_played: holes, photo_path: null, api_course_id: r.api_course_id, created_at: W.at(0, 13, 5),
        tee_name: (r.course_snapshot || {}).tee || null, par: holes === 9 ? 36 : 72 })
      posted.push({ name: labelOf(pl), gross, holes, round_id: rid, profile_id: pid })
      /* W1 (2026-09-28): a posted card scores like any other round, so the
         finish can read its league verdict through round_card */
      if (pid && typeof W.rescore === 'function') W.rescore(pid)
    }
    r.status = 'final'; r.finished_at = W.at(0, 13, 5); r.result = a.p_result || null
    return { posted, guests, skipped, casual: !!a.p_casual }
  }

  return {
    start_live_round: (a) => start(a || {}),
    live_join: () => null,
    live_set_score: (a) => setScore(a || {}),
    live_set_wolf: (a) => { const r = round((a || {}).p_live_round); if (!r) return { __error: 'No such round' }; r.game_state['h' + a.p_hole] = { v: a.p_wolf ?? null, cts: a.p_client_ts || W.now }; return null },
    live_state: (a) => stateOf((a || {}).p_live_round),
    finish_live_round: (a) => finish(a || {}),
    abandon_live_round: (a) => { const r = round((a || {}).p_live_round); if (r && r.status === 'live') r.status = 'abandoned'; return null },
  }
}
