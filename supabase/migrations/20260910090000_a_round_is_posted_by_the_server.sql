-- Cup Season — a round is posted by the server (D227, D229, D239, IOS-030).
--
-- R11 · post_round(...) -> jsonb{round, epilogue}
--
-- The quick post was the one consequential DIRECT WRITE left on either client:
-- `insert into rounds (...) select id`, eleven columns, with the season the
-- golfer happened to be looking at stamped on it (`preferredLeague` on the
-- phone, `CS.season` on the web). L-03 says a write with game consequences is
-- an RPC, and D229 says Home has no open league — so the season a round posts
-- into stops being a client's opinion and becomes a server derivation.
--
-- WHAT THE DERIVATION IS, AND WHAT IT IS NOT. `season_id` on `rounds` is a
-- STAMP, not the scorer: `v_rounds_ranked` joins every membership × season
-- whose window contains `played_on` and applies THAT membership's own
-- allowance, so a golfer in two seasons already scores in both and always did
-- (L-13). What the stamp decides is which season the receipt and the epilogue
-- talk about. Here it is derived from `p_played_on` against every living
-- membership's window — an active season first, then the one closing soonest —
-- which is the multi-league case one client-chosen `season_id` could never
-- express, and which is why the client no longer sends one.
--
-- THE TWO SKEW RETRIES MOVE INSIDE. `PostService.insertRound` dropped
-- `api_course_id` and then `photo_path` on any error and retried. Both are
-- garnish and neither may cost a golfer their score, so the server nulls an
-- `api_course_id` that names no cached course and a `photo_path` that is not
-- under the caller's own prefix, and posts the round anyway.
--
-- R7 · round_epilogue gains its movement, additively: `rank_before`,
-- `rank_after`, `of`, `passed[]`, `gap_to_next_after` — and `played_with`,
-- because the next act's fourth and fifth rungs are about a person. Every key
-- that was there is still there and still means what it meant; a client that
-- has not shipped yet reads straight past the new ones.
--
-- Grants: L-04. Every new client-called function is granted to `authenticated`
-- and revoked from `public, anon`.

-- ---------------------------------------------------------------------------
-- R7 · the epilogue, with what the round moved
-- ---------------------------------------------------------------------------

