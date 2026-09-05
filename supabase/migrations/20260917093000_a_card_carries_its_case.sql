-- ============================================================================
-- Cup Season — a card carries its case (R21 `tour_card` + `case[]` +
-- `career.best_round`; R12 `career_record` narrowed)
--
-- Wave 5 of the UX overhaul (docs/ux-overhaul-2026-09-04/, owner-authorised
-- 2026-09-05). D232 (You keeps two heads: Your golf, and Your record), IOS-032.
--
-- ---------------------------------------------------------------------------
-- R21 · tour_card gains `case[]` and `career.best_round`
--
-- The person page has two rows the design draws and no read can fill:
--
--   TROPHIES   2 cups · 1 points king
--   BEST       74 at Troon North, May 3
--
-- Neither is computable today, and each for its own reason:
--
--   * `trophies` RLS is SELF-ONLY (`20260713200000_trophies.sql:31-34`, whose
--     own comment says "Viewing another golfer's case is a later RPC") and
--     `my_trophies()` takes no `p_profile`. So a golfer cannot see anybody
--     else's silverware, ever.
--   * `tour_card.trophies` is built from `achievements`, which are milestones
--     ("first birdie"), not titles — a different object under the same word.
--   * `career.best` is `min(differential)`: a decimal against a course rating,
--     with no gross, no course and no date. "74 at Troon North, May 3" is
--     three facts the payload does not carry.
--
-- So this adds, behind the UNCHANGED L-37 gate the function already applies:
--
--   `case[]`  {kind, title, subtitle, placement, season_year, earned_on} from
--             `trophies` for the VIEWED profile. SECURITY DEFINER, which is
--             what makes it lawful without touching the self-only RLS policy:
--             the policy stays exactly as it is and this one function, which
--             already decides who may see this card, decides who may see the
--             case on it. `trophies` is `case` and `achievements` stays
--             `trophies` on the payload, under its existing key, because
--             renaming a shipped key would blank the credential on every
--             client that has not been updated.
--
--   `career.best_round` {gross, course_label, played_on, differential} — the
--             lowest GROSS among that golfer's counting rounds, with where and
--             when. Gross, not differential, because "74 at Troon North" is
--             the sentence a golfer says; the differential rides along so the
--             old `best` row keeps its own figure and nothing is re-signed.
--
-- Both are ADDITIVE keys on a payload the client already tolerates additions
-- to (`TourCard.parse` reads by key), and both are absent-safe: a client that
-- does not know them renders exactly what it renders today, and a client that
-- knows them renders the two rows only when the keys arrive (L-44).
--
-- ---------------------------------------------------------------------------
-- R12 · career_record narrowed
--
-- `seasons_done` counts DISTINCT seasons in `season_payouts`
-- (`20260725190000:154-158`). `season_payouts` holds **0 rows for every
-- profile in prod**, so the record tells every golfer they have finished no
-- seasons — including the golfers in the one season that actually completed.
-- The figure is not wrong as a denominator for money; it is wrong as an answer
-- to "how many seasons have you played".
--
-- So the two are split and both are returned:
--   `seasons_played`  complete seasons this golfer was a member of
--   `seasons_done`    seasons that actually PAID this golfer — unchanged, and
--                     it stays the denominator under the money line
--   `first_round_on`  min(played_on) over their own counting rounds — which is
--                     what a "since March" clause needs and what no read
--                     returns today. Until this lands, the clause does not
--                     render: `profiles.created_at` is the ACCOUNT, not the
--                     golf, and printing it as "since" would be L-44.
--
-- Additive. A client that predates this reads `seasons_done` as it always did.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- R21 · the case and the best round
-- ---------------------------------------------------------------------------
create or replace function public.tour_card(p_profile uuid)
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare
  v uuid := auth.uid();
  v_prof jsonb; v_career jsonb; v_trophies jsonb; v_recent jsonb; v_vs jsonb;
  v_courses jsonb; v_shared jsonb; v_case jsonb; v_best jsonb;
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

  -- D209 · ONE lens. `lens` is this golfer's allowance figure — the engine's
  -- own `v_rounds_ranked.pvi`, the number the points were scored against —
  -- collapsed to ONE ROW PER ROUND, because a round played by a member of two
  -- leagues fans into two ranked rows and would otherwise carry double weight.
  -- The lens that wins is the one the round scored best under, the same ladder
  -- `month_rank` already uses on this view. Sim rounds are excluded here for
  -- the same reason every other figure in this block excludes them.
  with lens as (
    select distinct on (rr.round_id) rr.round_id, rr.pvi
      from v_rounds_ranked rr
     where rr.profile_id = p_profile
       and rr.pvi is not null
       and coalesce(rr.source,'app') <> 'sim'
     order by rr.round_id, rr.points desc, rr.pvi desc, rr.season_id
  )
  select jsonb_build_object(
    'rounds', count(*),
    'best', min(differential),
    'avg_vs_index', round(avg(index_at_post - differential) filter (where index_at_post is not null), 1),
    'avg_pvi',  (select round(avg(l.pvi), 1) from lens l),
    'best_pvi', (select max(l.pvi) from lens l)
  ) into v_career
  from rounds
  where profile_id = p_profile and not voided and differential is not null
    and coalesce(source,'app') <> 'sim';

  -- R21 · the best round as a SENTENCE's worth of facts: the lowest gross,
  -- where, and when. Null when this golfer has no counting round with a gross
  -- on it, and the row simply does not render (L-44). Nines are excluded: a 38
  -- for nine is not a lower round than a 74 for eighteen, and the row would
  -- read as though it were.
  select jsonb_build_object('gross', r.gross,
                            'course_label', nullif(r.course_label, ''),
                            'played_on', r.played_on,
                            'differential', r.differential)
    into v_best
    from rounds r
   where r.profile_id = p_profile and not r.voided
     and coalesce(r.source,'app') <> 'sim'
     and r.gross is not null
     and coalesce(r.holes_played, 18) = 18
   order by r.gross asc, r.played_on desc
   limit 1;

  if v_best is not null then
    v_career := coalesce(v_career, '{}'::jsonb) || jsonb_build_object('best_round', v_best);
  end if;

  -- the MILESTONES, under the key they have always had. Renaming a shipped key
  -- blanks the credential on every client that has not been updated.
  select coalesce(jsonb_agg(jsonb_build_object(
           'kind', kind, 'label', label, 'earned_on', earned_on, 'meta', meta)
         order by earned_on desc, kind), '[]'::jsonb) into v_trophies
  from achievements where profile_id = p_profile;

  -- R21 · the CASE — the actual silverware. `trophies` RLS is self-only and
  -- stays self-only; this function is SECURITY DEFINER and has already decided
  -- that this viewer may see this card, so it is the one place the case may be
  -- read from. Nothing here is a count of anything else: a title is a row.
  select coalesce(jsonb_agg(jsonb_build_object(
           'kind', t.kind, 'title', t.title, 'subtitle', t.subtitle,
           'placement', t.placement, 'season_year', t.season_year,
           'earned_on', t.earned_on)
         order by t.earned_on desc nulls last, t.title), '[]'::jsonb) into v_case
  from trophies t where t.profile_id = p_profile;

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
  -- where somebody has played.
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
    'trophies', v_trophies, 'case', coalesce(v_case, '[]'::jsonb),
    'recent', v_recent, 'vs_you', v_vs,
    'courses', coalesce(v_courses, '[]'::jsonb),
    'shared_courses', coalesce(v_shared, '[]'::jsonb)
  );
