-- ============================================================================
-- Cup Season — the pot goes real + the season announces itself
--
-- 1. mark_buy_in(): the Pro toggles a member's buy-in on the buy_ins table
--    (006 schema, PK season_id+member_id). Security-definer, commissioner-
--    gated at the database. Marking PAID posts the running tally to the
--    board ("DANNY'S BUY-IN IS IN — 4/5 COLLECTED"); unmarking is a quiet
--    correction. The post carries the Pro's member_id so the webhook's
--    author-exclusion spares the person doing the marking.
--
-- 2. Kickoff post: seasons gain a kicked_off sentinel (same idempotence
--    pattern as month_closed). daily_season_tick posts "THE SEASON IS LIVE"
--    to the board the first tick on/after starts_on. Existing seasons that
--    already started are backfilled kicked_off=true — no retroactive posts.
-- ============================================================================

alter table public.seasons add column if not exists kicked_off boolean not null default false;
update public.seasons set kicked_off = true where starts_on <= current_date;

create or replace function public.mark_buy_in(p_season uuid, p_member uuid, p_paid boolean)
returns void
language plpgsql security definer
set search_path = public
as $$
declare
  v_league uuid;
  v_stake  integer;
  v_name   text;
  v_paid_n integer;
  v_total  integer;
begin
  select league_id into v_league from seasons where id = p_season;
  if v_league is null then raise exception 'No such season'; end if;
  if not is_commissioner(v_league) then raise exception 'Only the Pro marks buy-ins'; end if;
  if not exists (select 1 from league_members where id = p_member and league_id = v_league) then
    raise exception 'Not a member of this league';
  end if;

  select coalesce(buyin_cents, 0) into v_stake from league_settings where league_id = v_league;

  insert into buy_ins (season_id, member_id, amount_cents, paid, marked_by, marked_at)
  values (p_season, p_member, coalesce(v_stake, 0), p_paid, my_member_id(v_league), now())
  on conflict (season_id, member_id) do update
    set paid = excluded.paid,
        marked_by = excluded.marked_by,
        marked_at = excluded.marked_at;

  if p_paid then
    select upper(coalesce(p.display_name, 'A MEMBER')) into v_name
      from league_members lm join profiles p on p.id = lm.profile_id
     where lm.id = p_member;
    select count(*) filter (where b.paid) into v_paid_n
      from buy_ins b where b.season_id = p_season;
    select count(*) into v_total from league_members where league_id = v_league;

    insert into posts (league_id, season_id, kind, member_id, body)
    values (v_league, p_season, 'system', my_member_id(v_league),
            v_name || '''S BUY-IN IS IN — ' || v_paid_n || '/' || v_total || ' COLLECTED');
  end if;
end $$;

grant execute on function public.mark_buy_in(uuid, uuid, boolean) to authenticated;

create or replace function public.daily_season_tick() returns void
language plpgsql security definer
set search_path = public
as $$
declare se record;
begin
  for se in select * from seasons where status in ('active','cup_final')
  loop
    -- kickoff: first tick on/after the Sunday first tee, once ever
    if se.status = 'active' and not se.kicked_off and current_date >= se.starts_on then
      update seasons set kicked_off = true where id = se.id;
      insert into posts (league_id, season_id, kind, body)
      values (se.league_id, se.id, 'system',
              'THE SEASON IS LIVE — WEEK 1. COUNTING ROUNDS START NOW.');
    end if;
    -- open the Cup Final window at ends_on − 27 (a Sunday, seasons end Saturday)
    if se.status = 'active' and current_date >= se.ends_on - 27 then
      perform enter_cup_final(se.id);
    end if;
    -- grace-aware season close: final day + 48h (seasons.grace_hours), local tz
    if now() > ((se.ends_on + 1)::timestamp at time zone se.timezone
                + make_interval(hours => se.grace_hours)) then
      perform close_season(se.id);
    end if;
  end loop;
end $$;
