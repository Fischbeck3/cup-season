-- ============================================================================
-- Cup Season — one lens on the Tour Card (D209)
--
-- Measured on an iPhone 17 Pro, 2026-09-02: the Tour Card's CAREER block read
-- "Avg vs your number -1.6" while the You tab, for the same golfer, read
-- "Avg vs your playing number +2.6". Two figures, one screen apart, for one
-- fact — the §16 failure D209 ruled out.
--
-- Cause, read out of prod: tour_card()'s career block computes its average
-- from `index_at_post - differential` — the 100% lens — while every You
-- figure now reads `v_rounds_ranked.pvi`, the allowance lens (the engine's
-- own `round(index_at_post * handicap_allowance / 100 - differential, 1)`;
-- prod runs a single allowance, 95, so the allowance figure sits about 5% of
-- an index below the 100% one, on every round, for every golfer).
--
-- WHAT THE BRIEF DID NOT KNOW: `avg_pvi` is NOT a new key. It already exists
-- on the career object and already holds the 100% figure — the name says PvI
-- and the body says otherwise, which is how this drifted unseen. Both clients
-- read it today (`index.html:15436`, `TourCard.swift:65`). So this migration
-- cannot "add" it; it CORRECTS it, and keeps the old figure whole under a
-- name that says which lens it is:
--
--   avg_pvi       (existing key, LENS CORRECTED)  mean pvi, allowance lens
--   best_pvi      (NEW, nullable)                 max  pvi, allowance lens
--   avg_vs_index  (NEW, nullable)                 the old avg_pvi body, verbatim
--   rounds, best  (UNTOUCHED)                     `best` is still min(differential),
--                                                 the "Best round vs course" figure
--
-- BEST IS THE MAXIMUM, not the minimum. The brief said "best (lowest)"; that
-- is the differential convention, and pvi runs the other way. Proven, not
-- assumed: cup_points(6.0)=12 "Torched it", cup_points(0.5)=7 "Played to it",
-- cup_points(-1.0)=6 "A little loose" — a HIGHER pvi is a better round, and
-- settle_week_clash prints "beat their number by <pvi>". The Kit already
-- agrees (`Career.swift:19` "max `pvi`"; `SeasonStats.swift:18`). The
-- self-check below asserts the sign rather than trusting this paragraph.
--
-- SCOPE, honestly. The existing average silently covers rounds v_rounds_ranked
-- cannot score, and this migration does not paper over it — measured in prod
-- 2026-09-02: 33 card-visible rounds carry no ranked row at all (played
-- outside every season window, or by a golfer in no league), and 4 profiles
-- with posted rounds have no ranked row whatsoever. For those four,
-- `avg_pvi` and `best_pvi` come back NULL — there is no allowance figure to
-- report, and inventing one is the worse answer. `avg_vs_index` is what a
-- client falls back to. Two more scope facts, both handled below:
--   · 83 rounds fan into more than one ranked row (a golfer in two leagues,
--     or two overlapping seasons). Averaging the view raw double-counts them,
--     so the career figures collapse to ONE ROW PER ROUND.
--   · all 13 prod leagues set `sim_rounds_allowed`, so a sim round WOULD earn
--     a pvi — while `rounds`, `best`, `recent` and `courses` in this same
--     block all exclude sim. The lens excludes it too; one block, one scope.
--
-- Signature, return type, volatility, security and grants are all unchanged
-- (`tour_card|p_profile uuid|jsonb|definer|auth`), so packages/db/contract.psv
-- does not move.
--
--   1 · tour_card — body = prod 2026-09-02 verbatim but for the career block
--   2 · grants (unchanged, restated explicitly)
--   3 · self-check
-- ============================================================================

-- ── 1 · the career block, under one lens ────────────────────────────────────
create or replace function public.tour_card(p_profile uuid)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
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

  -- D209 · ONE lens. `lens` is this golfer's allowance figure — the engine's
  -- own `v_rounds_ranked.pvi`, the number the points were scored against —
  -- collapsed to ONE ROW PER ROUND, because a round played by a member of two
  -- leagues fans into two ranked rows and would otherwise carry double weight.
  -- The lens that wins is the one the round scored best under, the same ladder
  -- `month_rank` already uses on this view (today no round disagrees: prod
  -- holds a single `handicap_allowance`, 95). Sim rounds are excluded here for
  -- the same reason every other figure in this block excludes them — all 13
  -- leagues set `sim_rounds_allowed`, so without this line a sim round would
  -- land in the average while `rounds`, `best`, `recent` and `courses` all
  -- pretend it does not exist.
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
    -- the 100% figure this function has always returned, kept whole under a
    -- name that says which lens it is. Nothing is lost; it is the fallback a
    -- leagueless golfer still has a number in.
    'avg_vs_index', round(avg(index_at_post - differential) filter (where index_at_post is not null), 1),
    -- the two keys the card reads. Null when no league has ever scored this
    -- golfer — a fabricated number would be the worse answer.
    'avg_pvi',  (select round(avg(l.pvi), 1) from lens l),
    'best_pvi', (select max(l.pvi) from lens l)
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