end $function$;

comment on function public.tour_card(uuid) is
  'The whole card, behind the L-37 visibility gate. R21 (wave 5) adds `case[]` — the viewed golfer''s actual silverware from `trophies`, readable here and nowhere else because the table''s RLS stays self-only — and `career.best_round{gross, course_label, played_on}`, which is the sentence a golfer says. `trophies` on the payload is still the MILESTONES, under the key it has always had.';

-- the grant is unchanged; restated because the function was replaced (L-04)
revoke all on function public.tour_card(uuid) from public, anon;
grant execute on function public.tour_card(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- R12 · career_record narrowed
-- ---------------------------------------------------------------------------
create or replace function public.career_record()
returns jsonb
language plpgsql
stable
security definer
set search_path to 'public'
as $function$
declare v uuid := auth.uid(); v_t jsonb;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select jsonb_build_object(
    'cups',       count(*) filter (where kind = 'league' and placement = 'winner'),
    'runner_ups', count(*) filter (where kind = 'league' and placement = 'runner_up'),
    'crowns',     count(*) filter (where placement = 'points_king'),
    'majors',     count(*) filter (where kind = 'major'  and placement = 'winner'),
    'events',     count(*) filter (where kind = 'event'  and placement = 'winner'),
    'trophies',   count(*)
  ) into v_t from trophies where profile_id = v;

  return coalesce(v_t, '{}'::jsonb) || jsonb_build_object(
    -- an EXACT sum of recorded rows; never a recomputation (D67/§16)
    'earnings_cents', coalesce((select sum(cents) from season_payouts where profile_id = v), 0),
    -- #7: the denominator under the earnings total is the count of seasons
    -- that actually paid this profile — not every complete season they were
    -- in. UNCHANGED, and it stays under the money line where it belongs.
    'seasons_done',   (select count(distinct season_id) from season_payouts where profile_id = v),
    -- R12 · and the answer to the different question the record was asking it.
    -- `season_payouts` holds zero rows for everyone, so "0 seasons" was being
    -- printed to golfers who have finished one.
    'seasons_played', (select count(distinct s.id)
                         from league_members lm
                         join seasons s on s.league_id = lm.league_id
                        where lm.profile_id = v and s.status = 'complete'),
    -- R12 · what a "since March" clause needs, and what no read returned. The
    -- account's created_at is not the golf, and the clause does not render
    -- without this (L-44).
    'first_round_on', (select min(played_on) from rounds
                        where profile_id = v and not voided
                          and coalesce(source,'app') <> 'sim'),
    'leagues',        (select count(*) from league_members where profile_id = v));
end $function$;

comment on function public.career_record() is
  'D67 / R12 · what you have won. `seasons_played` (complete seasons you were in) is split from `seasons_done` (seasons that actually paid you, which is 0 for everyone and is the money line''s own denominator), and `first_round_on` is the earliest counting round — the only honest basis for a "since" clause.';

revoke all on function public.career_record() from public, anon;
grant execute on function public.career_record() to authenticated;

-- ---------------------------------------------------------------------------
-- self-check — catalogue and read-only calls; no row is written (L-05)
-- ---------------------------------------------------------------------------
do $check$
declare
  v jsonb;
begin
  if has_function_privilege('anon', 'public.tour_card(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.career_record()', 'EXECUTE') then
    raise exception 'wave 5: anon can execute tour_card or career_record';
  end if;
  if not has_function_privilege('authenticated', 'public.tour_card(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.career_record()', 'EXECUTE') then
    raise exception 'wave 5: authenticated lost execute on tour_card or career_record';
  end if;

  -- the gate still refuses, and the shape is still the shape
  v := tour_card(null);
  if coalesce((v->>'visible')::boolean, true) then
    raise exception 'tour_card: a null profile must not be visible';
  end if;

  -- `trophies` RLS is untouched by this migration and must stay self-only:
  -- the case is readable through the definer function and nowhere else.
  if not exists (select 1 from pg_policies
                  where schemaname = 'public' and tablename = 'trophies'
                    and qual like '%auth.uid()%') then
    raise exception 'trophies: the self-only read policy is gone (R21 reads the case through tour_card, not through RLS)';
  end if;
end $check$;
