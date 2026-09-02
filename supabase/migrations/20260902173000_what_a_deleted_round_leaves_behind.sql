-- ============================================================================
-- Cup Season — what a deleted round leaves behind, and what a posted one may
-- carry in (Y-19 · Y-20 · M-16 · M-14 · D124 (i))
--
-- delete_round() removes the row and the engine keeps the number it had: the
-- refresh trigger only ever fired on INSERT, so a golfer who deletes their
-- best round keeps the index that round earned them until the next post.
-- ONE EXCEPTION SURVIVES, deliberately: `round_refresh_index` returns early
-- while `handicap_index()` is null — under three live rounds there is no
-- engine number to write — so a golfer who deletes down to two rounds keeps
-- `index_current` (still stamped `index_source = 'app'`) until they post
-- again. The number follows the ledger both ways once the engine has one.
-- Their trophy case keeps the medal too — the FK sets round_id to null and
-- "Broke 90" stays on the card with no round behind it (prod has three such
-- orphans today, all on one profile). The board lost the opposite way: every
-- post that pointed at the round CASCADEd out with it, taking the clash
-- result and the moment with it.
--
-- On the way in, an authenticated INSERT could name any column: the index
-- snapshot, the attestation flag, posted_by. Nothing on the table stopped it
-- — the BEFORE trigger only fills what is missing. And when the snapshot
-- falls back to the round's own differential (a first round, no starting
-- number) nothing recorded that it did, so the receipt cannot say so.
--
-- AFTER `supabase db push` this batch OWES A CONTRACT REFRESH: `my_achievements()`
-- is dropped and re-created returning `TABLE(kind, label, earned_on, meta,
-- round_id)`, and `score_round(int, numeric, int, numeric, numeric, int, int)`
-- loses its execute grant (20260902170000 §4). Run the refresh query from
-- `packages/db/contract.psv`'s own header, overwrite that file with the
-- result, run `node tools/build-db.mjs`, and commit contract.psv +
-- Generated/Rpc.swift together — preflight check 11 fails the NEXT push until
-- both are current (no Swift file calls `Rpc.score_round(`; `YouRepository`
-- already decodes `round_id` optionally, so nothing breaks before the refresh).
--
--   1 · round_refresh_index fires on DELETE too — tg_op-aware
--   2 · the trophy case after a delete — the receipt's award goes, the rest
--       is re-derived from what remains; today's orphans healed the same way
--   3 · my_achievements() returns the receipt (round_id)
--   4 · posts remember a deleted round as "a round" — SET NULL, not CASCADE
--   5 · what a client may write on a round — INSERT sealed to the payload
--   6 · rounds.index_provisional — marked by the engine, read by round_card
--       as `index_provisional` + `provisional_round` (the two keys the
--       receipt decodes: the flag, and "N of 3")
--   7 · self-check
--
-- Read out of prod on 2026-09-02: posts with round_id = 292 (all keep their
-- row under SET NULL); achievements = 111, 3 with round_id null (first_round,
-- sub_100, sub_90 — one profile, 17 live rounds, earliest 2026-03-22, best
-- gross 80); rounds ACL is table-level authenticated=arwdDxtm; both clients
-- insert exactly gross, rating, nine_rating, slope, holes_played, source,
-- played_on, course_label, api_course_id, season_id, photo_path.
-- ============================================================================

-- ── 1 · the number follows the ledger both ways ─────────────────────────────
-- Body = prod 2026-09-02 verbatim, reading OLD on a delete (an AFTER DELETE
-- row has no NEW). The early return when the engine has no number yet
-- (fewer than three rounds) is kept as it was: index_current stays.
create or replace function public.round_refresh_index()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
declare v_auto numeric; v_old numeric; v_src text; v_name text;
        v_pid uuid; v_voided boolean;
