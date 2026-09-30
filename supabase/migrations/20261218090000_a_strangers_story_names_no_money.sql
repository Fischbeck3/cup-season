-- X38 follow-up (D397's amendment: every public artifact drops who-pays-whom), 2026-09-29.
--
-- 20261214090000 took `transfers` out of the settlement branch of share_info, but the
-- same branch still sends the stored `game_result.story`, and some games write their
-- money INTO that sentence: solo Sunningdale names the bank and "each owes", and Wolf
-- names each player's signed dollar balance. A stranger holding the link read who
-- owes whom in the JSON (found by Codex's push-9 review). The story now travels only
-- when it carries no money: any "$", "pays", "owes", "from each" or "settle up" drops
-- it (the client's csPublicSettlementText uses the same fail-closed test). With no
-- story, the share page says the result from `winner`/`status`, or "Settled on the
-- course" (renderShareView's existing fallbacks). The stake line stays ("$N a side"
-- is the game, D397); no row is written or read differently anywhere else.
--
-- A NEW migration (CLAUDE.md rule 2: 20261214090000 is applied). One asserted text
-- replacement on the live definition, exactly as 20261214090000 does it; IDEMPOTENT
-- (a second run finds the [X38-story] marker and returns). CREATE OR REPLACE keeps
-- the ACL; the grants are restated anyway (anon and authenticated, D57).

do $patch$
declare
  v_def text;
  v_n   integer;
  a_story constant text := $a$'story',  lr.game_result->>'story',$a$;
  b_story constant text := $b$'story',  -- [X38-story] D397: a stranger's story names no money
                 case when lr.game_result->>'story' ~* '(\$|\mpays?\M|\mowes?\M|from each|settle up)'
                      then null else lr.game_result->>'story' end,$b$;
begin
  v_def := pg_get_functiondef('public.share_info(uuid)'::regprocedure);

  if position('[X38-story]' in v_def) > 0 then
    raise notice '[X38-story] share_info already filters the story; nothing to patch';
    return;
  end if;

  v_n := (length(v_def) - length(replace(v_def, a_story, ''))) / length(a_story);
  if v_n <> 1 then
    raise exception '[X38-story] share_info: the settlement story anchor was found % times; expected once', v_n;
  end if;
  v_def := replace(v_def, a_story, b_story);

  execute v_def;
end $patch$;

revoke all on function public.share_info(uuid) from public;
grant execute on function public.share_info(uuid) to anon, authenticated;

do $assert$
declare
  v_def text := pg_get_functiondef('public.share_info(uuid)'::regprocedure);
begin
  if position('[X38-story]' in v_def) = 0 then
    raise exception '[X38-story] share_info was not patched';
  end if;
  if position('[X38]' in v_def) = 0 then
    raise exception '[X38-story] share_info lost the stranger shape of 20261214090000';
  end if;
  if not has_function_privilege('anon', 'public.share_info(uuid)', 'execute')
     or not has_function_privilege('authenticated', 'public.share_info(uuid)', 'execute') then
    raise exception '[X38-story] share_info lost a grant: every public landing would be dead';
  end if;
  -- the filter itself, on the two shapes the review found and one that must survive
  if 'Casey banks $15; Gray and Kit each owes $5' !~* '(\$|\mpays?\M|\mowes?\M|from each|settle up)'
     or 'Kit +$12, Gray -$4' !~* '(\$|\mpays?\M|\mowes?\M|from each|settle up)'
     or 'Casey & Gray beat Kit & Lee 3&2' ~* '(\$|\mpays?\M|\mowes?\M|from each|settle up)' then
    raise exception '[X38-story] the money test does not separate money from the result';
  end if;
end $assert$;
