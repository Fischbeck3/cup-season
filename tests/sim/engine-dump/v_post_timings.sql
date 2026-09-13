-- VIEW v_post_timings
CREATE OR REPLACE VIEW public.v_post_timings AS
 SELECT created_at,
    profile_id,
    props ->> 'mode'::text AS mode,
    (props ->> 'secs'::text)::integer AS secs,
    (props ->> 'gross'::text)::integer AS gross,
    (props ->> 'holes'::text)::integer AS holes
   FROM client_events e
  WHERE event = 'post_submit'::text;