begin
  -- Y-19 · INSERT reads NEW, DELETE reads OLD; the return value of an AFTER
  -- row trigger is ignored either way.
  if tg_op = 'DELETE' then
    v_pid := old.profile_id; v_voided := old.voided;
  else
    v_pid := new.profile_id; v_voided := new.voided;
  end if;
  if v_voided then return null; end if;
  v_auto := handicap_index(v_pid);                   -- non-null once >= 3 rounds
  if v_auto is null then return null; end if;

  select index_current, index_source, display_name
    into v_old, v_src, v_name from profiles where id = v_pid;

  update profiles set index_current = v_auto, index_source = 'app'
   where id = v_pid;                                  -- scores are the truth

  -- announce ONLY the handoff: scores taking over a manual starter, and only
  -- when the number actually moves. Routine per-round updates stay silent.
  if coalesce(v_src, 'app') in ('self', 'ghin') and v_old is distinct from v_auto then
    insert into posts (league_id, kind, member_id, body)
    select lm.league_id, 'system', lm.id,
           coalesce(v_name, 'A golfer') || '''s number now comes from their scores — '
             || coalesce(v_old::text, 'starter') || ' → ' || v_auto
      from league_members lm where lm.profile_id = v_pid;
  end if;
  return null;
end $function$;

drop trigger if exists round_refresh_index_trg on public.rounds;
create trigger round_refresh_index_trg
  after insert or delete on public.rounds
  for each row execute function public.round_refresh_index();

-- ── 2 · the trophy case after a delete ──────────────────────────────────────
-- The three career-first awards are derivable from the ledger (that is how
-- 20260716020000 backfilled them). This helper re-runs those derivations for
-- one profile, additively — `on conflict do nothing` — so a medal the
-- remaining rounds still earn comes back with its true receipt, and a medal
-- they no longer earn stays gone. Streaks are forward-only (as the backfill
-- ruled) and are not re-derived.
create or replace function public.rederive_achievements(p_profile uuid)
returns void
language plpgsql
security definer
set search_path = public
as $function$
begin
  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'first_round', 'First round posted', r.played_on, r.id,
         jsonb_build_object('gross', r.gross)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and coalesce(r.source, 'app') <> 'sim'
   order by r.played_on, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select distinct on (thr.t) r.profile_id, 'sub_' || thr.t, 'Broke ' || thr.t,
         r.played_on, r.id, jsonb_build_object('gross', r.gross)
    from rounds r
    cross join unnest(array[100, 90, 80]) as thr(t)
   where r.profile_id = p_profile
     and not r.voided and r.holes_played = 18 and r.gross is not null
     and r.gross < thr.t and coalesce(r.source, 'app') <> 'sim'
   order by thr.t, r.played_on, r.id
  on conflict (profile_id, kind) do nothing;

  insert into achievements (profile_id, kind, label, earned_on, round_id, meta)
  select r.profile_id, 'personal_best', 'Personal best',
         r.played_on, r.id, jsonb_build_object('diff', r.differential)
    from rounds r
   where r.profile_id = p_profile
     and not r.voided and r.differential is not null and coalesce(r.source, 'app') <> 'sim'
   order by r.differential asc, r.played_on desc, r.id
   limit 1
  on conflict (profile_id, kind) do nothing;
end $function$;

revoke all on function public.rederive_achievements(uuid) from public, anon, authenticated;

-- BEFORE the row goes: the award whose receipt this round was is deleted
-- while round_id still points at it (the FK's SET NULL runs after). AFTER
-- the row is gone: what the remaining ledger still earns is re-derived.
create or replace function public.round_achievements_on_delete()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  if tg_when = 'BEFORE' then
    delete from achievements where round_id = old.id;
    return old;
  end if;
  perform rederive_achievements(old.profile_id);
  return null;
end $function$;

revoke all on function public.round_achievements_on_delete() from public, anon, authenticated;

drop trigger if exists round_achievements_before_delete_trg on public.rounds;
create trigger round_achievements_before_delete_trg
  before delete on public.rounds
  for each row execute function public.round_achievements_on_delete();

drop trigger if exists round_achievements_after_delete_trg on public.rounds;
create trigger round_achievements_after_delete_trg
  after delete on public.rounds
  for each row execute function public.round_achievements_on_delete();

-- today's orphans: an award with no receipt is a medal nobody can show. Every
-- award in the table is a round award (season hardware lives in trophies),
-- so a null round_id can only mean the receipt was deleted.
do $heal$
declare v_p uuid; v_n integer; v_gone integer := 0; v_profiles integer := 0;
begin
  for v_p in select distinct profile_id from achievements where round_id is null loop
    v_profiles := v_profiles + 1;
    delete from achievements where profile_id = v_p and round_id is null;
    get diagnostics v_n = row_count;
    v_gone := v_gone + v_n;
    perform rederive_achievements(v_p);
  end loop;
  raise notice '[Y-19] % orphaned award(s) on % profile(s) removed and re-derived', v_gone, v_profiles;
end $heal$;

-- ── 3 · the receipt on the card ─────────────────────────────────────────────
-- Same name, same arguments; the return type widens by one nullable column,
-- which needs a drop (CREATE OR REPLACE cannot change a result type).
drop function if exists public.my_achievements();
create function public.my_achievements()
returns table (kind text, label text, earned_on date, meta jsonb, round_id uuid)
language sql
stable
security definer
set search_path = public
as $function$
  select kind, label, earned_on, meta, round_id
    from achievements
   where profile_id = auth.uid()
   order by earned_on desc, kind;
$function$;

revoke all on function public.my_achievements() from public, anon;
grant execute on function public.my_achievements() to authenticated;

-- ── 4 · posts remember ──────────────────────────────────────────────────────
-- A clash result, a moment, a "took the week" line: the sentence stays on the
-- board when its round goes; only the link goes.
alter table public.posts drop constraint if exists posts_round_id_fkey;
alter table public.posts
  add constraint posts_round_id_fkey
  foreign key (round_id) references public.rounds(id) on delete set null;

-- ── 5 · what a client may write on a round ──────────────────────────────────
-- A column REVOKE never subtracts from a table grant, so the table privilege
-- goes and the payload's columns come back one by one. profile_id, the index
-- snapshot, attested, posted_by, voided, index_provisional and the rest are
-- the engine's to fill (BEFORE-trigger assignments are not privilege-checked).
revoke insert on public.rounds from authenticated;
grant insert (gross, rating, nine_rating, slope, holes_played, source, played_on,
              course_label, api_course_id, season_id, photo_path)
  on public.rounds to authenticated;

-- ── 6 · the provisional number, marked ──────────────────────────────────────
-- FORWARD-ONLY, deliberately: the flag is a fact the engine knows at post
-- time and nowhere else. A backfill would have to GUESS it from
-- `index_at_post = differential`, which is also true of any round a golfer
-- happened to play to their number — a wrong receipt is worse than none, so
-- rounds posted before this migration stay false and read as they do today.
alter table public.rounds
  add column if not exists index_provisional boolean not null default false;
comment on column public.rounds.index_provisional is
  'D124 (i) · true when the index snapshot fell back to this round''s own '
  'differential (no caller number, no standing number, no engine number yet). '
  'Set by score_round(); read back by round_card() as index_provisional, '
  'alongside provisional_round ("N of 3"). Forward-only — never backfilled.';

-- Body = prod verbatim plus the one flag line before the fallback.
create or replace function public.score_round()
returns trigger
language plpgsql
security definer
set search_path = public
as $function$
begin
  if new.profile_id is null then new.profile_id := auth.uid(); end if;

  -- differential first (index-independent)
  if new.holes_played = 9 and new.nine_rating is not null then
    new.differential := round(((new.gross - new.nine_rating) * 113.0 / new.slope) * 2, 1);
  else
    new.differential := round((new.gross - new.rating) * 113.0 / new.slope, 1);
  end if;

  -- index snapshot: caller-provided > standing index > engine(prior rounds) >
  -- this round's own differential (first-round provisional). NEVER a blind 18.
  if new.index_at_post is null then
    select index_current into new.index_at_post from profiles where id = new.profile_id;
  end if;
  if new.index_at_post is null then
    new.index_at_post := handicap_index_asof(new.profile_id, new.played_on, new.id);
  end if;
  new.index_provisional := (new.index_at_post is null);   -- D124 (i): the fallback fired
  new.index_at_post := coalesce(new.index_at_post, new.differential);

  return new;
end $function$;

-- Body = prod verbatim plus two keys: `index_provisional` and, when it is
-- true, `provisional_round` — which of the three starting rounds this is.
create or replace function public.round_card(p_round uuid)
returns jsonb
language plpgsql
stable security definer
set search_path = public
as $function$
declare
  v uuid := auth.uid();
  r rounds%rowtype;
  v_rank record;
  v_mates jsonb;
  v_prov integer;
begin
  if v is null then raise exception 'Sign in first'; end if;
  select * into r from rounds where id = p_round;
  if r.id is null then raise exception 'No such round'; end if;

  -- yours, or posted by someone you share a league with
  if r.profile_id is distinct from v and not exists (
    select 1 from league_members a
      join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = r.profile_id)
  then raise exception 'That round is not yours to read'; end if;

  -- the scoring lens: points and where it lands in the month's counting cap
  select rr.points, rr.month_rank, rr.playing_index, rr.pvi, ls.counting_cap
    into v_rank
    from v_rounds_ranked rr
    join league_members lm on lm.id = rr.member_id
    join league_settings ls on ls.league_id = lm.league_id
   where rr.round_id = r.id and lm.profile_id = r.profile_id
   order by rr.month_rank limit 1;

  -- who was there: the live round's roster when there was one, else the
  -- attestation names the finish recorded
  select coalesce(jsonb_agg(distinct nm), '[]'::jsonb) into v_mates from (
    select coalesce(pr.display_name, lp.guest_name) as nm
      from live_round_players lp
      left join league_members m on m.id = lp.member_id
      left join profiles pr on pr.id = m.profile_id
     where r.live_round_id is not null and lp.live_round_id = r.live_round_id
    union
    select a.attested_by from attestations a where a.round_id = r.id
  ) t where nm is not null and nm <> coalesce((select display_name from profiles where id = r.profile_id), '');

  -- D124 (i) · which of the three starting rounds this is. Counted over the
  -- rounds the engine itself reads (handicap_index_asof: not voided, not sim,
  -- a differential) and ordered the way it orders them, so "2 of 3" means the
  -- second round the number will be built from. Null unless the fallback
  -- fired and this is still one of the first three — the receipt prints the
  -- parenthetical only when the count is there, and never counts rounds itself.
  if r.index_provisional then
    select count(*) into v_prov
      from rounds r2
     where r2.profile_id = r.profile_id
       and not r2.voided and coalesce(r2.source, 'app') <> 'sim'
       and r2.differential is not null
       and (r2.played_on, r2.id) <= (r.played_on, r.id);
    if v_prov < 1 or v_prov > 3 then v_prov := null; end if;
  end if;

  return jsonb_build_object(
    'id', r.id,
    'gross', r.gross,
    'holes_played', r.holes_played,
    'played_on', r.played_on,
    'course_label', r.course_label,
    'rating', r.rating,
    'slope', r.slope,
    'nine_rating', r.nine_rating,
    'differential', r.differential,
    'index_at_post', r.index_at_post,
    'index_provisional', r.index_provisional,
    'provisional_round', v_prov,
    'playing_index', v_rank.playing_index,
    'pvi', coalesce(v_rank.pvi, r.index_at_post - r.differential),
    'points', v_rank.points,
    'month_rank', v_rank.month_rank,
    'counting_cap', v_rank.counting_cap,
    'source', r.source,
    'attested', r.attested,
    'photo_path', r.photo_path,
    'live_round_id', r.live_round_id,
    'profile_id', r.profile_id,
    'golfer', (select display_name from profiles where id = r.profile_id),
    'is_mine', (r.profile_id = v),
    'played_with', v_mates);
end $function$;

revoke all on function public.round_card(uuid) from public, anon;
grant execute on function public.round_card(uuid) to authenticated;

-- ── 7 · self-check ──────────────────────────────────────────────────────────
do $chk$
declare v_def text; v_n integer; v_col text;
begin
  -- Y-19 · the refresh fires both ways and reads the right row
  select pg_get_triggerdef(t.oid) into v_def from pg_trigger t
   where t.tgrelid = 'public.rounds'::regclass and t.tgname = 'round_refresh_index_trg';
  if v_def is null or v_def not like '%AFTER INSERT OR DELETE ON public.rounds%' then
    raise exception '[Y-19] round_refresh_index_trg is not AFTER INSERT OR DELETE';
  end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'round_refresh_index'
                    and p.prosrc like '%tg_op = ''DELETE''%' and p.prosrc like '%handicap_index(v_pid)%') then
    raise exception '[Y-19] round_refresh_index is not tg_op-aware';
  end if;
  if not exists (select 1 from pg_trigger where tgrelid = 'public.rounds'::regclass
                    and tgname = 'round_achievements_before_delete_trg')
     or not exists (select 1 from pg_trigger where tgrelid = 'public.rounds'::regclass
                    and tgname = 'round_achievements_after_delete_trg') then
    raise exception '[Y-19] the achievements delete triggers are missing';
  end if;
  select count(*) into v_n from achievements where round_id is null;
  if v_n > 0 then
    raise exception '[Y-19] % achievement(s) still carry no receipt', v_n;
  end if;

  -- Y-20 · the card gets the receipt
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'my_achievements'
                    and pg_get_function_result(p.oid) = 'TABLE(kind text, label text, earned_on date, meta jsonb, round_id uuid)'
                    and has_function_privilege('authenticated', p.oid, 'execute')
                    and not has_function_privilege('anon', p.oid, 'execute')) then
    raise exception '[Y-20] my_achievements() does not return round_id to authenticated';
  end if;

  -- M-16 · posts keep their row
  if not exists (select 1 from pg_constraint
                  where conrelid = 'public.posts'::regclass and conname = 'posts_round_id_fkey'
                    and confdeltype = 'n') then
    raise exception '[M-16] posts_round_id_fkey is not ON DELETE SET NULL';
  end if;

  -- M-14 · the INSERT surface is exactly the payload
  if has_table_privilege('authenticated', 'public.rounds', 'INSERT') then
    raise exception '[M-14] authenticated still holds table-level INSERT on rounds';
  end if;
  foreach v_col in array array['gross','rating','nine_rating','slope','holes_played','source',
                               'played_on','course_label','api_course_id','season_id','photo_path'] loop
    if not has_column_privilege('authenticated', 'public.rounds', v_col, 'INSERT') then
      raise exception '[M-14] authenticated cannot insert rounds.%', v_col;
    end if;
  end loop;
  foreach v_col in array array['id','profile_id','index_at_post','attested','posted_by','voided',
                               'differential','index_source_at_post','index_provisional'] loop
    if has_column_privilege('authenticated', 'public.rounds', v_col, 'INSERT') then
      raise exception '[M-14] authenticated can still insert rounds.%', v_col;
    end if;
  end loop;
  if not has_table_privilege('authenticated', 'public.rounds', 'SELECT') then
    raise exception '[M-14] rounds SELECT was lost';
  end if;

  -- D124 (i) · the flag exists, the engine sets it, the card returns it
  if not exists (select 1 from information_schema.columns
                  where table_schema = 'public' and table_name = 'rounds' and column_name = 'index_provisional') then
    raise exception '[D124] rounds.index_provisional missing';
  end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'score_round' and p.prorettype = 'trigger'::regtype
                    and p.prosrc like '%new.index_provisional := (new.index_at_post is null);%'
                    and p.prosrc like '%new.index_at_post := coalesce(new.index_at_post, new.differential);%') then
    raise exception '[D124] score_round() does not mark the provisional number';
  end if;
  if not exists (select 1 from pg_proc p join pg_namespace n on n.oid = p.pronamespace
                  where n.nspname = 'public' and p.proname = 'round_card'
                    and p.prosrc like '%''index_provisional'', r.index_provisional%'
                    and p.prosrc like '%''provisional_round'', v_prov%'
                    and has_function_privilege('authenticated', p.oid, 'execute')) then
    raise exception '[D124] round_card does not return index_provisional / provisional_round';
  end if;
end $chk$;
