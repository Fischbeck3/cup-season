CREATE OR REPLACE FUNCTION public.squad_lead_moments()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  r            record;
  v_leader     uuid;
  v_leader_pts numeric;
  v_second_pts numeric;
  v_prior      uuid;
  v_lname      text;
  v_pname      text;
  v_moment     text;
  v_since      timestamptz;
  v_days       integer;
  v_peak       numeric;
begin
  if new.voided or new.differential is null then return new; end if;
  if coalesce(new.source, 'app') = 'sim' then return new; end if;

  for r in
    select s.id as season_id, s.league_id
      from league_members lm
      join seasons s on s.league_id = lm.league_id
                    and s.status in ('active', 'cup_final')
                    and new.played_on between s.starts_on and s.ends_on
     where lm.profile_id = new.profile_id
  loop
    select squad_id, points into v_leader, v_leader_pts
      from v_squad_standings
     where season_id = r.season_id
     order by points desc, squad_id
     limit 1;
    if v_leader is null then continue; end if;

    select points into v_second_pts
      from v_squad_standings
     where season_id = r.season_id and squad_id <> v_leader
     order by points desc
     limit 1;

    -- a real, sole leader (nobody tied at the top)
    if v_second_pts is not null and v_leader_pts <= v_second_pts then
      continue;
    end if;

    select squad_id, since into v_prior, v_since from season_lead where season_id = r.season_id;

    if v_prior is null then
      -- first-ever strict leader: record silently, never announce
      insert into season_lead (season_id, squad_id) values (r.season_id, v_leader)
        on conflict (season_id) do update set squad_id = excluded.squad_id, since = now();
      continue;
    end if;

    if v_leader <> v_prior then
      -- the standing flipped. #23's collapse tag: the squad that just LOST
      -- first place is the other half of the story, and until now got nothing.
      -- Natural case throughout — the push function has no lowercasing pass.
      select name into v_lname from squads where id = v_leader;
      select name into v_pname from squads where id = v_prior;
      v_days := greatest(0, (now()::date - v_since::date));
      -- the biggest lead the deposed squad ever held, read from the weekly
      -- snapshots taken while they were on top
      select max(q.mine - coalesce(q.best_other, q.mine)) into v_peak
        from (
          select (select (e->>'points')::numeric
                    from jsonb_array_elements(ss.standings->'squads') e
                   where (e->>'squad_id')::uuid = v_prior) as mine,
                 (select max((e->>'points')::numeric)
                    from jsonb_array_elements(ss.standings->'squads') e
                   where (e->>'squad_id')::uuid <> v_prior) as best_other
            from standings_snapshots ss
           where ss.season_id = r.season_id and ss.captured_at >= v_since
        ) q
       where q.mine is not null;
      if v_peak is not null and v_peak >= 10 then
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead. '
                 || coalesce(v_pname, 'The field') || ' were ' || round(v_peak)
                 || ' points clear at their best. A commanding lead. Formerly.';
      elsif v_days >= 14 then
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead. '
                 || coalesce(v_pname, 'The field') || ' held first for '
                 || v_days || ' days. Once upon a time.';
      else
        v_moment := coalesce(v_lname, 'A squad') || ' take the lead, and '
                 || coalesce(v_pname, 'the field') || ' give it up. '
                 || 'Well. That didn''t last long.';
      end if;
      v_moment := upper(left(v_moment, 1)) || substr(v_moment, 2);
      insert into posts (league_id, season_id, kind, member_id, body)
      values (r.league_id, r.season_id, 'moment', null, v_moment);
      update season_lead set squad_id = v_leader, since = now()
       where season_id = r.season_id;
    end if;
  end loop;

  return new;
end $function$

