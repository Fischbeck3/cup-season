-- D167 · the column grant D125a forgot.
--
-- `live_round_players` does not carry a table-level SELECT for `authenticated`;
-- it carries an explicit COLUMN LIST (D37's seal), and `claim_token` is left off
-- it deliberately — the guest's pencil token is a secret, sealed the same way
-- `profiles.email` is.
--
-- Adding `joined_at` in 20260831110000 (D125a) put a column on that table with
-- NO grant. It is not yet selected by either client, so nothing is broken
-- today — which is exactly the shape of the landmine CLAUDE.md already records
-- against `profiles`:
--
--   "The seal also FROZE the column-grant list: a migration adding a column
--    MUST grant select (<col>) … or every select naming it fails 42501
--    'permission denied for table …' — a message that never names the column"
--
-- The next surface that wants to show "their phone was in the session" would
-- have hit a 42501 that names the table and not the column, on boot, with no
-- clue pointing here. Grant it now, while the cause is still obvious.
--
-- `joined_at` is not a secret: it is the fact D125 exists to make visible.

grant select (joined_at) on public.live_round_players to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_missing text;
begin
  -- every column except the deliberately-sealed claim_token must be readable
  select string_agg(a.attname, ', ')
    into v_missing
    from pg_attribute a
   where a.attrelid = 'public.live_round_players'::regclass
     and a.attnum > 0 and not a.attisdropped
     and a.attname <> 'claim_token'
     and not has_column_privilege('authenticated', a.attrelid, a.attname, 'select');
  if v_missing is not null then
    raise exception 'D167: live_round_players column(s) unreadable by authenticated: %', v_missing;
  end if;

  -- and the seal itself must hold: claim_token stays unreadable
  if has_column_privilege('authenticated', 'public.live_round_players'::regclass, 'claim_token', 'select') then
    raise exception 'D167: claim_token became readable — the guest pencil token is a secret';
  end if;

  -- the table-level grant must NOT come back, or the column list is moot
  if has_table_privilege('authenticated', 'public.live_round_players', 'select') then
    raise exception 'D37: live_round_players regained a table-level SELECT, which defeats the column seal';
  end if;
end $chk$;
