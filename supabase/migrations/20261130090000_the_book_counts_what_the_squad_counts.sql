-- Launch-audit integration I4 (2026-09-24) · the Book counts what the squad counts.
-- D381 (the Book) · D383 (a finished season keeps its book) · D386 (a late seat counts forward).
--
-- S7 (20261126090000) made v_squad_standings count a member for a squad only from a seat
-- taken under way (squad_members.seated_at), but season_book still built the squad and
-- member-contribution receipts from every round the member posted. Reproduced (Codex,
-- 2026-09-24): a squad's authoritative total 280, its Book entries 326, coverage_complete
-- false. The Race is drawn from the same cells, so it drifted with them.
--
--   1 · season_book's squad and contribution entries use v_squad_standings' own rule; the
--       golfer's individual row still lists every round (the golfer's record is theirs).
--   2 · each entry carries `withdrawn` (false for everything but a line a finished season's
--       book kept after the golfer deleted the round). The line keeps its points and its
--       explanation; no private round detail is exposed (the Book never carried course,
--       photo or card, and round_card has nothing to open for it). Old clients ignore the key.
--   3 · a booked (finished) season says its lines are frozen at the close, `frozen: true`;
--       the envelope is version 2 (additive: every version-1 key is unchanged).
--   4 · the tie ladder's squad month scores (D388; close_season / enter_cup_final) use the
--       same seat rule, so the table, the Book, the Race and a tie-break agree.
--
-- The Book's migration (20261118090000) is applied and never edited: the function is
-- re-emitted whole here from its text with only the changes above.

-- ── 0 · one seat rule, answerable after a finished season's round is deleted ─
-- The seat rule compares a round's post time with the seat. A finished season's book
-- keeps a line after the golfer deletes the round (D383), and with the rounds row gone
-- the rule could not tell a pre-seat round from a post-seat one: deleting a pre-seat
-- round after the close LIFTED the squad (280 → 289 on the Book fixture). The book now
-- keeps each line's post time, and every reader asks one helper.
alter table public.season_book_rows add column if not exists round_created_at timestamptz;
update public.season_book_rows b set round_created_at = r.created_at
  from public.rounds r where r.id = b.round_id and b.round_created_at is null;

create or replace function public._counts_for_seat(p_round uuid, p_seat timestamptz)
returns boolean language sql stable security definer set search_path = public
as $$
  -- a seat taken at formation (null) counts every round; otherwise only rounds posted from it.
  -- The post time is the round's own, or the one the finished season's book kept.
  select p_seat is null
      or coalesce((select r.created_at from rounds r where r.id = p_round),
                  (select max(b.round_created_at) from season_book_rows b where b.round_id = p_round)) is null
      or coalesce((select r.created_at from rounds r where r.id = p_round),
                  (select max(b.round_created_at) from season_book_rows b where b.round_id = p_round)) >= p_seat
$$;
-- an invoker view (v_squad_standings) calls it, so authenticated keeps EXECUTE; it answers
-- one boolean about a round id and a time, nothing else
revoke all on function public._counts_for_seat(uuid, timestamptz) from public, anon;
grant execute on function public._counts_for_seat(uuid, timestamptz) to authenticated;

