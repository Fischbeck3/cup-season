-- D383 (OWNER-RULED 2026-09-24) · launch audit S2, L-02 + L-33.
-- A finished season keeps its book.
--
-- The lens (v_rounds_ranked) scored a COMPLETE season live from `rounds`, by
-- date, with no cut at the close. So after the crown a member could move the
-- finished table and the Points King by posting a round dated inside the
-- season (1, 30 or 366 days later), deleting a counted round, posting for
-- another league on an overlapping date, or inserting a round directly. The
-- stored crown stayed put, so the ceremony and the table named different
-- winners (launch audit L-02, reproduced on the real engine).
--
-- The fix is a book, not a cut. When a season turns complete, a trigger copies
-- that season's lens rows into `season_book_rows` and marks it in
-- `season_books`; from then on the lens reads a booked season from its book
-- and never from live rounds. That closes every route at once (late post,
-- delete, cross-league, direct insert, and any later change to membership),
-- and it is what the owner ruled for a delete (D383 §2): the golfer's delete
-- still removes the round from their card, their index and their record
-- (delete_round is untouched), and the finished table keeps the line it
-- closed with.
--
-- Existing complete seasons are booked here from the live lens, cut at the
-- moment the crown was read: close_season writes its story and settlement as
-- the season's last `system` posts in the same transaction as the crown, so a
-- round created after that post cannot have counted toward it and drops back
-- out (D383 §3: the crown stands). Not the grace deadline: a season whose
-- rounds were entered late but before its close was crowned WITH them. A
-- season with no close post is booked as it stands, and the notice counts
-- them. A round DELETED after a close cannot be recovered; prod-exposure
-- Q1/Q1b says whether any was.
--
-- Also (D383 §4, L-33): post_round no longer stamps a complete season, and
-- run_it_back refuses a first tee on or before the previous season's last day.
--
-- The lens text is patched from the LIVE definition by anchor, as 20261115090000
-- did, and security_invoker is set again (create or replace view drops it).

-- ── 1 · the book ────────────────────────────────────────────────────────────
create table if not exists public.season_books (
  season_id   uuid primary key references public.seasons(id) on delete cascade,
  booked_at   timestamptz not null default now(),
  rows_booked integer not null default 0,
  source      text not null default 'close' check (source in ('close', 'backfill'))
);
create table if not exists public.season_book_rows (
  season_id     uuid not null references public.season_books(season_id) on delete cascade,
  member_id     uuid not null,
  round_id      uuid not null,
  profile_id    uuid not null,
  played_on     date not null,
  holes_played  integer,
  source        text,
  attested      boolean,
  differential  numeric(5,1),
  index_at_post numeric(4,1),
  playing_index numeric,
  pvi           numeric,
  points        integer,
  floor_credit  numeric,
  primary key (season_id, member_id, round_id)
);
create index if not exists season_book_rows_member on public.season_book_rows (member_id, season_id);

alter table public.season_books     enable row level security;
alter table public.season_book_rows enable row level security;
revoke all on table public.season_books from public, anon, authenticated;
revoke all on table public.season_book_rows from public, anon, authenticated;
grant select on table public.season_books to authenticated;
grant select on table public.season_book_rows to authenticated;

drop policy if exists season_books_read on public.season_books;
create policy season_books_read on public.season_books for select to authenticated
  using (public.is_league_member((select s.league_id from public.seasons s where s.id = season_id)));
drop policy if exists season_book_rows_read on public.season_book_rows;
create policy season_book_rows_read on public.season_book_rows for select to authenticated
  using (public.is_league_member((select s.league_id from public.seasons s where s.id = season_id)));

