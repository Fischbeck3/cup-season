-- ============================================================================
-- Cup Season — the handicap engine (kill the silent default-18)
--
-- THE HOLE: score_round() did `index_at_post := coalesce(index_at_post, 18)`,
-- so a member with no handicap index competed as an 18 — and could lead the
-- league on a number they never earned (natalieramirezarizona, verified).
--
-- THE FIX (approved 2026-07-15): derive the index from scores, WHS-style. Every
-- round already carries a differential ((gross − rating) × 113 ÷ slope), which
-- is index-independent — so nobody is barred and nobody types a number: the
-- index EMERGES from play.
--   • handicap_index_asof(): WHS-lite off the best of the last 20 differentials
--     (establishes at 3 rounds: 3→low−2, 4→low−1, 5→low, then best-N averages).
--   • score_round(): index_at_post = caller > the golfer's standing index >
--     engine(prior rounds) > this round's own differential (first-round
--     provisional). NEVER 18.
--   • an AFTER-INSERT trigger keeps profiles.index_current current from scores,
--     UNLESS the golfer set it by hand (index_source='self'/'ghin' sticks —
--     the manual override, socially policed).
--   • BACKFILL: re-snapshot every existing round's index_at_post on a rolling
--     WHS basis and recompute everyone's index_current → the views rescore, and
--     18-inflated leads (Natalie) self-correct to real handicaps.
-- Touches spec §2 scoring — promote to v1.1.
-- ============================================================================

alter table public.profiles add column if not exists index_source text;

-- ---- WHS-lite index from a golfer's differentials (optionally "as of" a round)
create or replace function public.handicap_index_asof(
  p_profile uuid, p_before_date date, p_before_id uuid
) returns numeric
language sql stable security definer set search_path = public as $$
  with d as (
    select r.differential
      from rounds r
     where r.profile_id = p_profile and not r.voided
       and coalesce(r.source,'app') <> 'sim' and r.differential is not null
       and (p_before_date is null or (r.played_on, r.id) < (p_before_date, p_before_id))
     order by r.played_on desc, r.id desc
     limit 20
  ),
  cnt as (select count(*)::int c from d),
  params as (
    select c,
      case when c<3 then 0 when c<=5 then 1 when c<=8 then 2 when c<=11 then 3
           when c<=14 then 4 when c<=16 then 5 when c=17 then 6 when c=18 then 7
           else 8 end as m,
      case when c=3 then 2.0 when c=4 then 1.0 when c=6 then 1.0
           when c in (9,10,11) then 1.0 else 0 end as adj
      from cnt
  ),
  best as (
    select differential, row_number() over (order by differential asc) rn from d
  )
  select case when (select c from cnt) < 3 then null
    else round(avg(differential) filter (where rn <= (select m from params))
               - (select adj from params), 1) end
    from best;
$$;
grant execute on function public.handicap_index_asof(uuid, date, uuid) to authenticated;

create or replace function public.handicap_index(p_profile uuid)
returns numeric language sql stable security definer set search_path = public as $$
  select public.handicap_index_asof(p_profile, null, null);
$$;
grant execute on function public.handicap_index(uuid) to authenticated;

-- ---- score_round(): the index snapshot, no more blind 18 ---------------------
create or replace function public.score_round() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- differential first (index-independent)
  if new.holes_played = 9 and new.nine_rating is not null then
    new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;

  -- index snapshot: caller-provided > standing index > engine(prior rounds) >
  -- this round's own differential (first-round provisional). NEVER a blind 18.
  if new.index_at_post is null then
    select index_current into new.index_at_post from profiles where id = new.profile_id;
  end if;
  if new.index_at_post is null then
    new.index_at_post := handicap_index_asof(new.profile_id, new.played_on, new.id);
  end if;
  new.index_at_post := coalesce(new.index_at_post, new.differential);

  return new;
end $$;

-- ---- keep index_current fresh from scores (unless manually locked) -----------
create or replace function public.round_refresh_index() returns trigger
language plpgsql security definer set search_path = public as $$
declare v_src text; v_auto numeric;
begin
  if new.voided then return new; end if;
  select index_source into v_src from profiles where id = new.profile_id;
  if coalesce(v_src, 'app') = 'app' then               -- 'self'/'ghin' stick
    v_auto := handicap_index(new.profile_id);
    if v_auto is not null then
      update profiles set index_current = v_auto where id = new.profile_id;
    end if;
  end if;
  return new;
end $$;
drop trigger if exists round_refresh_index_trg on public.rounds;
create trigger round_refresh_index_trg after insert on public.rounds
  for each row execute function public.round_refresh_index();

-- ---- set_index: a manual set now LOCKS to 'self' (sticks vs the engine) ------
create or replace function public.set_index(p_index numeric) returns void
language plpgsql security definer set search_path = public as $$
declare v_old numeric; v_name text;
begin
  if p_index is null or p_index < -10 or p_index > 54 then
    raise exception 'index out of range';
  end if;
  select index_current, display_name into v_old, v_name from profiles where id = auth.uid();
  if not found then raise exception 'no profile'; end if;

  update profiles set index_current = p_index, index_source = 'self' where id = auth.uid();
  if v_old is not distinct from p_index then return; end if;

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || case when v_old is null
           then ' set their index to ' || p_index
           else ' adjusted their index ' || v_old || ' → ' || p_index end
    from league_members lm where lm.profile_id = auth.uid();
