-- ============================================================================
-- Cup Season — socially-policed identity (make the Tour Card feel legit)
--
-- The record was already bulletproof (rounds/trophies/index bind to an
-- immutable profile_id, never to the label). What felt loose: name + @handle
-- were SILENTLY and infinitely editable. Fix with the model the index already
-- uses — changes are allowed but ACCOUNTABLE (announced to the crew), plus a
-- cooldown on the handle so it behaves like a real @identity, plus an immutable
-- "member since" tenure anchor. Accountability, not lockdown.
--
--   1. name change  -> announced on every league board ("METZ NOW GOES BY …")
--   2. handle change -> once / 60 days, announced; first claim is free + silent
--   3. member since  -> profiles.created_at, exposed on the card (can't be faked)
-- ============================================================================

alter table public.profiles add column if not exists handle_set_at timestamptz;

-- ---- set_handle: rate-limited + announced --------------------------------
create or replace function public.set_handle(p_handle text) returns void
language plpgsql security definer set search_path = public as $$
declare
  v      text := lower(trim(both from replace(p_handle, '@', '')));
  v_old  text; v_set timestamptz; v_name text;
begin
  if v !~ '^[a-z0-9_]{3,20}$' then
    raise exception 'Handles are 3–20 characters: letters, numbers, underscores';
  end if;
  if v in ('pro','demo','cupseason','admin','support','help','official','cup','season','sndycup') then
    raise exception 'That handle is reserved';
  end if;

  select handle, handle_set_at, display_name into v_old, v_set, v_name
    from profiles where id = auth.uid();
  if v_old is not distinct from v then return; end if;   -- no actual change

  -- cooldown applies only to a genuine change of an existing handle
  if v_old is not null and v_set is not null and v_set > now() - interval '60 days' then
    raise exception 'Your @handle can change once every 60 days — next change on %',
      to_char(v_set + interval '60 days', 'Mon DD');
  end if;

  begin
    update profiles set handle = v, handle_set_at = now() where id = auth.uid();
  exception when unique_violation then
    raise exception 'That handle is taken';
  end;

  -- announce a re-handle (first claim stays silent)
  if v_old is not null then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(coalesce(v_name, 'A member')) || ' IS NOW @' || v
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $$;

-- ---- set_profile: same 6-arg shape, now announces a NAME change -----------
create or replace function public.set_profile(
  p_name text, p_city text default null, p_home text default null,
  p_index numeric default null, p_marker text default null, p_ghin text default null
) returns void
language plpgsql security definer set search_path = public as $$
declare v_old text;
begin
  select display_name into v_old from profiles where id = auth.uid();

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
    ghin_number   = case when p_ghin is null then profiles.ghin_number
                         else nullif(trim(p_ghin), '') end;

  -- a name change is announced to the crew (an existing member, real change)
  if p_name is not null and v_old is not null and trim(p_name) <> v_old then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           upper(v_old) || ' NOW GOES BY ' || upper(trim(p_name))
      from league_members lm where lm.profile_id = auth.uid();
  end if;
end $$;
grant execute on function public.set_profile(text, text, text, numeric, text, text) to authenticated;

-- ---- tour_card: carry member-since (created_at) on the profile block ------
create or replace function public.tour_card(p_profile uuid)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v uuid := auth.uid();
  v_prof jsonb; v_career jsonb; v_trophies jsonb; v_recent jsonb; v_vs jsonb;
begin
  if p_profile is null then return jsonb_build_object('visible', false); end if;

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
    'index_current', p.index_current, 'ghin', p.ghin_number,
    'member_since', p.created_at, 'is_me', p.id = v
  ) into v_prof
  from profiles p where p.id = p_profile and p.deleted_at is null;

  if v_prof is null then return jsonb_build_object('visible', false); end if;

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
