-- D381: read-only points record. No scoring view or historical round is changed.
-- The two contribution lenses intentionally preserve D376: individual totals
-- include overrides; squad totals include every squad adjustment.
create or replace function public.season_book(p_league_id uuid, p_season_id uuid)
returns jsonb language plpgsql stable security definer set search_path = public
as $book$
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
      rr.month_rank<=coalesce(ls.counting_cap,999) as counting
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
      case when rr.counting then 'Counting round' else 'Outside the best '||ls.counting_cap||' for this calendar month; the round stays in the record.' end as reason
    from rounds rr
    union all
    select scope.row_id, 'round:'||rr.round_id,rr.round_id,rr.member_id,sq.id,rr.week,
      rr.played_on,date_trunc('month',rr.played_on)::date,'round',rr.points,
      case when rr.counting then rr.points else 0 end,
      case when rr.counting then 'counting' else 'dropped' end,
      case when rr.counting then 'Counting round' else 'Outside the best '||ls.counting_cap||' for this calendar month; the round stays in the record.' end
    from rounds rr join public.squad_members sm on sm.member_id=rr.member_id
    join public.squads sq on sq.id=sm.squad_id and sq.season_id=se.id
    cross join lateral (values ('squad:'||sq.id),('contribution:'||sq.id||':'||rr.member_id)) scope(row_id)
    union all
    select 'golfer:'||a.member_id,'adjustment:'||a.id,null,a.member_id,a.squad_id,
      case when (a.created_at at time zone se.timezone)::date between se.starts_on and se.ends_on
        then ((a.created_at at time zone se.timezone)::date-se.starts_on)/7+1 end,
      (a.created_at at time zone se.timezone)::date,a.month,a.kind,a.points,
      case when a.kind='override' then a.points else 0 end,
      case when a.kind='bye' then 'bye' else 'adjustment' end,
      coalesce(nullif(a.reason,''),'Recorded adjustment')||case when a.kind not in ('override','bye') then ' Does not change the individual points total.' else '' end
    from public.season_adjustments a join members m on m.member_id=a.member_id
    where a.season_id=se.id and a.kind<>'month_closed'
    union all
    select 'squad:'||a.squad_id,'adjustment:'||a.id,null,a.member_id,a.squad_id,
      case when (a.created_at at time zone se.timezone)::date between se.starts_on and se.ends_on
        then ((a.created_at at time zone se.timezone)::date-se.starts_on)/7+1 end,
      (a.created_at at time zone se.timezone)::date,a.month,a.kind,a.points,a.points,
      case when a.kind='bye' then 'bye' else 'adjustment' end,coalesce(nullif(a.reason,''),'Recorded adjustment')
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
    'version',1,'league_id',p_league_id,'season_id',se.id,
    'name',(select name from public.leagues where id=p_league_id),'number',se.number,
    'status',se.status,'starts_on',se.starts_on,'ends_on',se.ends_on,'timezone',se.timezone,
    'generated_at',now(),'current_week',this_week,'structure',ls.structure,
    'field_size',(select count(*) from members),
    'counting_cap',ls.counting_cap,'participation_floor',ls.participation_floor,
    'rules_note',case when se.status='complete' then 'This record uses the league’s current scoring rules; a locked historical rule snapshot is not available.' end,
    'coverage_complete',coalesce((select bool_and(reconciled) from row_data),true),
    'weeks',(select jsonb_agg(to_jsonb(w) order by w.week) from weeks w),
    'rows',coalesce((select jsonb_agg(to_jsonb(r) order by r.kind,r.points desc,r.name,r.id) from row_data r),'[]'::jsonb)
  ) into result;
  return result;
end $book$;
revoke all on function public.season_book(uuid,uuid) from public, anon;
grant execute on function public.season_book(uuid,uuid) to authenticated;

-- Home already reads these same standings views. Keep stable alphabetical
-- display order for neighbours, but remove it from points rank. This patches
-- the latest definition in place without reverting subsequent home features.
do $patch$
declare src text; updated text;
begin
  src:=pg_get_functiondef('public.native_home()'::regprocedure);
  if position('''points_tied''' in src)=0 then
    updated:=replace(src,'select vs.squad_id, vs.points,'||chr(10)||'                   rank()       over w as rk,',
      'select vs.squad_id, vs.points,'||chr(10)||'                   rank() over (order by vs.points desc) as rk, count(*) over (partition by vs.points)>1 as tied,');
    updated:=replace(updated,'select vi.member_id, vi.points,'||chr(10)||'                   rank()       over w as rk,',
      'select vi.member_id, vi.points,'||chr(10)||'                   rank() over (order by vi.points desc) as rk, count(*) over (partition by vi.points)>1 as tied,');
    if updated=src or position('rank()       over w as rk' in updated)>0 then
      raise exception 'D381: native_home standing anchors changed; inspect before applying';
    end if;
    updated:=replace(updated,'''rank'',             st.rk,','''rank'',             st.rk, ''points_rank'', st.rk, ''points_tied'', st.tied,');
    if position('''points_tied''' in updated)=0 then raise exception 'D381: missing standing fields'; end if;
    execute updated;
  end if;
end $patch$;
