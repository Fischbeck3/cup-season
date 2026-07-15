-- ============================================================================
-- Cup Season — the Tour Card as a VIEWABLE object (+ optional GHIN)
--
-- The identity object was half-finished: the Tour Card only ever rendered your
-- OWN self. "Click a name → see their card" is the vision doc's core promise
-- ("a permanent golfer profile"), and it's pure read — every field already
-- exists. tour_card(p_profile) returns the whole card in one round trip, gated
-- by the SAME visibility fence home_feed/my_schedule already use: you, an
-- accepted buddy, a league/event mate, or anyone set discoverable='everyone'.
-- Tombstoned profiles ("Former member") return not-visible.
--
-- GHIN: ghin_number already exists on profiles (never a paid verification
-- product — an optional reference line on the card, per the monetization note).
-- set_profile grows p_ghin. Empty string clears it; NULL keeps it (so an old
-- cached client that omits the arg never wipes a saved number).
-- ============================================================================

-- ---- set_profile gains GHIN (drop first: the arg list changes) -------------
drop function if exists public.set_profile(text, text, text, numeric, text);
create or replace function public.set_profile(
  p_name text, p_city text default null, p_home text default null,
  p_index numeric default null, p_marker text default null, p_ghin text default null
) returns void
language plpgsql security definer set search_path = public as $$
begin
  insert into profiles (id, email, display_name, city, home_course, index_current, marker, ghin_number)
  values (
    auth.uid(),
    coalesce((select email from auth.users where id = auth.uid()), ''),
    p_name, p_city, p_home, p_index, p_marker, nullif(trim(coalesce(p_ghin,'')), ''))
  on conflict (id) do update set
    display_name  = coalesce(excluded.display_name,  profiles.display_name),
    city          = coalesce(excluded.city,          profiles.city),
    home_course   = coalesce(excluded.home_course,   profiles.home_course),
    index_current = coalesce(excluded.index_current, profiles.index_current),
    marker        = coalesce(excluded.marker,        profiles.marker),
    ghin_number   = case when p_ghin is null then profiles.ghin_number   -- omitted: keep
                         else nullif(trim(p_ghin), '') end;               -- sent: set or clear
end $$;
grant execute on function public.set_profile(text, text, text, numeric, text, text) to authenticated;

-- ---- tour_card: another golfer's whole card, one round trip ----------------
create or replace function public.tour_card(p_profile uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_prof jsonb; v_career jsonb; v_trophies jsonb; v_recent jsonb; v_vs jsonb;
begin
  if p_profile is null then return jsonb_build_object('visible', false); end if;

  -- same visibility fence as home_feed / my_schedule
  if not (
    p_profile = v
    or exists (select 1 from friendships f where f.status='accepted'
        and ((f.requester=v and f.addressee=p_profile) or (f.addressee=v and f.requester=p_profile)))
    or exists (select 1 from league_members a join league_members b on b.league_id=a.league_id
        where a.profile_id=v and b.profile_id=p_profile)
    or exists (select 1 from event_players a join event_players b on b.event_id=a.event_id
        where a.profile_id=v and b.profile_id=p_profile)
    or coalesce((select discoverable from profiles where id=p_profile), 'nobody') = 'everyone'
  ) then
    return jsonb_build_object('visible', false);
  end if;

  select jsonb_build_object(
    'id', p.id, 'display_name', p.display_name, 'handle', p.handle,
    'marker', p.marker, 'city', p.city, 'home_course', p.home_course,
    'index_current', p.index_current, 'ghin', p.ghin_number, 'is_me', p.id = v
  ) into v_prof
  from profiles p where p.id = p_profile and p.deleted_at is null;

  if v_prof is null then return jsonb_build_object('visible', false); end if;

  -- career: global, 100%-allowance PvI = index_at_post − differential
  select jsonb_build_object(
    'rounds', count(*),
    'best', min(differential),
    'avg_pvi', round(avg(index_at_post - differential) filter (where index_at_post is not null), 1)
  ) into v_career
  from rounds
  where profile_id = p_profile and not voided and differential is not null
    and coalesce(source,'app') <> 'sim';

  select coalesce(jsonb_agg(jsonb_build_object(
           'kind', kind, 'label', label, 'earned_on', earned_on, 'meta', meta)
         order by earned_on desc, kind), '[]'::jsonb) into v_trophies
  from achievements where profile_id = p_profile;

  select coalesce(jsonb_agg(to_jsonb(x)), '[]'::jsonb) into v_recent from (
    select played_on, course_label, gross, differential, holes_played
      from rounds
     where profile_id = p_profile and not voided and coalesce(source,'app') <> 'sim'
     order by played_on desc, created_at desc
     limit 5
  ) x;

  -- vs the viewer: weekly clash record (skip when it's your own card)
  if p_profile <> v then
    with shared as (
      select distinct s.id season_id
        from league_members lm1
        join league_members lm2 on lm2.league_id=lm1.league_id and lm2.profile_id=p_profile
        join seasons s on s.league_id=lm1.league_id
       where lm1.profile_id = v
    ),
    mine as (select date_trunc('week',rr.played_on)::date wk, max(rr.pvi) pvi
       from v_rounds_ranked rr where rr.profile_id=v and rr.season_id in (select season_id from shared) group by 1),
    opp as (select date_trunc('week',rr.played_on)::date wk, max(rr.pvi) pvi
       from v_rounds_ranked rr where rr.profile_id=p_profile and rr.season_id in (select season_id from shared) group by 1),
    clash as (select m.pvi mp, o.pvi op from mine m join opp o on o.wk=m.wk)
    select jsonb_build_object(
      'wins',   count(*) filter (where mp > op),
      'losses', count(*) filter (where mp < op),
      'ties',   count(*) filter (where mp = op)
    ) into v_vs from clash;
  end if;

  return jsonb_build_object(
    'visible', true, 'profile', v_prof, 'career', v_career,
    'trophies', v_trophies, 'recent', v_recent, 'vs_you', v_vs
  );
end $$;
grant execute on function public.tour_card(uuid) to authenticated;