-- the close books the post time with the line (re-emitted from 20261119090000's body)
create or replace function public._book_season()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and old.status is distinct from 'complete' then
    if exists (select 1 from season_books where season_id = new.id) then return new; end if;
    -- one statement: every CTE reads the same snapshot, so the lens read in
    -- `hold` cannot see the marker `mark` writes beside it
    with hold as materialized (
      select rr.season_id, rr.member_id, rr.round_id, rr.profile_id, rr.played_on, rr.holes_played, rr.source,
             rr.attested, rr.differential, rr.index_at_post, rr.playing_index, rr.pvi, rr.points, rr.floor_credit,
             (select r.created_at from rounds r where r.id = rr.round_id) as round_created_at   -- [I4]
        from v_rounds_ranked rr where rr.season_id = new.id
    ), mark as (
      insert into season_books (season_id, rows_booked, source)
      values (new.id, (select count(*) from hold), 'close')
      returning season_id
    )
    insert into season_book_rows (season_id, member_id, round_id, profile_id, played_on, holes_played, source,
                                  attested, differential, index_at_post, playing_index, pvi, points, floor_credit,
                                  round_created_at)
      select h.* from hold h cross join mark;
  elsif old.status = 'complete' and new.status is distinct from 'complete' then
    delete from season_books where season_id = new.id;
  end if;
  return new;
end $$;
revoke all on function public._book_season() from public, anon, authenticated;

-- v_squad_standings asks the helper (re-emitted from 20261126090000's text)
create or replace view public.v_squad_standings with (security_invoker = 'true') as
 with rp as (
   select sq.season_id,
          sq.id as squad_id,
          coalesce(sum(rr.points) filter (where rr.month_rank <= coalesce(ls.counting_cap, 999)), 0::bigint) as pts
     from public.squads sq
     join public.seasons se on se.id = sq.season_id
     join public.league_settings ls on ls.league_id = se.league_id
     left join public.squad_members sm on sm.squad_id = sq.id
     left join public.v_rounds_ranked rr on rr.member_id = sm.member_id and rr.season_id = sq.season_id
          -- [I4] D386: a late seat counts forward only — one rule, the book's post time included
          and public._counts_for_seat(rr.round_id, sm.seated_at)
    group by sq.season_id, sq.id, ls.counting_cap
 ), adj as (
   select season_adjustments.season_id,
          season_adjustments.squad_id,
          coalesce(sum(season_adjustments.points), 0::bigint) as pts
     from public.season_adjustments
    where season_adjustments.squad_id is not null
    group by season_adjustments.season_id, season_adjustments.squad_id
 )
 select rp.season_id,
        rp.squad_id,
        rp.pts + coalesce(adj.pts, 0::bigint) as points
   from rp
   left join adj on adj.season_id = rp.season_id and adj.squad_id = rp.squad_id;

-- ── 1–3 · season_book ───────────────────────────────────────────────────────
create or replace function public.season_book(p_league_id uuid, p_season_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public
as $book$
-- [I4] version 2: squad receipts count from the seat; entries carry `withdrawn`; frozen seasons say so
declare
  se public.seasons%rowtype;
  ls public.league_settings%rowtype;
  viewer uuid;
  week_count integer;
  this_week integer;
  result jsonb;
begin
  select * into se from public.seasons where id=p_season_id and league_id=p_league_id;
  -- One indistinguishable denial, including a mismatched season/league pair.
  select lm.id into viewer from public.league_members lm
   where lm.league_id=p_league_id and lm.profile_id=auth.uid()
     and lm.left_at is null and lm.suspended_at is null
     and se.number=any(lm.agreed_seasons);
  if se.id is null or viewer is null then
    raise exception 'This season is not available to you.' using errcode='42501';
  end if;
  select * into strict ls from public.league_settings where league_id=p_league_id;
  week_count := (se.ends_on-se.starts_on)/7+1;
  this_week := case when (now() at time zone se.timezone)::date < se.starts_on then 0
    else least(week_count, ((now() at time zone se.timezone)::date-se.starts_on)/7+1) end;
  if week_count not between 1 and 104
    or (select count(*) from public.v_individual_standings where season_id=se.id)>200
    or (select count(*) from public.v_rounds_ranked where season_id=se.id)>10000
    or (select count(*) from public.season_adjustments where season_id=se.id)>10000 then
    raise exception 'This season is too large for one Book read.' using errcode='54000';
  end if;

  with
  weeks as (
    select w as week, se.starts_on+(w-1)*7 as starts_on,
      least(se.ends_on,se.starts_on+w*7-1) as ends_on from generate_series(1,week_count) w
  ),
  members as (
    select iv.member_id, coalesce(p.display_name,'Golfer') as name, iv.points,
      rank() over (order by iv.points desc)::integer as points_rank,
      count(*) over (partition by iv.points)>1 as tied
    from public.v_individual_standings iv
    join public.league_members lm on lm.id=iv.member_id
    join public.profiles p on p.id=lm.profile_id where iv.season_id=se.id
  ),
  squad_rows as (
    select sq.id, sq.name, vs.points,
      rank() over (order by vs.points desc)::integer as points_rank,
      count(*) over (partition by vs.points)>1 as tied
    from public.squads sq join public.v_squad_standings vs on vs.squad_id=sq.id and vs.season_id=sq.season_id
    where sq.season_id=se.id
  ),
  rounds as (
    select rr.*, (rr.played_on-se.starts_on)/7+1 as week,
      rr.month_rank<=coalesce(ls.counting_cap,999) as counting,
      -- [I4] a line a finished season's book kept after the golfer deleted the round
      not exists (select 1 from public.rounds r1 where r1.id=rr.round_id) as withdrawn
    from public.v_rounds_ranked rr where rr.season_id=se.id
  ),
  -- Each entry is scoped to the total it explains. A golfer's floor receipt
  -- remains visible with zero individual contribution; its squad carries it.
  entry_source as (
    select 'golfer:'||rr.member_id as row_id, 'round:'||rr.round_id as id,
      rr.round_id, rr.member_id, null::uuid as squad_id, rr.week,
      rr.played_on as recorded_on, date_trunc('month',rr.played_on)::date as affected_month,
      'round'::text as kind, rr.points::bigint as points,
      case when rr.counting then rr.points else 0 end::bigint as contribution,
      case when rr.counting then 'counting' else 'dropped' end as count_state,
      case when rr.withdrawn then 'Withdrawn by the golfer after the season closed; its points stay in the final table.'
           when rr.counting then 'Counting round' else 'Outside the best '||ls.counting_cap||' for this calendar month; the round stays in the record.' end as reason,
      rr.withdrawn
    from rounds rr
    union all
    select scope.row_id, 'round:'||rr.round_id,rr.round_id,rr.member_id,sq.id,rr.week,
      rr.played_on,date_trunc('month',rr.played_on)::date,'round',rr.points,
      case when rr.counting then rr.points else 0 end,
      case when rr.counting then 'counting' else 'dropped' end,
      case when rr.withdrawn then 'Withdrawn by the golfer after the season closed; its points stay in the final table.'
           when rr.counting then 'Counting round' else 'Outside the best '||ls.counting_cap||' for this calendar month; the round stays in the record.' end,
      rr.withdrawn
    from rounds rr join public.squad_members sm on sm.member_id=rr.member_id
    join public.squads sq on sq.id=sm.squad_id and sq.season_id=se.id
    cross join lateral (values ('squad:'||sq.id),('contribution:'||sq.id||':'||rr.member_id)) scope(row_id)
    -- [I4] D386: a seat taken under way counts forward only, exactly as v_squad_standings;
    -- the golfer's own row (the first branch) still lists every round
    where public._counts_for_seat(rr.round_id, sm.seated_at)
    union all
    select 'golfer:'||a.member_id,'adjustment:'||a.id,null,a.member_id,a.squad_id,
      case when (a.created_at at time zone se.timezone)::date between se.starts_on and se.ends_on
        then ((a.created_at at time zone se.timezone)::date-se.starts_on)/7+1 end,
      (a.created_at at time zone se.timezone)::date,a.month,a.kind,a.points,
      case when a.kind='override' then a.points else 0 end,
      case when a.kind='bye' then 'bye' else 'adjustment' end,
      coalesce(nullif(a.reason,''),'Recorded adjustment')||case when a.kind not in ('override','bye') then ' Does not change the individual points total.' else '' end,
      false
    from public.season_adjustments a join members m on m.member_id=a.member_id
    where a.season_id=se.id and a.kind<>'month_closed'
    union all
    select 'squad:'||a.squad_id,'adjustment:'||a.id,null,a.member_id,a.squad_id,
      case when (a.created_at at time zone se.timezone)::date between se.starts_on and se.ends_on
        then ((a.created_at at time zone se.timezone)::date-se.starts_on)/7+1 end,
      (a.created_at at time zone se.timezone)::date,a.month,a.kind,a.points,a.points,
      case when a.kind='bye' then 'bye' else 'adjustment' end,coalesce(nullif(a.reason,''),'Recorded adjustment'),
      false
    from public.season_adjustments a join squad_rows sq on sq.id=a.squad_id
    where a.season_id=se.id and a.kind<>'month_closed'
  ),
  competitors as (
    select 'golfer:'||m.member_id as id,'golfer'::text as kind,m.name,m.member_id,null::uuid as squad_id,
      m.points,m.points_rank,m.tied,m.member_id=viewer as mine from members m
    union all
    select 'squad:'||sq.id,'squad',sq.name,null,sq.id,sq.points,sq.points_rank,sq.tied,
      exists(select 1 from public.squad_members sm where sm.squad_id=sq.id and sm.member_id=viewer)
    from squad_rows sq
    union all
    select 'contribution:'||sq.id||':'||m.member_id,'contribution',m.name,m.member_id,sq.id,
      coalesce((select sum(e.contribution) from entry_source e where e.row_id='contribution:'||sq.id||':'||m.member_id),0),
      null,false,m.member_id=viewer
    from squad_rows sq join public.squad_members sm on sm.squad_id=sq.id join members m on m.member_id=sm.member_id
  ),
  row_data as (
    select c.*,
      c.points=coalesce((select sum(e.contribution) from entry_source e where e.row_id=c.id),0) as reconciled,
      coalesce((select sum(e.contribution) from entry_source e where e.row_id=c.id and e.week is null),0) as unplaced_points,
      coalesce((select jsonb_agg(to_jsonb(e)-'row_id' order by e.recorded_on nulls last,e.id) from entry_source e where e.row_id=c.id),'[]'::jsonb) as entries,
      (select jsonb_agg(jsonb_build_object('week',w.week,
        'points',case when w.week<=this_week then (select sum(e.contribution) from entry_source e where e.row_id=c.id and e.week=w.week) end,
        'cumulative',case when w.week<=this_week then (select sum(e.contribution) from entry_source e where e.row_id=c.id and e.week<=w.week) end,
        'future',w.week>this_week) order by w.week) from weeks w) as cells
    from competitors c
  )
  select jsonb_build_object(
    'version',2,'league_id',p_league_id,'season_id',se.id,
    'name',(select name from public.leagues where id=p_league_id),'number',se.number,
    'status',se.status,'starts_on',se.starts_on,'ends_on',se.ends_on,'timezone',se.timezone,
    'generated_at',now(),'current_week',this_week,'structure',ls.structure,
    'field_size',(select count(*) from members),
    'counting_cap',ls.counting_cap,'participation_floor',ls.participation_floor,
    -- [I4] a booked season (D383) reads the lines it closed with; only an unbooked one can drift
    'rules_note',case when se.status='complete' and exists (select 1 from public.season_books b where b.season_id=se.id)
                        then 'These are the lines the season closed with. Later rule changes, posts and deletions do not move them.'
                      when se.status='complete' then 'This record uses the league’s current scoring rules; a locked historical rule snapshot is not available.' end,
    'frozen',exists (select 1 from public.season_books b where b.season_id=se.id),
    'coverage_complete',coalesce((select bool_and(reconciled) from row_data),true),
    'weeks',(select jsonb_agg(to_jsonb(w) order by w.week) from weeks w),
    'rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.kind,r.points desc,r.name,r.id) from row_data r),'[]'::jsonb)
  ) into result;
  return result;
end $book$;
revoke all on function public.season_book(uuid,uuid) from public, anon;
grant execute on function public.season_book(uuid,uuid) to authenticated;

-- ── 4 · the tie ladder's squad month scores count from the seat ─────────────
do $patch$
declare v_def text; v_n integer; v_a text;
begin
  v_def := pg_get_functiondef('public.close_season'::regproc);
  if position('[I4]' in v_def) = 0 then
    v_a := E'        join v_rounds_ranked rr on rr.season_id = p_season and rr.member_id = c.member_id\n                               and rr.month_rank <= cap_n\n       group by 1, 2';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[I4] close_season month-score anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      E'        join v_rounds_ranked rr on rr.season_id = p_season and rr.member_id = c.member_id\n'
      || E'                               and rr.month_rank <= cap_n\n'
      || E'                               -- [I4] D386: a late seat counts for the squad from the seat\n'
      || E'                               and (v_solo or public._counts_for_seat(rr.round_id, (select sm0.seated_at from squad_members sm0\n'
      || E'                                     where sm0.squad_id = c.cid and sm0.member_id = c.member_id)))\n'
      || E'       group by 1, 2');
  end if;

  v_def := pg_get_functiondef('public.enter_cup_final'::regproc);
  if position('[I4]' in v_def) = 0 then
    v_a := E'                               and rr.month_rank <= cap_n and rr.played_on < cf_start\n       group by 1, 2';
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[I4] enter_cup_final month-score anchor found % times', v_n; end if;
    execute replace(v_def, v_a,
      E'                               and rr.month_rank <= cap_n and rr.played_on < cf_start\n'
      || E'                               -- [I4] D386: a late seat counts for the squad from the seat\n'
      || E'                               and (st.structure = ''solo'' or public._counts_for_seat(rr.round_id, (select sm0.seated_at from squad_members sm0\n'
      || E'                                     where sm0.squad_id = c.cid and sm0.member_id = c.member_id)))\n'
      || E'       group by 1, 2');
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
begin
  if position('[I4]' in pg_get_functiondef('public.season_book(uuid,uuid)'::regprocedure)) = 0
     or position('[I4]' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('[I4]' in pg_get_functiondef('public.enter_cup_final'::regproc)) = 0 then
    raise exception '[I4] a receipt or a tie-break still counts a round the squad does not';
  end if;
  if position('_counts_for_seat' in pg_get_viewdef('public.v_squad_standings'::regclass)) = 0
     or not exists (select 1 from pg_class where oid = 'public.v_squad_standings'::regclass
                      and 'security_invoker=true' = any(reloptions)) then
    raise exception '[I4] v_squad_standings does not ask the seat helper, or lost security_invoker';
  end if;
  if has_function_privilege('anon', 'public._counts_for_seat(uuid, timestamptz)', 'EXECUTE') then
    raise exception '[I4] the seat helper is reachable signed out';
  end if;
  if has_function_privilege('anon', 'public.season_book(uuid,uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.season_book(uuid,uuid)', 'EXECUTE') then
    raise exception '[I4] season_book grants changed';
  end if;
  -- the earlier fixes in these bodies survive
  if position('[D388]' in pg_get_functiondef('public.close_season'::regproc)) = 0
     or position('[D384]' in pg_get_functiondef('public.enter_cup_final'::regproc)) = 0 then
    raise exception '[I4] an earlier fix was lost';
  end if;
end $chk$;
