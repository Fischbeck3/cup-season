-- open_week_clash(p_season uuid) oid=21932
CREATE OR REPLACE FUNCTION public.open_week_clash(p_season uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se       record;
  v_local  date;
  v_wk     integer;
  v_total  integer;
  v_a      uuid;   -- league_members.id
  v_b      uuid;
  v_id     uuid;
  v_a_name text;
  v_b_name text;
  v_riv    text;
  v_end    date;
  v_roster integer;
  v_same   boolean := false;
  v_quiet  boolean := false;
  v_lws    date;
  v_lwe    date;
begin
  select * into se from seasons where id = p_season;
  if se.id is null or se.status not in ('active','cup_final') then
    return null;
  end if;

  v_local := (now() at time zone se.timezone)::date;
  if v_local < se.starts_on or v_local > se.ends_on then
    return null;                                   -- no clash outside the season
  end if;

  v_total := ceil((se.ends_on - se.starts_on + 1) / 7.0);
  v_wk    := floor((v_local - se.starts_on) / 7)::int + 1;
  if v_wk < 1 or v_wk > v_total then
    return null;
  end if;

  -- idempotent: this week's clash already stands
  select id into v_id from week_clashes
   where season_id = p_season and week_no = v_wk;
  if v_id is not null then
    return v_id;
  end if;

  -- the pairing (see header for the cascade + rotation-guarantee reasoning)
  with mem as (            -- active members: on the roster, not tombstoned
    select lm.id, lm.profile_id, p.display_name
      from league_members lm
      join profiles p on p.id = lm.profile_id and p.deleted_at is null
     where lm.league_id = se.league_id
  ),
  feat as (                -- each member's most recent spotlight week
    select m.id, max(wc.week_no) as last_wk
      from mem m
      join week_clashes wc
        on wc.season_id = p_season
       and (wc.a_member = m.id or wc.b_member = m.id)
     group by m.id
  ),
  stand as (
    select member_id, points from v_individual_standings
     where season_id = p_season
  ),
  pairs as (
    select a.id as a_id, b.id as b_id,
           a.display_name as a_name, b.display_name as b_name,
           greatest(coalesce(fa.last_wk, 0), coalesce(fb.last_wk, 0)) as staleness,
           exists (select 1 from rivalry_names rn
                    where rn.pair_low  = least(a.profile_id, b.profile_id)
                      and rn.pair_high = greatest(a.profile_id, b.profile_id)) as named,
           abs(coalesce(sa.points, 0) - coalesce(sb.points, 0)) as gap,
           a.profile_id as a_pid, b.profile_id as b_pid
      from mem a
      join mem b on a.id < b.id
      left join feat  fa on fa.id = a.id
      left join feat  fb on fb.id = b.id
      left join stand sa on sa.member_id = a.id
      left join stand sb on sb.member_id = b.id
  ),
  pick as (
    select * from pairs
     order by staleness asc,        -- rotation guarantee: the most-due pair first
              named desc,           -- then D52's cascade: named rivalry (D21)
              gap asc,              -- → closest table gap
              a_id, b_id            -- → deterministic
     limit 1
  )
  select p.a_id, p.b_id, p.a_name, p.b_name,
         (select rn.name from rivalry_names rn
           where rn.pair_low  = least(p.a_pid, p.b_pid)
             and rn.pair_high = greatest(p.a_pid, p.b_pid))
    into v_a, v_b, v_a_name, v_b_name, v_riv
    from pick p;

  if v_a is null or v_b is null then
    return null;                                   -- solo league (<2 active) — skip
  end if;

  insert into week_clashes (season_id, week_no, a_member, b_member)
  values (p_season, v_wk, v_a, v_b)
  on conflict (season_id, week_no) do nothing
  returning id into v_id;

  if v_id is null then                             -- lost a race — take the standing row
    select id into v_id from week_clashes
     where season_id = p_season and week_no = v_wk;
    return v_id;
  end if;

  -- D207 · is there anything to say? The active roster size, whether last
  -- week paired the same two, and whether either of them played last week.
  -- 20260902100000 gave league_members a `suspended_at`; a suspended member
  -- cannot post, so they are not part of the roster this question asks about.
  -- (The pairing CTE above still ignores suspension — a prod gap named in the
  -- header, not closed here.)
  select count(*) into v_roster
    from league_members lm
    join profiles p on p.id = lm.profile_id and p.deleted_at is null
   where lm.league_id = se.league_id
     and lm.suspended_at is null;

  if v_wk > 1 then
    v_lws := se.starts_on + 7 * (v_wk - 2);
    v_lwe := v_lws + 6;
    select true into v_same from week_clashes wc
     where wc.season_id = p_season and wc.week_no = v_wk - 1
       and least(wc.a_member, wc.b_member) = least(v_a, v_b)
       and greatest(wc.a_member, wc.b_member) = greatest(v_a, v_b);
    v_same := coalesce(v_same, false);
    if v_same then
      v_quiet := not exists (
        select 1 from v_rounds_ranked rr
         where rr.season_id = p_season
           and rr.member_id in (v_a, v_b)
           and rr.played_on between v_lws and v_lwe);
    end if;
  end if;

  if v_same and v_quiet then
    return v_id;                                   -- the row stands; the board stays quiet
  end if;

  -- the open story (only when this call actually opened the week)
  v_end := se.starts_on + 7 * v_wk - 1;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case
            when v_wk = 1 and v_roster = 2 then
              case when v_riv is not null and btrim(v_riv) <> ''
                   then '“' || btrim(v_riv) || '” is on again: '
                        || firstname(v_a_name) || ' v ' || firstname(v_b_name) || '. '
                   else '' end
              || 'It''s the two of you — every week is the clash.'
            when v_riv is not null and btrim(v_riv) <> '' then
              '“' || btrim(v_riv) || '” is on again: '
              || firstname(v_a_name) || ' v ' || firstname(v_b_name) || '.'
              || ' Best round of the week takes it.'
            else
              'The clash: ' || firstname(v_a_name) || ' v '
              || firstname(v_b_name) || '.'
              || ' Best round of the week takes it.'
          end);

  return v_id;
end $function$

