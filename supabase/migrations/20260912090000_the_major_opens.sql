-- ============================================================================
-- D252 / R-E — THE MAJOR'S DOOR OPENS
--
-- `app_flags.ios.major` is the phone's one curtain over the Major: the door in
-- the event picker (`EventPickerSheet.swift`) and the four Home occasion cards
-- that sell a jug (`HomeStream.swift` — opener, test, oldest, fall) all read it
-- fail-closed, so until this file runs the code ships and the door stays shut.
-- Wave 0 darkened the four cards under D252's sequencing clause; wave 3 makes
-- the Major's surfaces good enough to receive the traffic and this file opens
-- the door. The two halves belong to one entry precisely so a door is never
-- sold before it opens (L-32, L-44).
--
-- WHAT THIS FILE IS, AND WHAT IT IS NOT
--   It is one idempotent write of one boolean into one existing jsonb row.
--   It creates no object, grants nothing new and changes no function, so it
--   carries no grants of its own: `app_flags` is read by `authenticated`
--   through the `flags_read` policy (20260718045514) and has no write policy
--   at all — writes are migration-only, which is the point of the table.
--
-- THE MERGE ORDER IS DELIBERATE, AND IT IS THE OPPOSITE OF 20260827130100's.
--   The iOS flag row's own migration lets the EXISTING value win
--   (`excluded || existing`) so a hand-raised `min_build` is never lowered by a
--   re-run. This file must do the reverse for exactly one key: `major` is the
--   thing being changed, so it is written last and wins, while every other key
--   in the row — `min_build`, `note`, `apple_sign_in`, anything the owner has
--   set from the SQL editor since — is preserved untouched. Hence
--   `value || '{"major": true}'` rather than a replacement object.
--
-- RE-RUNNABLE. Running it twice sets the same true twice. If the row is
-- somehow absent the insert creates it with the flag on and nothing else, and
-- 20260827130100's own upsert will still add `min_build` and `note` if it runs
-- after (its merge lets the existing value win, which is why that direction is
-- safe here).
-- ============================================================================

insert into public.app_flags (key, value)
values ('ios', '{"major": true}'::jsonb)
on conflict (key) do update
  set value      = public.app_flags.value || '{"major": true}'::jsonb,
      updated_at = now();

-- ---------------------------------------------------------------------------
-- Self-check (L-05: it reads, it does not mutate). Fails the migration loudly
-- rather than leaving a shut door that everyone believes is open.
-- ---------------------------------------------------------------------------
do $$
declare v jsonb;
begin
  select value into v from public.app_flags where key = 'ios';
  if v is null then
    raise exception 'the_major_opens: no app_flags row keyed ios after the upsert';
  end if;
  if coalesce((v->>'major')::boolean, false) is not true then
    raise exception 'the_major_opens: app_flags.ios.major is not true (value = %)', v;
  end if;
  -- the neighbours survived the merge: min_build is the build gate and losing
  -- it would un-retire every build below it.
  if not (v ? 'min_build') then
    raise exception 'the_major_opens: the merge dropped min_build (value = %)', v;
  end if;
end $$;
