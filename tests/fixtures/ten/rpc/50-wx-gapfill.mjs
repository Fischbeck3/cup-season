/* Cup Season · ten-capture: reads found by the WX runs that no family module
 * answers (WX lane, 2026-09-28). Each is a port of the RPC's latest SQL over
 * the synthetic world, named beside it. Loaded after 10-40, and only FILLS a
 * handler another module did not define. */
export default function install(W) {
  const T = W.tables
  const out = {}
  const fill = (k, fn) => { if (!W.handlers[k] || /^\(\) => (\[\]|null|0)$/.test(String(W.handlers[k]).trim())) out[k] = fn }

  /* 20261104090000_the_round_that_counts_explained.sql -- my_month_counters +
     month_counters: per membership in an active/cup_final season covering the
     date, the month's counting rounds (inside the cap), their count and the
     lowest points among them */
  fill('my_month_counters', (a) => {
    if (!W.V.session) return []
    const on = String((a && a.p_on) || W.today).slice(0, 10)
    const month = on.slice(0, 7)
    const rows = []
    for (const m of T.league_members.filter((x) => x.profile_id === W.me && !x.left_at)) {
      const l = T.leagues.find((x) => x.id === m.league_id)
      const ls = T.league_settings.find((x) => x.league_id === m.league_id)
      for (const s of T.seasons.filter((x) => x.league_id === m.league_id && ['active', 'cup_final'].includes(x.status) && on >= x.starts_on && on <= x.ends_on)) {
        const cap = ls ? ls.counting_cap : null
        const c = T.v_rounds_ranked.filter((vr) => vr.member_id === m.id && vr.season_id === s.id && String(vr.played_on).slice(0, 7) === month && (cap == null || cap <= 0 || vr.month_rank <= cap))
        rows.push({ league_id: m.league_id, league_name: l ? l.name : null, season_id: s.id, cap, structure: ls ? ls.structure : null,
          counters: { cap, used: c.length, worst: c.length ? Math.min(...c.map((x) => x.points)) : null, month } })
      }
    }
    return rows.sort((x, y) => String(x.league_name).localeCompare(String(y.league_name)))
  })
  return out
}
