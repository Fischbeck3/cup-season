-- Integration repair, D381/D383. Frozen and withdrawn are additive fields;
-- both deployed Book readers require envelope version 1. Keep that contract
-- while retaining the corrected seat eligibility and frozen scoring lines.
do $patch$
declare d text;
begin
  d := pg_get_functiondef('public.season_book(uuid,uuid)'::regprocedure);
  if position($a$'version',2,$a$ in d) > 0 then
    execute replace(d, $a$'version',2,$a$, $a$'version',1,$a$);
  elsif position($a$'version',1,$a$ in d) = 0 then
    raise exception 'Book envelope version anchor missing';
  end if;
end $patch$;
revoke all on function public.season_book(uuid,uuid) from public, anon;
grant execute on function public.season_book(uuid,uuid) to authenticated;