create or replace function public.round_epilogue(p_round uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v_prof   uuid;
  v_played date;
  v_gross  int;
  v_holes  int;
  v_season uuid;
  v_member uuid;
  v_cap    int;
  v_pvi    numeric := null;
  v_points int     := null;
  v_rank   int     := null;
  v_earned jsonb   := '[]'::jsonb;
  v_rivals jsonb   := '[]'::jsonb;
  v_before int     := null;
  v_after  int     := null;
  v_of     int     := null;
  v_passed jsonb   := '[]'::jsonb;
  v_gap    numeric := null;
  v_with   jsonb   := '[]'::jsonb;
begin
  select profile_id, played_on, gross, holes_played, season_id
    into v_prof, v_played, v_gross, v_holes, v_season
    from rounds where id = p_round;

  if v_prof is null or v_prof <> auth.uid() then
    return null;
  end if;

  if v_season is not null then
    select pvi, points, month_rank
      into v_pvi, v_points, v_rank
      from v_rounds_ranked
     where round_id = p_round and season_id = v_season
     limit 1;
  end if;

  select coalesce(jsonb_agg(
           jsonb_build_object('kind', kind, 'label', label)
           order by case kind
             when 'personal_best' then 0 when 'sub_80' then 1
             when 'sub_90' then 2 when 'sub_100' then 3
             when 'first_round' then 4 else 5 end), '[]'::jsonb)
    into v_earned
    from achievements
   where profile_id = v_prof and round_id = p_round;

  select coalesce(jsonb_agg(
           jsonb_build_object('name', mr.display_name, 'handle', mr.handle,
             'wins', mr.wins, 'losses', mr.losses, 'ties', mr.ties, 'lead', mr.lead,
             'rivalry_name', mr.rivalry_name)
           order by mr.meetings desc), '[]'::jsonb)
    into v_rivals
    from my_rivalries() mr
   where exists (
     select 1
       from v_rounds_ranked rr
       join league_members lm1 on lm1.profile_id = v_prof
       join league_members lm2 on lm2.league_id = lm1.league_id
                              and lm2.profile_id = mr.opponent
      where rr.profile_id = mr.opponent
        and rr.member_id  = lm2.id
        and date_trunc('week', rr.played_on) = date_trunc('week', v_played)
   );

  -- R7 · the movement. The table is computed twice off the SAME view the
  -- engine uses — once whole, once with this round taken out — so "rank
  -- before" is a count over a named read and not a memory of a Sunday
  -- snapshot (A-4: `prev_rank` is a Sunday figure and cannot answer what a
  -- Tuesday round changed). Both sides are solo standings; a squads season
  -- has no personal rank to move, so it stays null and nothing renders.
  if v_season is not null then
    begin
      select lm.id, ls.counting_cap
        into v_member, v_cap
        from league_members lm
        join seasons s on s.id = v_season and s.league_id = lm.league_id
        join league_settings ls on ls.league_id = lm.league_id
       where lm.profile_id = v_prof
       limit 1;

      if v_member is not null and not exists (
        select 1 from seasons s
         where s.id = v_season
           and exists (select 1 from league_settings ls
                        where ls.league_id = s.league_id and ls.season_format = 'squads')) then
        with base as (
          select lm.id as member_id, p.display_name
            from league_members lm
            join seasons s on s.id = v_season and s.league_id = lm.league_id
            join profiles p on p.id = lm.profile_id
        ),
        after_rounds as (
          select rr.member_id, rr.points, rr.month_rank
            from v_rounds_ranked rr
           where rr.season_id = v_season
        ),
        before_rounds as (
          -- month_rank is recomputed from scratch without this round: taking a
          -- round out can promote another of the golfer's own rounds into the
          -- counting set, and re-using the whole table's rank would miss it.
          select rr.member_id, rr.points,
                 row_number() over (partition by rr.member_id, date_trunc('month', rr.played_on)
                                    order by rr.points desc, rr.pvi desc, rr.played_on desc) as month_rank
            from v_rounds_ranked rr
           where rr.season_id = v_season and rr.round_id <> p_round
        ),
        tally as (
          select b.member_id, b.display_name,
                 coalesce((select sum(a.points) from after_rounds a
                            where a.member_id = b.member_id and a.month_rank <= coalesce(v_cap, 999)), 0) as pts_after,
                 coalesce((select sum(x.points) from before_rounds x
                            where x.member_id = b.member_id and x.month_rank <= coalesce(v_cap, 999)), 0) as pts_before
            from base b
        ),
        ranked as (
          select t.*,
                 rank() over (order by t.pts_after desc, t.display_name)  as rk_after,
                 rank() over (order by t.pts_before desc, t.display_name) as rk_before,
                 count(*) over () as of_n
            from tally t
        )
        select r.rk_before, r.rk_after, r.of_n,
               coalesce((select jsonb_agg(firstname(o.display_name) order by o.rk_before)
                           from ranked o
                          where o.member_id <> r.member_id
                            and o.rk_before < r.rk_before
                            and o.rk_after  > r.rk_after), '[]'::jsonb),
               (select min(o.pts_after) - r.pts_after from ranked o where o.rk_after < r.rk_after)
          into v_before, v_after, v_of, v_passed, v_gap
          from ranked r
         where r.member_id = v_member;
      end if;
    exception when others then
      v_before := null; v_after := null; v_of := null; v_passed := '[]'::jsonb; v_gap := null;
    end;
  end if;

  -- who was out there (C-2). A claim with a state: `confirmed` is null until
  -- the other golfer says so (D239 rule 2), and a tag is never a vouch (L-19).
  if to_regclass('public.round_players') is not null then
    begin
      execute $q$
        select coalesce(jsonb_agg(jsonb_build_object(
                 'profile_id', rp.profile_id,
                 'name',       firstname(p.display_name),
                 'confirmed',  rp.confirmed_at is not null,
                 'shares_season', exists (
                    select 1 from league_members a
                      join league_members b on b.league_id = a.league_id
                     where a.profile_id = $1 and b.profile_id = rp.profile_id))
                 order by p.display_name), '[]'::jsonb)
          from round_players rp join profiles p on p.id = rp.profile_id
         where rp.round_id = $2
      $q$ into v_with using v_prof, p_round;
    exception when others then
      v_with := '[]'::jsonb;
    end;
  end if;

  return jsonb_build_object(
    'gross', v_gross, 'holes', v_holes,
    'pvi', v_pvi, 'points', v_points, 'month_rank', v_rank,
    'earned', v_earned, 'rivals', v_rivals,
    -- R7, all additive
    'season_id', v_season,
    'rank_before', v_before, 'rank_after', v_after, 'of', v_of,
    'passed', v_passed, 'gap_to_next_after', v_gap,
    'played_with', v_with
  );
end $$;

revoke all on function public.round_epilogue(uuid) from public, anon;
grant execute on function public.round_epilogue(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- R11 · post_round
-- ---------------------------------------------------------------------------

create or replace function public.post_round(
  p_gross        int,
  p_rating       numeric,
  p_slope        int,
  p_holes_played int     default 18,
  p_nine_rating  numeric default null,
  p_course_id    text    default null,
  p_course_label text    default null,
  p_played_on    date    default current_date,
  p_photo_path   text    default null,
  p_played_with  uuid[]  default '{}'::uuid[]
) returns jsonb
language plpgsql volatile security definer set search_path = public as $$
declare
  v_me      uuid := auth.uid();
  v_played  date := coalesce(p_played_on, current_date);
  v_holes   int  := case when p_holes_played = 9 then 9 else 18 end;
  v_label   text := nullif(btrim(coalesce(p_course_label, '')), '');
  v_course  text := nullif(btrim(coalesce(p_course_id, '')), '');
  v_photo   text := nullif(btrim(coalesce(p_photo_path, '')), '');
  v_season  uuid;
  v_league  uuid;
  v_lname   text;
  v_squad   text;
  v_round   uuid;
  v_tagged  int := 0;
begin
  if v_me is null then
    raise exception 'Sign in to post a round.' using errcode = '42501';
  end if;
  if p_gross is null or p_gross < 18 or p_gross > 200 then
    raise exception 'That score is not a round — check the gross.' using errcode = '22023';
  end if;
  if p_rating is null or p_rating < 25 or p_rating > 90 then
    raise exception 'Type the rating off the scorecard — it is on the back of the card.' using errcode = '22023';
  end if;
  if p_slope is null or p_slope < 55 or p_slope > 155 then
    raise exception 'Type the slope off the scorecard — it is on the back of the card.' using errcode = '22023';
  end if;
  if v_label is null then
    raise exception 'Type the course you played — it goes on the card.' using errcode = '22023';
  end if;
  if v_played > current_date then
    raise exception 'That round has not been played yet.' using errcode = '22023';
  end if;

  -- garnish never costs a golfer their score: an api course id that names no
  -- cached course, and a photo path that is not the caller's own, are dropped
  -- and the round posts. (These are the two client-side skew retries, moved in.)
  if v_course is not null and not exists (select 1 from api_courses c where c.id = v_course) then
    v_course := null;
  end if;
  if v_photo is not null and v_photo not like (v_me::text || '/%') then
    v_photo := null;
  end if;

  -- D229 · the season is DERIVED, never chosen by the client. An active season
  -- first, then the one that closes soonest; a round outside every window
  -- posts with no stamp and still builds the golfer's number (L-13).
  select s.id, s.league_id, l.name
    into v_season, v_league, v_lname
    from league_members lm
    join seasons s on s.league_id = lm.league_id
                  and s.status in ('active', 'cup_final', 'complete')
                  and v_played between s.starts_on and s.ends_on
    join leagues l on l.id = s.league_id
   where lm.profile_id = v_me
     and lm.suspended_at is null
   order by (s.status = 'active') desc, s.ends_on asc, s.id
   limit 1;

  if v_season is not null then
    select q.name into v_squad
      from squad_members sm
      join squads q on q.id = sm.squad_id
      join league_members lm on lm.id = sm.member_id
     where lm.profile_id = v_me and q.season_id = v_season
     limit 1;
  end if;

  insert into rounds (profile_id, gross, rating, nine_rating, slope, holes_played,
                      source, played_on, course_label, api_course_id, season_id, photo_path)
  values (v_me, p_gross, p_rating,
          case when v_holes = 9 then p_nine_rating else null end,
          p_slope, v_holes, 'quick', v_played, v_label, v_course, v_season, v_photo)
  returning id into v_round;

  -- C-2 · who was out there. Bounded by `home_feed`'s own circle (buddies ∪
  -- league mates ∪ event co-players) and capped at seven, so a tag is a claim
  -- about somebody you actually play with (D239 rule 3). No confirmation is
  -- written: `confirmed_at` stays null until the other golfer answers.
  if to_regclass('public.round_players') is not null
     and p_played_with is not null and array_length(p_played_with, 1) is not null then
    execute $q$
      with circle as (
        select case when requester = $1 then addressee else requester end as pid
          from friendships
         where status = 'accepted' and (requester = $1 or addressee = $1)
        union
        select lm2.profile_id
          from league_members lm1 join league_members lm2 on lm2.league_id = lm1.league_id
         where lm1.profile_id = $1
        union
        select ep2.profile_id
          from event_players ep1 join event_players ep2 on ep2.event_id = ep1.event_id
         where ep1.profile_id = $1
      ),
      want as (select distinct unnest($3::uuid[]) as pid)
      insert into round_players (round_id, profile_id)
      select $2, w.pid
        from want w
       where w.pid <> $1
         and w.pid in (select pid from circle)
       limit 7
      on conflict do nothing
    $q$ using v_me, v_round, p_played_with;
    get diagnostics v_tagged = row_count;
  end if;

  return jsonb_build_object(
    'round', jsonb_build_object(
      'id', v_round,
      'season_id', v_season,
      'league_id', v_league,
      'league_name', v_lname,
      'squad', v_squad,
      'played_on', v_played,
      'gross', p_gross,
      'holes_played', v_holes,
      'course_label', v_label,
      'api_course_id', v_course,
      'photo_path', v_photo,
      'counts', v_season is not null,
      'tagged', v_tagged),
    'epilogue', round_epilogue(v_round)
  );
end $$;

revoke all on function public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[]) from public, anon;
grant execute on function public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[]) to authenticated;