-- ── 2 · the lens reads a booked season from its book ────────────────────────
do $patch$
declare v_def text; v_new text; v_a1 text; v_a2 text; v_n integer;
begin
  v_def := pg_get_viewdef('public.v_rounds_ranked'::regclass, true);
  if position('season_book_rows' in v_def) > 0 then
    raise notice '[D383] v_rounds_ranked already reads the book';
  else
    v_a1 := 'AND (s.number = ANY (lm.agreed_seasons))';
    v_n := (length(v_def) - length(replace(v_def, v_a1, ''))) / length(v_a1);
    if v_n <> 1 then raise exception '[D383] lens anchor 1 found % times; expected once', v_n; end if;
    v_a2 := E'\n        )\n SELECT member_id,';
    v_n := (length(v_def) - length(replace(v_def, v_a2, ''))) / length(v_a2);
    if v_n <> 1 then raise exception '[D383] lens anchor 2 found % times; expected once', v_n; end if;

    v_new := replace(v_def, v_a1,
      v_a1 || ' AND (NOT (EXISTS ( SELECT 1 FROM season_books bk WHERE bk.season_id = s.id)))');
    v_new := replace(v_new, v_a2,
      E'\n        UNION ALL\n         SELECT br.member_id, br.season_id, br.round_id, br.profile_id, br.played_on,'
      || ' br.holes_played, br.source, br.attested, br.differential, br.index_at_post,'
      || ' br.playing_index, br.pvi, br.points, br.floor_credit'
      || ' FROM season_book_rows br' || v_a2);
    execute 'create or replace view public.v_rounds_ranked as ' || rtrim(v_new, E'; \n');
  end if;
  execute 'alter view public.v_rounds_ranked set (security_invoker = true)';
end $patch$;

-- ── 3 · the close writes the book ───────────────────────────────────────────
-- Fires on every path that completes a season (close_season, the tick, any
-- future engine), so no caller can forget it. Rows are read from the lens
-- BEFORE the season is marked booked, i.e. exactly the table the crown was
-- read from in the same transaction. A season that leaves complete (an
-- operator repair) loses its book and is scored live again.
create or replace function public._book_season()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if new.status = 'complete' and old.status is distinct from 'complete' then
    if exists (select 1 from season_books where season_id = new.id) then return new; end if;
    -- one statement: every CTE reads the same snapshot, so the lens read in
    -- `hold` cannot see the marker `mark` writes beside it
    with hold as materialized (
      select season_id, member_id, round_id, profile_id, played_on, holes_played, source,
             attested, differential, index_at_post, playing_index, pvi, points, floor_credit
        from v_rounds_ranked where season_id = new.id
    ), mark as (
      insert into season_books (season_id, rows_booked, source)
      values (new.id, (select count(*) from hold), 'close')
      returning season_id
    )
    insert into season_book_rows
      select h.* from hold h cross join mark;
  elsif old.status = 'complete' and new.status is distinct from 'complete' then
    delete from season_books where season_id = new.id;
  end if;
  return new;
end $$;
revoke all on function public._book_season() from public, anon, authenticated;

drop trigger if exists seasons_book_on_close on public.seasons;
create trigger seasons_book_on_close
  after update of status on public.seasons
  for each row execute function public._book_season();

-- ── 4 · book the seasons that are already finished (D383 §3) ────────────────
do $backfill$
declare v_seasons integer; v_rows integer;
begin
  create temp table _bf on commit drop as
    select rr.season_id, rr.member_id, rr.round_id, rr.profile_id, rr.played_on, rr.holes_played,
           rr.source, rr.attested, rr.differential, rr.index_at_post, rr.playing_index, rr.pvi,
           rr.points, rr.floor_credit
      from v_rounds_ranked rr
      join seasons s on s.id = rr.season_id and s.status = 'complete'
      join rounds r on r.id = rr.round_id
      left join lateral (select max(p.created_at) as closed_at from posts p
                          where p.season_id = s.id and p.kind = 'system') c on true
     where not exists (select 1 from season_books b where b.season_id = s.id)
       and (c.closed_at is null or r.created_at <= c.closed_at);
  insert into season_books (season_id, rows_booked, source)
    select s.id, (select count(*) from _bf where _bf.season_id = s.id), 'backfill'
      from seasons s
     where s.status = 'complete'
       and not exists (select 1 from season_books b where b.season_id = s.id);
  get diagnostics v_seasons = row_count;
  insert into season_book_rows select * from _bf;
  get diagnostics v_rows = row_count;
  raise notice '[D383] booked % finished season(s), % round line(s); % with no close post, booked as they stand',
    v_seasons, v_rows,
    (select count(*) from seasons s where s.status = 'complete'
        and not exists (select 1 from posts p where p.season_id = s.id and p.kind = 'system'));
