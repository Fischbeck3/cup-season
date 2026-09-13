-- VIEW v_squad_standings
CREATE OR REPLACE VIEW public.v_squad_standings AS
 WITH rp AS (
         SELECT sq.season_id,
            sq.id AS squad_id,
            COALESCE(sum(rr.points) FILTER (WHERE rr.month_rank <= COALESCE(ls.counting_cap, 999)), 0::bigint) AS pts
           FROM squads sq
             JOIN seasons se ON se.id = sq.season_id
             JOIN league_settings ls ON ls.league_id = se.league_id
             LEFT JOIN squad_members sm ON sm.squad_id = sq.id
             LEFT JOIN v_rounds_ranked rr ON rr.member_id = sm.member_id AND rr.season_id = sq.season_id
          GROUP BY sq.season_id, sq.id, ls.counting_cap
        ), adj AS (
         SELECT season_adjustments.season_id,
            season_adjustments.squad_id,
            COALESCE(sum(season_adjustments.points), 0::bigint) AS pts
           FROM season_adjustments
          WHERE season_adjustments.squad_id IS NOT NULL
          GROUP BY season_adjustments.season_id, season_adjustments.squad_id
        )
 SELECT rp.season_id,
    rp.squad_id,
    rp.pts + COALESCE(adj.pts, 0::bigint) AS points
   FROM rp
     LEFT JOIN adj ON adj.season_id = rp.season_id AND adj.squad_id = rp.squad_id;