end $$;
grant execute on function public.set_index(numeric) to authenticated;

-- ---- finish_live_round(): drop the "no index" skip — the engine handles it ---
-- (post the card with index_at_post NULL; score_round() resolves it)
create or replace function public.finish_live_round(
  p_live_round uuid, p_cards jsonb, p_casual boolean default false
) returns jsonb
language plpgsql security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  lr live_rounds%rowtype; v_starter uuid;
  v_snap jsonb; v_rating numeric; v_slope int; v_nine numeric;
  v_card jsonb; v_pl live_round_players%rowtype;
  v_pid uuid; v_strokes int[]; v_n int; v_holes int; v_gross int;
  v_round uuid; h int;
  v_posted jsonb := '[]'; v_guests jsonb := '[]'; v_skipped jsonb := '[]';
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into lr from live_rounds where id = p_live_round;
  if lr.id is null then raise exception 'No such round'; end if;

  select profile_id into v_starter from league_members where id = lr.started_by;
  if v_starter is distinct from v and not exists (
    select 1 from live_round_players p join league_members m on m.id = p.member_id
     where p.live_round_id = p_live_round and m.profile_id = v) then
    raise exception 'You are not in this round';
  end if;
  if lr.status = 'final' then return jsonb_build_object('already_final', true); end if;

  v_snap := coalesce(lr.course_snapshot, '{}'::jsonb);
  v_rating := nullif(v_snap->>'rating','')::numeric;
  v_slope  := nullif(v_snap->>'slope','')::int;
  v_nine   := nullif(v_snap->>'nine_rating','')::numeric;

  for v_card in select * from jsonb_array_elements(coalesce(p_cards, '[]'::jsonb)) loop
    select * into v_pl from live_round_players
     where id = (v_card->>'player_id')::uuid and live_round_id = p_live_round;
    if v_pl.id is null then continue; end if;

    if v_pl.member_id is null then
      v_guests := v_guests || jsonb_build_object('name', v_pl.guest_name, 'claim_token', v_pl.claim_token);
      continue;
    end if;

    select profile_id into v_pid from league_members where id = v_pl.member_id;

    v_strokes := array(select nullif(x,'null')::int from jsonb_array_elements_text(coalesce(v_card->'strokes','[]'::jsonb)) x);
    v_n := coalesce(array_length(v_strokes, 1), 0);
    v_holes := null;
    if v_n >= 18 and (select count(*) from unnest(v_strokes[1:18]) s where s is null) = 0 then
      v_holes := 18;
    elsif v_n >= 9 and (select count(*) from unnest(v_strokes[1:9]) s where s is null) = 0
          and (v_n < 10 or (select count(*) from unnest(v_strokes[10:18]) s where s is not null) = 0) then
      v_holes := 9;
    end if;

    if p_casual then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'casual'); continue;
    end if;
    if v_holes is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'incomplete card'); continue;
    end if;
    if v_rating is null or v_slope is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no course rating'); continue;
    end if;
    if v_holes = 9 and v_nine is null then
      v_skipped := v_skipped || jsonb_build_object('name', playerlabel(v_pid), 'reason', 'no 9-hole rating'); continue;
    end if;

    v_gross := (select coalesce(sum(s),0) from unnest(v_strokes[1:v_holes]) s);

    -- index_at_post omitted → score_round() resolves it via the engine
    insert into rounds (profile_id, live_round_id, course_id, tee_id, course_label,
                        played_on, holes_played, gross, rating, slope, nine_rating,
                        source, attested, index_source_at_post)
    values (v_pid, p_live_round, lr.course_id, lr.tee_id, lr.course_label,
            current_date, v_holes, v_gross, v_rating, v_slope, v_nine,
            'live', true, 'app')
    returning id into v_round;

    for h in 1..v_holes loop
      if v_strokes[h] is not null then
        insert into round_holes (round_id, hole_number, strokes) values (v_round, h, v_strokes[h]);
      end if;
    end loop;

    v_posted := v_posted || jsonb_build_object('name', playerlabel(v_pid), 'gross', v_gross, 'holes', v_holes);
  end loop;

  update live_rounds set status = 'final', finished_at = now() where id = p_live_round;
  return jsonb_build_object('posted', v_posted, 'guests', v_guests, 'skipped', v_skipped, 'casual', p_casual);
end $$;
grant execute on function public.finish_live_round(uuid, jsonb, boolean) to authenticated;

-- ---- BACKFILL: rolling re-snapshot + establish everyone's index -------------
do $$
declare p record; r record; v_idx numeric;
begin
  for p in select id from profiles where deleted_at is null loop
    for r in
      select id, played_on, differential from rounds
       where profile_id = p.id and not voided and coalesce(source,'app') <> 'sim'
         and differential is not null
       order by played_on, id
    loop
      v_idx := coalesce(handicap_index_asof(p.id, r.played_on, r.id), r.differential);
      update rounds set index_at_post = v_idx where id = r.id;
    end loop;
    if coalesce((select index_source from profiles where id = p.id), 'app') = 'app' then
      v_idx := handicap_index(p.id);
      if v_idx is not null then
        update profiles set index_current = v_idx where id = p.id;
      end if;
    end if;
  end loop;
end $$;
