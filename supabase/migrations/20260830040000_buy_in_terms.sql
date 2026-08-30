-- D129 · The pot gets a payment path
--
-- Why (blind UX audit, 2026-08-29, TOP-5). The Pot tab showed "$150 · $0
-- collected · 2 still owe" six weeks into a real season, and not one tester
-- could say who to pay, how, or by when — including the member who had been in
-- the league the whole time. Every persona asked the same three questions and
-- the screen answered none of them. Meanwhile the member rows LOOKED tappable
-- and silently refused anyone but the Pro.
--
-- What this is NOT: a payment rail. D39 is unchanged and unchallenged — Cup
-- Season never holds, moves or touches money. This stores the Pro's own
-- instructions ("Venmo @casey") and a due date, exactly as a shared
-- spreadsheet would, so the group can settle among themselves. Guideline
-- 5.3.4's answer is the same after this migration as before it.
--
-- Fail-closed (D136 · §6 Q-27): the note is for MEMBERS. `join_covenant_info`
-- learns only whether a note exists and when payment is due — never the note
-- itself — because a league code escapes the group chat and a payment handle
-- should not travel with it.

alter table public.league_settings
  add column if not exists buy_in_note   text,
  add column if not exists buy_in_due_on date;

comment on column public.league_settings.buy_in_note is
  'The Pro''s own words on how to pay them (D129). Instructions, never a rail — the app moves no money (D39).';
comment on column public.league_settings.buy_in_due_on is
  'When the Pro wants buy-ins in by. Advisory: nothing enforces it and no penalty reads it.';

-- The Pro sets the terms. Security definer because league_settings is not
-- client-writable (D37: identity is checked at the database, not by hiding a
-- button — the audit found four member rows that looked tappable and were not).
create or replace function public.set_buy_in_terms(
  p_league uuid,
  p_note   text default null,
  p_due_on date default null
) returns json
language plpgsql
security definer
set search_path to 'public'
as $function$
declare v league_settings;
begin
  if not is_commissioner(p_league) then
    raise exception 'Only the Pro can set how the pot is paid.';
  end if;
  -- a note is instructions, not an essay; trim to something a card can hold
  if p_note is not null and length(btrim(p_note)) > 140 then
    raise exception 'Keep the payment note under 140 characters.';
  end if;

  update league_settings
     set buy_in_note   = nullif(btrim(coalesce(p_note, '')), ''),
         buy_in_due_on = p_due_on
   where league_id = p_league
  returning * into v;

  if not found then raise exception 'That league no longer exists.'; end if;

  return json_build_object('note', v.buy_in_note, 'due_on', v.buy_in_due_on);
end $function$;

revoke all on function public.set_buy_in_terms(uuid, text, date) from public, anon;
grant execute on function public.set_buy_in_terms(uuid, text, date) to authenticated;

-- The covenant learns THAT the Pro has posted terms, never what they say.
-- (join_covenant_info is the one anon window in the whole schema — CLAUDE.md.)
create or replace function public.join_covenant_info(p_code text)
returns jsonb                      -- jsonb, as it already is: a return-type
                                   -- change cannot ride on CREATE OR REPLACE
language sql
security definer
stable
set search_path to 'public'
as $function$
  select jsonb_build_object(
    'name',        l.name,
    'buyin_cents', coalesce(ls.buyin_cents, 0),
    'preset',      ls.preset,
    'floor',       ls.participation_floor,
    'finish',      coalesce(ls.finish, 'cup_final'),
    'structure',   ls.structure,
    -- D129, fail-closed: a boolean and a date, never the note itself
    'has_pay_note', (ls.buy_in_note is not null),
    'buy_in_due_on', ls.buy_in_due_on)
  from leagues l
  join league_settings ls on ls.league_id = l.id
  where upper(l.code) = upper(p_code)
  limit 1;
$function$;

revoke all on function public.join_covenant_info(text) from public;
grant execute on function public.join_covenant_info(text) to anon, authenticated;