end $backfill$;

-- ── 5 · post_round stops stamping a finished season (D383 §4) ───────────────
do $patch$
declare v_def text; v_a text := $a$s.status in ('active', 'cup_final', 'complete')$a$; v_n integer;
begin
  v_def := pg_get_functiondef('public.post_round'::regproc);
  v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
  if v_n = 0 and position($a$s.status in ('active', 'cup_final')$a$ in v_def) > 0 then
    raise notice '[D383] post_round already skips complete seasons';
  elsif v_n <> 1 then
    raise exception '[D383] post_round anchor found % times; expected once', v_n;
  else
    execute replace(v_def, v_a, $a$s.status in ('active', 'cup_final')$a$);
  end if;
end $patch$;

-- ── 6 · run_it_back refuses an overlapping first tee (D383 §4, L-33) ───────
do $patch$
declare v_def text;
  v_a text := $a$if v_ends <= v_starts then raise exception 'A season ends after it starts.'; end if;$a$;
  v_n integer;
begin
  v_def := pg_get_functiondef('public.run_it_back'::regproc);
  if position('[D383]' in v_def) > 0 then
    raise notice '[D383] run_it_back already refuses an overlap';
  else
    v_n := (length(v_def) - length(replace(v_def, v_a, ''))) / length(v_a);
    if v_n <> 1 then raise exception '[D383] run_it_back anchor found % times; expected once', v_n; end if;
    execute replace(v_def, v_a, v_a || $b$
  -- [D383] a round in an overlap would fan into both seasons
  if v_starts <= v_last.ends_on then
    raise exception 'The next season tees off after this one ends (%). Pick a first tee from % on.',
      to_char(v_last.ends_on, 'Dy Mon FMDD'), to_char(v_last.ends_on + 1, 'Dy Mon FMDD');
  end if;$b$);
  end if;
end $patch$;

-- ── self-check (read-only; it never touches a real row — D215) ──────────────
do $chk$
declare v_def text; v_n integer;
begin
  v_def := pg_get_viewdef('public.v_rounds_ranked'::regclass, true);
  if position('season_book_rows' in v_def) = 0 or position('season_books bk' in v_def) = 0 then
    raise exception '[D383] the lens does not read the book';
  end if;
  -- earlier fixes must survive the patch (checks 25 and 37 read these)
  if position('agreed_seasons' in v_def) = 0 or position('prior_left_at' in v_def) = 0
     or position('r.created_at < lm.left_at' in v_def) = 0 or position('NOT r.voided' in v_def) = 0 then
    raise exception '[D383] the lens lost an earlier conjunct';
  end if;
  if not exists (select 1 from pg_class where oid = 'public.v_rounds_ranked'::regclass
                   and 'security_invoker=true' = any(reloptions)) then
    raise exception '[D383] the lens lost security_invoker';
  end if;
  select count(*) into v_n from seasons s
   where s.status = 'complete' and not exists (select 1 from season_books b where b.season_id = s.id);
  if v_n > 0 then raise exception '[D383] % complete season(s) have no book', v_n; end if;
  if not exists (select 1 from pg_trigger where tgname = 'seasons_book_on_close'
                   and tgrelid = 'public.seasons'::regclass and not tgisinternal) then
    raise exception '[D383] the close does not write the book';
  end if;
  if has_table_privilege('anon', 'public.season_book_rows', 'SELECT')
     or has_table_privilege('authenticated', 'public.season_book_rows', 'INSERT')
     or has_function_privilege('authenticated', 'public._book_season()', 'EXECUTE') then
    raise exception '[D383] a client role can reach the book';
  end if;
  if position($a$'active', 'cup_final', 'complete'$a$ in pg_get_functiondef('public.post_round'::regproc)) > 0 then
    raise exception '[D383] post_round still stamps a complete season';
  end if;
  if position('[D383]' in pg_get_functiondef('public.run_it_back'::regproc)) = 0 then
    raise exception '[D383] run_it_back does not refuse an overlap';
  end if;
end $chk$;
