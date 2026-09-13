-- rederive_achievements(p_profile uuid) oid=29032
CREATE OR REPLACE FUNCTION public.rederive_achievements(p_profile uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'first_round', 'First round posted', r.played_on, r.id,
         jsonb_build_object('gross', r.gross)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and coalesce(r.source, 'app') <> 'sim'
   order by r.played_on, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select distinct on (thr.t) r.profile_id, 'sub_' || thr.t, 'Broke ' || thr.t,
         r.played_on, r.id, jsonb_build_object('gross', r.gross)
    from rounds r
    cross join unnest(array[100, 90, 80]) as thr(t)
   where r.profile_id = p_profile
     and not r.voided and r.holes_played = 18 and r.gross is not null
     and r.gross < thr.t and coalesce(r.source, 'app') <> 'sim'
   order by thr.t, r.played_on, r.id
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'personal_best', 'Personal best',
         r.played_on, r.id, jsonb_build_object('diff', r.differential)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and r.differential is not null and coalesce(r.source, 'app') <> 'sim'
   order by r.differential asc, r.played_on desc, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;
end $function$

