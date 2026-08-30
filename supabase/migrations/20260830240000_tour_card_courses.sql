-- ============================================================================
-- D150 (3/3) . the Tour Card answers "where has this guy played"
--
-- The card already answered "how good is he" well -- index, best differential,
-- average PvI, round count, trophies, and a head-to-head. It answered "what
-- courses has he played" with the last five rounds and nothing more, and it had
-- no answer at all for the question that actually makes two strangers talk.
--
-- Two new blocks:
--   courses        every course this golfer has PICKED, with how many rounds
--                  and when they last played it
--   shared_courses the courses you and they have BOTH played -- the
--                  "oh, you have played Papago too" moment
--
-- Free-typed rounds are excluded by construction: course_key returns NULL
-- without an api_course_id, so a typed string never becomes a claim about where
-- somebody has been (D150 ruling 1).
--
-- No new privacy rule (D150 ruling 4). Both blocks sit INSIDE tour_card, behind
-- the gate it has always had: yourself, an accepted buddy, a shared league, a
-- shared event, or discoverable='everyone'. A stranger who cannot see the card
-- cannot see the courses, and there is nothing new for a golfer to learn or
-- configure.
--
-- Body taken from the LIVE database: tour_card has three definitions in the
-- tree and the newest by filename is not necessarily the one running.
-- ============================================================================

CREATE OR REPLACE FUNCTION public.tour_card(p_profile uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v uuid := auth.uid();
  v_prof jsonb; v_career jsonb; v_trophies jsonb; v_recent jsonb; v_vs jsonb;
  v_courses jsonb; v_shared jsonb;
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
    select played_on, course_label, gross, differential, holes_played,
           -- D76 FORM: beat the number = pvi >= 1 (nines are 18-equivalized
           -- upstream by score_round; nulls stay null, never a guess)
           case when differential is not null and index_at_post is not null
                then (index_at_post - differential) >= 1
                else null end as beat
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

  -- D150 · the course history. Only PICKED courses count: course_key returns
  -- NULL for a free-typed round, so a typed label never becomes a claim about
  -- where somebody has played. Identity is the catalogue's club+course name, so
  -- the two cached Papago rows collapse to one course, and a round whose course
  -- was never cached still resolves through its own picker label.
  select coalesce(jsonb_agg(jsonb_build_object(
           'name', nm, 'rounds', n, 'last_played', last_on) order by n desc, nm), '[]'::jsonb)
    into v_courses
    from (
      select course_key(api_course_id, course_label) k,
             min(course_name_of(api_course_id, course_label)) nm,
             count(*) n, max(played_on) last_on
        from rounds
       where profile_id = p_profile and not voided
         and coalesce(source,'app') <> 'sim'
         and course_key(api_course_id, course_label) is not null
       group by 1
    ) c;

  -- the point of the whole exercise: what the two of you have both played
  if p_profile <> v then
    select coalesce(jsonb_agg(jsonb_build_object('name', nm, 'mine', mine, 'theirs', theirs)
                    order by theirs desc, nm), '[]'::jsonb)
      into v_shared
      from (
        select coalesce(t.nm, m.nm) nm, coalesce(m.n,0) mine, coalesce(t.n,0) theirs
          from (select course_key(api_course_id, course_label) k,
                       min(course_name_of(api_course_id, course_label)) nm, count(*) n
                  from rounds where profile_id = v and not voided
                    and coalesce(source,'app') <> 'sim'
                    and course_key(api_course_id, course_label) is not null
                 group by 1) m
          join (select course_key(api_course_id, course_label) k,
                       min(course_name_of(api_course_id, course_label)) nm, count(*) n
                  from rounds where profile_id = p_profile and not voided
                    and coalesce(source,'app') <> 'sim'
                    and course_key(api_course_id, course_label) is not null
                 group by 1) t on t.k = m.k
      ) s;
  end if;

  return jsonb_build_object(
    'visible', true, 'profile', v_prof, 'career', v_career,
    'trophies', v_trophies, 'recent', v_recent, 'vs_you', v_vs,
    'courses', coalesce(v_courses, '[]'::jsonb),
    'shared_courses', coalesce(v_shared, '[]'::jsonb)
  );
end $function$;

revoke all on function public.tour_card(uuid) from public, anon;
grant execute on function public.tour_card(uuid) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_src text;
begin
  select prosrc into v_src from pg_proc
   where proname='tour_card' and pronamespace='public'::regnamespace;
  if position('shared_courses' in v_src) = 0 then
    raise exception 'D150: tour_card does not return the shared courses';
  end if;
  if position('course_key(api_course_id, course_label) is not null' in v_src) = 0 then
    raise exception 'D150: tour_card would count free-typed rounds as course history';
  end if;
  -- the gate this rides on must still be there (D150 ruling 4: no new privacy rule)
  if position('discoverable' in v_src) = 0 or position('friendships' in v_src) = 0 then
    raise exception 'D150: tour_card lost its visibility gate — wrong base';
  end if;
  -- and it must still return everything it did before
  if position('''vs_you''' in v_src) = 0 or position('''trophies''' in v_src) = 0
     or position('''career''' in v_src) = 0 then
    raise exception 'D150: tour_card lost an existing block — wrong base';
  end if;
end $chk$;
