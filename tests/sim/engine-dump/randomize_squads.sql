-- randomize_squads(p_season uuid) oid=18483
CREATE OR REPLACE FUNCTION public.randomize_squads(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  se record; st record; m record;
  sq_n int; total int; pool_n int;
  reveal text := '';
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can do that.'; end if;

  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  if coalesce(st.draft_type, 'random') <> 'random' then
    raise exception 'The Pro picks the squads in this league — tap golfers into squads instead of drawing.';
  end if;

  select count(*) into sq_n from squads where season_id = p_season;
  if sq_n = 0 then raise exception 'No squads yet — set the squads first.'; end if;

  select count(*) into total from league_members lm where lm.league_id = se.league_id;
  if total < sq_n then
    raise exception 'Not enough golfers to cover every squad — % in, % squads. Share the invite link first.', total, sq_n;
  end if;

  select count(*) into pool_n from league_members lm
  where lm.league_id = se.league_id
    and not exists (select 1 from squad_members x
                    join squads q on q.id = x.squad_id and q.season_id = p_season
                    where x.member_id = lm.id);
  if pool_n = 0 then return; end if;   /* nothing to deal — no story, no captain churn */

  for m in
    select lm.id from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id)
    order by random()
  loop
    /* the hat deals to the smallest squad — draws AND redraws stay balanced */
    insert into squad_members (squad_id, member_id)
    select q.id, m.id
    from squads q
    left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id
    order by count(sm.member_id) asc, random()
    limit 1;
  end loop;

  update squads q set captain_member_id = (
    select member_id from squad_members where squad_id = q.id limit 1)
  where q.season_id = p_season and q.captain_member_id is null;

  select string_agg(q.name||' — '||cnt||' golfer'||case when cnt=1 then '' else 's' end, ' · ')
    into reveal
  from (select q.name, count(sm.member_id) cnt
        from squads q left join squad_members sm on sm.squad_id = q.id
        where q.season_id = p_season group by q.name, q.id order by q.name) q;

  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          'The squads are drawn. The hat has spoken. '||coalesce(reveal,''));
end $function$

