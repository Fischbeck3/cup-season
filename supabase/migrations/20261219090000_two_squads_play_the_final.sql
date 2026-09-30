-- Q2 row 5 · spec §14.3 / D126 / SA-3. The finish announcement tells
-- a field of two squads about the head start, never a qualification cut.
-- Patch only its sentence, preserving D384's short-season and window guards.
-- Existing posts are factual history and are not rewritten.
do $patch$
declare
  v_def text;
  v_n integer;
  v_old text := $old$'The Pro set the finish: the Cup Final. Final four weeks, scored fresh, top seeds only.'$old$;
  v_new text := $new$-- [Q2] both squads play; the season decides the head start
              'The Pro set the finish: the Cup Final. ' ||
              case (select structure from league_settings where league_id = p_league)
                when 'squads2' then 'Both squads play the final four weeks, scored fresh. The leading squad carries a 10-point head start.'
                when 'solo' then 'The top two golfers play the final four weeks, scored fresh.'
                when 'squads3' then 'The top two squads play the final four weeks, scored fresh.'
                when 'squads4' then 'The top two squads play the final four weeks, scored fresh.'
                else 'Final four weeks, scored fresh.'
              end$new$;
begin
  v_def := pg_get_functiondef('public.set_league_finish(uuid,text)'::regprocedure);
  if position('[Q2]' in v_def) = 0 then
    v_n := (length(v_def) - length(replace(v_def, v_old, ''))) / length(v_old);
    if v_n <> 1 then raise exception '[Q2] finish sentence found % times; expected once', v_n; end if;
    execute replace(v_def, v_old, v_new);
  end if;
end $patch$;

revoke all on function public.set_league_finish(uuid,text) from public, anon;
grant execute on function public.set_league_finish(uuid,text) to authenticated;

-- The replacement retains the deployed safety guard and removes the cut lie.
do $verify$
declare v_def text := pg_get_functiondef('public.set_league_finish(uuid,text)'::regprocedure);
begin
  if position('[Q2]' in v_def) = 0 or position('[D384]' in v_def) = 0
     or position('top seeds only' in v_def) > 0 then
    raise exception '[Q2] finish announcement or existing short-season guard is missing';
  end if;
end $verify$;