-- ── 2 · grants ──────────────────────────────────────────────────────────────
-- Unchanged from prod (`authenticated` only), restated because a function
-- re-created by a runner that is not `postgres` can pick up PUBLIC execute
-- (CLAUDE.md landmine: the D37 default-privilege flip binds to that role).
revoke all on function public.tour_card(uuid) from public, anon;
grant execute on function public.tour_card(uuid) to authenticated;

-- ── 3 · self-check ──────────────────────────────────────────────────────────
do $chk$
declare v_src text; v_n integer; v_def boolean; v_vol "char";
begin
  select p.prosrc, p.prosecdef, p.provolatile into v_src, v_def, v_vol
    from pg_proc p join pg_namespace n on n.oid = p.pronamespace
   where n.nspname = 'public' and p.proname = 'tour_card';
  if v_src is null then
    raise exception '[D209] tour_card is gone';
  end if;

  -- the career average reads the engine's lens, and the old body is not
  -- still feeding the key that names it
  if v_src not like '%from v_rounds_ranked rr%' then
    raise exception '[D209] the career block no longer reads v_rounds_ranked';
  end if;
  if v_src like '%''avg_pvi'', round(avg(index_at_post%' then
    raise exception '[D209] avg_pvi is still the 100%% lens';
  end if;

  -- the two keys the card decodes — best is the MAXIMUM — and the 100%%
  -- figure kept whole for the golfer no league has ever scored
  if v_src not like '%''avg_pvi'',%(select round(avg(l.pvi), 1) from lens l)%' then
    raise exception '[D209] avg_pvi is not the mean of the allowance lens';
  end if;
  if v_src not like '%''best_pvi'',%(select max(l.pvi) from lens l)%' then
    raise exception '[D209] best_pvi is not the MAXIMUM allowance figure';
  end if;
  if v_src not like '%''avg_vs_index''%' then
    raise exception '[D209] the 100%% average lost its home (avg_vs_index)';
  end if;
  if v_src not like '%distinct on (rr.round_id)%' then
    raise exception '[D209] a round in two leagues would be counted twice';
  end if;

  -- the rest of the body survived the re-create
  if v_src not like '%D150 · the course history%'
     or v_src not like '%''shared_courses'', coalesce(v_shared%'
     or v_src not like '%''vs_you'', v_vs%'
     or v_src not like '%D76 FORM%' then
    raise exception '[D209] tour_card lost part of its body';
  end if;

  -- shape, security, volatility, grants (D37)
  if not v_def then raise exception '[D209] tour_card lost SECURITY DEFINER'; end if;
  if v_vol <> 's' then raise exception '[D209] tour_card is no longer STABLE'; end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'tour_card'
                    and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D209] tour_card lost its grant to authenticated';
  end if;
  if exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
              where n.nspname = 'public' and p.proname = 'tour_card'
                and has_function_privilege('anon', p.oid, 'execute')) then
    raise exception '[D209] tour_card is reachable by anon (or PUBLIC)';
  end if;

  -- ONE SCOPE: the lens can never average a round this same block pretends
  -- does not exist — voided, sim, or carrying no differential.
  select count(*) into v_n
    from v_rounds_ranked rr
    join rounds r on r.id = rr.round_id
   where rr.pvi is not null
     and coalesce(rr.source,'app') <> 'sim'
     and (r.voided or r.differential is null or coalesce(r.source,'app') = 'sim');
  if v_n > 0 then
    raise exception '[D209] % ranked round(s) would enter the career average that the card excludes', v_n;
  end if;

  -- best_pvi rests on "a higher pvi is a better round". Assert it, don't
  -- trust the header: if cup_points ever flips, best_pvi must stop being max().
  if cup_points(6.0) <= cup_points(-2.0) or cup_points(0.5) <= cup_points(-1.0) then
    raise exception '[D209] pvi changed sign — best_pvi is the wrong end of the range';
  end if;
end $chk$;