-- ---------------------------------------------------------------------------
-- self-check — catalogue only. L-05: a self-check never touches a real row.
-- ---------------------------------------------------------------------------
do $check$
declare
  d text;
  n int;
begin
  -- every new argument defaults, so a client that ships before this migration
  -- and one that ships after both call a function that answers (CLAUDE.md).
  select pronargdefaults into n from pg_proc
   where oid = 'public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[])'::regprocedure;
  if coalesce(n, 0) <> 7 then
    raise exception 'post_round: expected 7 defaulted arguments, found %', coalesce(n, 0);
  end if;

  if has_function_privilege('anon', 'public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[])', 'execute')
     or has_function_privilege('public', 'public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[])', 'execute') then
    raise exception 'post_round: anon or public can execute it (L-04)';
  end if;
  if not has_function_privilege('authenticated', 'public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[])', 'execute') then
    raise exception 'post_round: authenticated cannot execute it (L-04)';
  end if;

  select prosrc into d from pg_proc where oid = 'public.round_epilogue(uuid)'::regprocedure;
  if d not like '%rank_before%' or d not like '%rank_after%' or d not like '%gap_to_next_after%' or d not like '%''passed''%' then
    raise exception 'round_epilogue: R7 keys missing from the stored definition';
  end if;

  select prosrc into d from pg_proc
   where oid = 'public.post_round(int, numeric, int, int, numeric, text, text, date, text, uuid[])'::regprocedure;
  -- the season is derived here or it is not derived at all
  if d not like '%from league_members lm%' or d like '%p_season%' then
    raise exception 'post_round: the season must be derived server-side, never taken as an argument (D229)';
  end if;
end $check$;
