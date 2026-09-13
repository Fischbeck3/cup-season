-- VIEW v_rounds_ranked
CREATE OR REPLACE VIEW public.v_rounds_ranked AS
 WITH scored AS (
         SELECT lm.id AS member_id,
            s.id AS season_id,
            r.id AS round_id,
            r.profile_id,
            r.played_on,
            r.holes_played,
            r.source,
            r.attested,
            r.differential,
            r.index_at_post,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0, 1) AS playing_index,
            round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1) AS pvi,
                CASE
                    WHEN r.holes_played = 9 THEN ceil(cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))::numeric / 2::numeric)::integer
                    ELSE cup_points(round(r.index_at_post * ls.handicap_allowance::numeric / 100.0 - r.differential, 1))
                END AS points,
                CASE
                    WHEN r.holes_played = 9 THEN 0.5
                    ELSE 1.0
                END AS floor_credit
           FROM rounds r
             JOIN league_members lm ON lm.profile_id = r.profile_id
             JOIN league_settings ls ON ls.league_id = lm.league_id
             JOIN seasons s ON s.league_id = lm.league_id AND (s.status = ANY (ARRAY['active'::text, 'cup_final'::text, 'complete'::text])) AND r.played_on >= s.starts_on AND r.played_on <= s.ends_on
          WHERE NOT r.voided AND (ls.sim_rounds_allowed OR COALESCE(r.source, 'app'::text) <> 'sim'::text) AND (ls.nine_hole_allowed OR r.holes_played = 18) AND (lm.suspended_at IS NULL OR r.created_at < lm.suspended_at) AND (lm.left_at IS NULL OR r.created_at < lm.left_at)
        )
 SELECT member_id,
    season_id,
    round_id,
    profile_id,
    played_on,
    holes_played,
    source,
    attested,
    differential,
    index_at_post,
    playing_index,
    pvi,
    points,
    floor_credit,
    row_number() OVER (PARTITION BY member_id, season_id, (date_trunc('month'::text, played_on::timestamp with time zone)) ORDER BY points DESC, pvi DESC, played_on DESC) AS month_rank
   FROM scored;
