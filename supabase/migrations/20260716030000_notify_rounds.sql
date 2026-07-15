-- ============================================================================
-- Cup Season — events engine, checkpoint 6: CURATED PUSH (the round switch)
--
-- The push fan-out was all-or-nothing per league: every board post buzzed
-- everyone (chat already had its own mute via notify_chat). With moments now
-- firing, "meaningful only, no spam" (vision doc) means letting the noise-averse
-- keep the big stuff — announcements, moments (barrier / lead change), invites —
-- while muting the steady drip of "X posted 84 gross" round pings.
--
-- profiles.notify_rounds (default ON, per the personas doc: a friend posting IS
-- meaningful). The push function reads it in the default branch: kind='round'
-- respects notify_rounds, kind='chat' respects notify_chat, everything else
-- (moment / announce / system) always delivers. Mirrors set_notify_chat.
-- ============================================================================

alter table public.profiles
  add column if not exists notify_rounds boolean not null default true;

create or replace function public.set_notify_rounds(p_on boolean) returns void
language sql security definer set search_path = public
as $$ update profiles set notify_rounds = p_on where id = auth.uid(); $$;

grant execute on function public.set_notify_rounds(boolean) to authenticated;
