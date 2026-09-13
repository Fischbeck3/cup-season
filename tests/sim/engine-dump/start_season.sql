-- start_season(p_season uuid) oid=18484
CREATE OR REPLACE FUNCTION public.start_season(p_season uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare se record; st record; loose int; total int; empty_sq text;
begin
  select * into se from seasons where id = p_season;
  if se.id is null then raise exception 'no such season'; end if;
  select ls.* into st from league_settings ls where ls.league_id = se.league_id;
  -- brand canon §3: "The Pro", never "commissioner", on anything a golfer
  -- reads. This string reaches them as an error toast; the same file already
  -- says "Only the Pro can lock the bylaws." for the identical guard.
  if not is_commissioner(se.league_id) then raise exception 'Only the Pro can start the season.'; end if;

  if st.structure <> 'solo' then
    select count(*) into total from league_members lm where lm.league_id = se.league_id;
    if total < 4 then
      raise exception 'Minimum four to tee off — % in so far. Share the invite link.', total;
    end if;

    select count(*) into loose from league_members lm
    where lm.league_id = se.league_id
      and not exists (select 1 from squad_members x
                      join squads q on q.id = x.squad_id and q.season_id = p_season
                      where x.member_id = lm.id);
    if loose > 0 then
      raise exception '% not on a squad yet — everyone needs one before the first tee', loose;
    end if;

    select q.name into empty_sq
    from squads q left join squad_members sm on sm.squad_id = q.id
    where q.season_id = p_season
    group by q.id, q.name having count(sm.member_id) = 0 limit 1;
    if empty_sq is not null then
      raise exception '% is empty — draw again or assign somebody before the season starts', empty_sq;
    end if;
  end if;

  update leagues set phase = 'season' where id = se.league_id;
  insert into posts (league_id, season_id, kind, body)
  values (se.league_id, p_season, 'system',
          case when se.starts_on > (now() at time zone se.timezone)::date
               then 'The squads are set. First tee ' || to_char(se.starts_on, 'Dy Mon FMDD') || '.'
               else 'The squads are set. The season is live — add your round.' end);
end $function$

