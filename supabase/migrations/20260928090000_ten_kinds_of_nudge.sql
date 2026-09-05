-- C-6 · D248 · Ten kinds of nudge, and a table only a producer may write to.
--
-- WHAT THIS FILE DOES, AND — MORE IMPORTANTLY — WHAT IT DELIBERATELY DOES NOT.
--
-- D248 rules ten new `push_nudges.kind` values: NINE nudges, each naming one of
-- D23's eight emotions (L-20 — a nudge names an emotion or it does not render),
-- and ONE transactional notice, `season_cancel`, ruled explicitly OUTSIDE the
-- nudge policy under D71/L-38 because "consent" is not one of the eight and
-- labelling it with a word that is not on the list would break the law rather
-- than satisfy it.
--
-- THE GATE (D248's own tradeoff, and it is the owner's condition): no push
-- PRODUCER ships until one production APNs token has received one real push.
-- `device_tokens` holds one `ios-sandbox` row. So this file widens the CHECK
-- and seals the table, and it writes NOTHING and grants NO new function. The
-- vocabulary can exist before the producers do; the reverse — ten writers on a
-- rail nobody has seen work — is what the gate exists to prevent. Its own
-- self-check asserts that nothing in this database inserts one of the new kinds
-- yet, so the day a producer lands, it lands deliberately.
--
-- L-05: every check below is read-only and mutates no real row.

-- ---------------------------------------------------------------------------
-- 1 · the vocabulary
-- ---------------------------------------------------------------------------
-- `20260827210000_push_wave7.sql:36-38` wrote the first four; D237's own
-- migration added `callout`. Both files (and this one) `drop constraint if
-- exists` and rebuild the WHOLE list, so any order of application lands the
-- same table — which is why `callout` is repeated here rather than assumed.
alter table public.push_nudges drop constraint if exists push_nudges_kind_check;
alter table public.push_nudges add constraint push_nudges_kind_check
  check (kind in (
    -- shipped
    'nudge', 'invite', 'request', 'rsvp', 'callout',
    -- D248 · the nine nudges. The emotion each one names is in the entry and
    -- in `PushKind.emotion` (Kit), which is where a test can hold it.
    'rank_change',        -- rivalry     · somebody passed me, and it names them
    'clash_pressure',     -- rivalry     · they posted, I have not
    'clash_verdict',      -- achievement · the week settled
    'index_live',         -- achievement · three rounds — the number is mine
    'tee_tomorrow',       -- anticipation· 7:10 tomorrow, and who is in
    'season_countdown',   -- anticipation· it starts Saturday / it runs back
    'friend_round',       -- belonging   · a buddy posted
    'seat_open',          -- belonging   · a plan of theirs has room
    -- (`callout` above is the ninth: rivalry — I have been called out.)
    -- D248 · the tenth, and it is NOT a nudge. A vote opening on money and on
    -- a season somebody paid into is a transactional notice under D71/L-38,
    -- exempt from L-20's emotion requirement BY NAME. No other kind may claim
    -- that exemption without its own entry.
    'season_cancel'
  ));

-- ---------------------------------------------------------------------------
-- 2 · the producers' grants — only a producer may write a nudge
-- ---------------------------------------------------------------------------
-- The table carries RLS with ZERO policies, so `authenticated` can already
-- reach nothing through it; but the TABLE GRANTS say insert/update/delete, and
-- a policy added later for some unrelated reason would open every one of them.
-- Ten new kinds is ten new sentences that could be written to somebody else's
-- lock screen, so the grant is narrowed to match the mechanic: every writer in
-- this database is SECURITY DEFINER (`invite_golfer`, `friend_request`,
-- `set_round_rsvp`, `call_out`), and a definer function is not subject to
-- either the grant or the policy. Nothing legitimate loses anything.
revoke insert, update, delete on public.push_nudges from authenticated;

-- ---------------------------------------------------------------------------
-- self-check (L-05 · read-only)
-- ---------------------------------------------------------------------------
do $chk$
declare
  v_def  text;
  v_kind text;
  v_new  text[] := array['rank_change','clash_pressure','clash_verdict','index_live',
                         'tee_tomorrow','season_countdown','friend_round','seat_open',
                         'season_cancel'];
  v_src  text;
  v_writers text[] := '{}';
begin
  select pg_get_constraintdef(oid) into v_def
    from pg_constraint
   where conname = 'push_nudges_kind_check'
     and conrelid = 'public.push_nudges'::regclass;
  if v_def is null then raise exception 'C-6: push_nudges_kind_check is missing'; end if;

  -- the five that shipped must survive — a rebuild that drops one silently
  -- retires a notification that is live in the field
  foreach v_kind in array array['nudge','invite','request','rsvp','callout'] loop
    if position('''' || v_kind || '''' in v_def) = 0 then
      raise exception 'C-6: the CHECK dropped the shipped kind %', v_kind;
    end if;
  end loop;

  -- and the ten must be there
  foreach v_kind in array v_new loop
    if position('''' || v_kind || '''' in v_def) = 0 then
      raise exception 'D248: the CHECK does not admit %', v_kind;
    end if;
  end loop;

  -- THE GATE. Nothing may WRITE one of the new kinds yet. This is the check
  -- that keeps "the kinds ship and the producers stay dark" a fact rather than
  -- an intention: the day somebody adds a producer, this migration is already
  -- applied and cannot complain — but on the push that introduces it, the
  -- author has to come here and say so.
  for v_src, v_kind in
    select p.proname, k
      from pg_proc p
      cross join unnest(v_new) k
     where p.pronamespace = 'public'::regnamespace
       and p.prosrc ilike '%push_nudges%'
       and p.prosrc ilike '%''' || k || '''%'
  loop
    v_writers := v_writers || (v_src || ':' || v_kind);
  end loop;
  if array_length(v_writers, 1) is not null then
    raise exception 'D248: a producer shipped before the APNs gate — %', array_to_string(v_writers, ', ');
  end if;

  -- the seal
  if has_table_privilege('authenticated', 'public.push_nudges', 'insert')
     or has_table_privilege('authenticated', 'public.push_nudges', 'update')
     or has_table_privilege('authenticated', 'public.push_nudges', 'delete') then
    raise exception 'C-6: a client can still write a nudge — only a definer producer may';
  end if;
end $chk$;
