-- ============================================================================
-- Cup Season — live-round tables are READ-ONLY to the API (launch review
-- 2026-08-28, blocker #2; security-followups 2026-07-18 M4 / L8, finally).
--
-- The hole: live_rounds (live_write), live_round_players (livep_all) and
-- game_results (gamer_all) carried FOR ALL policies scoped to
-- is_league_member(league_id) — baseline :2101, :2173, :2177 — on top of
-- table-level INSERT/UPDATE/DELETE grants. Any league member could, with a
-- direct PATCH: rewrite another seat's member_id / claimed_profile /
-- guest_profile_id (post a round onto someone else's card at finish, or
-- hijack a guest claim), read every guest's claim_token (the same hijack,
-- one hop later via claim_round), or edit live_rounds.course_snapshot's
-- rating/slope before finish_live_round reads it into the record.
--
-- Every writer is already a SECURITY DEFINER RPC — verified against prod,
-- prosecdef=true for each function whose body writes these tables:
-- start_live_round, live_set_score, live_set_wolf, guest_live_set_score,
-- guest_live_set_wolf, finish_live_round, abandon_live_round, claim_round,
-- delete_account, daily_season_tick. Neither client writes them directly:
-- index.html's only touch is the open-rounds SELECT (:7636), the phone's is
-- LiveRepository.openRounds — both with explicit column lists that do NOT
-- include claim_token (the token reaches the starter through live_state /
-- finish_live_round's return payload, which is where it belongs).
--
-- So: drop the FOR ALL policies, keep/add SELECT-only ones for league
-- members (the phone's realtime + open-rounds reads need them), revoke the
-- write grants at the table level, and SEAL claim_token the way profiles.email
-- was sealed (20260721214500): revoke table-level SELECT on
-- live_round_players, re-grant the explicit column list without it. That
-- freezes the column list — a future live_round_players column MUST be
-- granted in its own migration or every select naming it fails 42501 (the
-- photo_path lesson; check 14 asserts it).
--
-- live_scores: no API grant and no policy in prod (already RPC-only); the
-- revoke below is a no-op kept for symmetry so the check can pin all four.
--
-- Self-enforcing: the DO block RAISES if any write policy or write privilege
-- is left, or if claim_token is still readable. No mechanic change; no
-- functions created.
-- ============================================================================

-- ---- 1 · the FOR ALL policies go ------------------------------------------
drop policy if exists live_write on public.live_rounds;
drop policy if exists livep_all  on public.live_round_players;
drop policy if exists gamer_all  on public.game_results;
drop policy if exists lives_all  on public.live_scores;   -- absent in prod; belt and braces

-- ---- 2 · SELECT for league members (live_read on live_rounds already exists)
create policy livep_read on public.live_round_players
  for select to authenticated
  using (exists (select 1 from public.live_rounds lr
                  where lr.id = live_round_players.live_round_id
                    and public.is_league_member(lr.league_id)));

create policy gamer_read on public.game_results
  for select to authenticated
  using (exists (select 1 from public.live_rounds lr
                  where lr.id = game_results.live_round_id
                    and public.is_league_member(lr.league_id)));

-- ---- 3 · table-level write privileges go ----------------------------------
revoke insert, update, delete, truncate, references, trigger
  on table public.live_rounds, public.live_round_players,
           public.game_results, public.live_scores
  from authenticated;

-- ---- 4 · seal claim_token: table SELECT off, explicit column list back on --
revoke select on table public.live_round_players from authenticated;
grant select (id, live_round_id, member_id, guest_name, guest_index, index_source,
              position, guest_profile_id, claimed_profile, guest_gross, guest_strokes)
  on public.live_round_players to authenticated;

-- ---- 5 · prove it, or fail the push ----------------------------------------
do $$
declare t text; v_pols text;
begin
  foreach t in array array['live_rounds','live_round_players','game_results','live_scores'] loop
    if has_table_privilege('authenticated', 'public.' || t, 'insert')
    or has_table_privilege('authenticated', 'public.' || t, 'update')
    or has_table_privilege('authenticated', 'public.' || t, 'delete') then
      raise exception 'live_tables_participant_scoped: authenticated still holds a write on public.%', t;
    end if;
  end loop;

  select string_agg(c.relname || '.' || p.polname, ', ') into v_pols
    from pg_policy p join pg_class c on c.oid = p.polrelid
   where c.relname in ('live_rounds','live_round_players','game_results','live_scores')
     and p.polcmd in ('w', 'a', 'd', '*');
  if v_pols is not null then
    raise exception 'live_tables_participant_scoped: write policy(ies) remain: %', v_pols;
  end if;

  if has_column_privilege('authenticated', 'public.live_round_players', 'claim_token', 'select') then
    raise exception 'live_tables_participant_scoped: claim_token is still readable by authenticated';
  end if;
  if not has_column_privilege('authenticated', 'public.live_round_players', 'guest_name', 'select')
  or not has_table_privilege('authenticated', 'public.live_rounds', 'select')
  or not has_table_privilege('authenticated', 'public.game_results', 'select') then
    raise exception 'live_tables_participant_scoped: a member SELECT was lost — do not ship';
  end if;
end $$;
