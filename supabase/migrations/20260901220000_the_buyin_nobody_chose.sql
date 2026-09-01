-- ============================================================================
-- Cup Season — the buy-in nobody chose, and the GHIN nobody published
--
-- Two things a column default decided on a golfer's behalf.
--
-- 1 · D113 (2026-08-29) ruled buy-in defaults to $0 at every layer, with the
--     backfill APPROVED for setup-phase leagues only and spec §7 amended to
--     "$0 by default (bragging rights); $25-$200 when money's in play". It was
--     decided, logged, and never built: `league_settings.buyin_cents` still
--     reads `DEFAULT 7500` in prod today, so every league created since has
--     started at a $75 buy-in its Pro never picked, and `join_covenant_info`
--     serves that number to every pre-lock joiner. D46's principle — money is
--     a CHOICE, not a default — has been true on paper for three days and
--     false in the schema the whole time.
--
--     `create_league` does not mention buyin_cents at all: it relies on the
--     column default, so moving the default IS the fix and no function
--     changes. The wizard's renderer already prints "None" for 0
--     (index.html:7976) and `resetWizard()` already zeroes it; only the static
--     markup still said $75, which is the pre-render frame. That moves in the
--     same commit.
--
--     The CHECK is the server ceiling the audit asked for and D192 did not
--     supply — D192 capped `#lrStake`, the per-round side stake, and left the
--     season buy-in unbounded. 0..20000 cents matches the $200 top of the
--     ladder and CS_STAKE_MAX. Prod's current range is 0..7500 across 13 rows,
--     so nothing existing violates it. The $25 FLOOR is deliberately NOT
--     encoded: that is a wizard rule about what is sensible, not a database
--     rule about what is possible, and a hard floor here would make $0 -> $10
--     an error instead of a choice.
--
-- 2 · `tour_card` returns `p.ghin_number` to any caller who passes its
--     visibility gate. That gate ends in `coalesce(discoverable,'nobody') =
--     'everyone'`, and `profiles.discoverable` has DEFAULTED to 'everyone'
--     since `20260712010000_social_graph.sql:16`, where it was born as a
--     FINDABILITY flag for `search_golfers`. `tour_card` later reused the same
--     column as a READABILITY gate. Two different questions, one flag — and
--     the settings control still reads "Findable by · All / Buddies / Nobody",
--     which tells a golfer nothing about what "All" makes readable.
--
--     Measured in prod on 2026-09-01: 24 of 39 profiles sit on the default,
--     4 profiles carry a GHIN, and ALL FOUR are among the 24. The GHIN help
--     copy calls it "a reference on your card — we never resell or verify it",
--     which reads as reassurance while the RPC hands the number to any signed-in
--     stranger. Nobody chose that; a column default chose it for them in July.
--
--     The field is dropped from the payload. No client change is needed —
--     `index.html` renders the GHIN row conditionally, so it simply stops
--     arriving. Tiering the whole payload by caller relationship is the right
--     long-term design and is logged as the decision that follows, not
--     attempted inside a 6,000-character function eleven days from submission.
--
-- 3 · While in there: the career block filters `differential is not null`
--     (so a round that never scored is not a round) and the courses block did
--     not, so "Rounds 14" in Career could sit above per-course counts summing
--     to more. Same filter, both places.
--
-- `tour_card`'s body below is prod's own `pg_get_functiondef` output with only
-- those two lines changed — generated, not retyped. Five migrations touch this
-- function and the newest by filename is not necessarily the one running, so
-- forking from a file would have been a coin flip.
-- ============================================================================

alter table public.league_settings alter column buyin_cents set default 0;

-- D113's approved backfill: unlocked leagues only, never a locked one.
update public.league_settings ls
   set buyin_cents = 0
  from public.leagues l
  join public.seasons s on s.league_id = l.id
 where l.id = ls.league_id
   and ls.buyin_cents = 7500
   and s.status = 'setup';

alter table public.league_settings
  drop constraint if exists league_settings_buyin_range;
alter table public.league_settings
  add constraint league_settings_buyin_range
  check (buyin_cents >= 0 and buyin_cents <= 20000);

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
    'index_current', p.index_current,
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
         and differential is not null
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

do $$
declare v text; n int;
begin
  select column_default into v from information_schema.columns
   where table_schema='public' and table_name='league_settings' and column_name='buyin_cents';
  if v is null or v not like '0%' then
    raise exception '[buyin] default is still %, not 0', v;
  end if;

  if (select prosrc from pg_proc p join pg_namespace ns on ns.oid=p.pronamespace
       where ns.nspname='public' and p.proname='tour_card') like '%ghin_number%' then
    raise exception '[tour_card] still returns a GHIN number';
  end if;

  select count(*) into n from public.league_settings where buyin_cents < 0 or buyin_cents > 20000;
  if n > 0 then raise exception '[buyin] % row(s) outside 0..20000', n; end if;
end $$;
