-- VIEW v_growth_funnel
CREATE OR REPLACE VIEW public.v_growth_funnel AS
 SELECT date_trunc('week'::text, at)::date AS week,
    kind,
    league_id,
    count(*) FILTER (WHERE node = 'artifact_shared'::text) AS shared,
    count(*) FILTER (WHERE node = 'link_opened'::text) AS opened,
    count(*) FILTER (WHERE node = 'claim_started'::text) AS claim_started,
    count(*) FILTER (WHERE node = 'profile_created'::text) AS profiles,
    count(*) FILTER (WHERE node = 'first_round_posted'::text) AS first_rounds
   FROM growth_events
  GROUP BY (date_trunc('week'::text, at)::date), kind, league_id
  ORDER BY (date_trunc('week'::text, at)::date) DESC, kind, league_id;
