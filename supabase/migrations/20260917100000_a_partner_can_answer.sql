-- ============================================================================
-- Cup Season — a partner can answer, and a golfer can ask for a seat
-- (R15 `confirm_round_partner`, R16 `ask_for_a_seat`)
--
-- Wave 5 of the UX overhaul (docs/ux-overhaul-2026-09-04/, owner-authorised
-- 2026-09-05). D239 (who was out there), IOS-032.
--
-- ---------------------------------------------------------------------------
-- R15 · confirm_round_partner(p_round uuid, p_confirm boolean default true)
--
-- `round_players` shipped in wave 2 with a state and nothing that could change
-- it. Until this exists, every tag reads "hasn't confirmed yet" forever, which
-- is true but permanent — and a claim about another person that they can never
-- answer is not a claim with a state, it is an assertion with a disclaimer.
--
-- The rules, and each is enforced here rather than by hiding a control:
--   * ONLY the tagged golfer may answer. Not the tagger, not the Pro, not the
--     founder — it is a statement about where THIS golfer was.
--   * `p_confirm = false` REMOVES the row. It does not write a "denied" state:
--     a golfer saying "I wasn't there" should leave no trace of somebody's
--     claim that they were, and a rejected tag that lingers in a table is a
--     rejected tag somebody can still count.
--   * NO round is touched (L-02). `rounds` is immutable and stays immutable;
--     `rounds_owner_update` stays dead.
--   * A TAG IS NEVER A VOUCH (L-19). Confirming says "I was out there"; it
--     attests nothing about the score, and no surface may say it does.
--   * It is idempotent: confirming twice is confirming once, and un-confirming
--     a row that is already gone is not an error.
--
-- ---------------------------------------------------------------------------
-- my_open_tags() — the read that makes R15 REACHABLE
--
-- Not in the plan's list, and here because `confirm_round_partner` without it
-- is a verb with no surface: `round_players` rows are readable by the tagged
-- golfer, but the ROUND they hang off belongs to somebody else, so a client
-- cannot join through to the day and the course without either an embed that
-- RLS may refuse or one `round_card` call per tag. One SECURITY DEFINER read
-- answers it in one round trip and leans on no policy at all.
--
-- It returns ONLY tags about ME that I have not answered — never a list of
-- other people's tags, never a browsable index (L-37). The tagger's name is
-- included because "somebody says you played Papago" is not a question a
-- golfer can answer.
--
-- ---------------------------------------------------------------------------
-- R16 · ask_for_a_seat(p_scheduled_round uuid)
--
-- D69 is untouched. A tee sheet is the host's, and RSVP is for the host and
-- the golfers they tagged (`set_round_rsvp` enforces that, and it keeps
-- enforcing it). Today a golfer who sees a buddy's plan and wants in has
-- NOWHERE TO GO — the row renders, the controls are absent, and that is the
-- dead end IA §10.1 names.
--
-- So this writes ONE `push_nudges` row of kind `rsvp` to the HOST. It is a
-- REQUEST, never a write to the tee sheet:
--   * no `scheduled_rounds` row is created, updated or tagged
--   * no `round_rsvp` row is written
--   * the host decides, from their own surface, with the control they already
--     have ("Edit group")
--
-- ONCE PER PERSON PER PLAN (L-20/L-21: a nudge that can be sent twice is a
-- nudge that will be). The second call returns the same answer and writes
-- nothing. It refuses a plan in the past, the host's own plan, and a plan
-- whose host this caller cannot see (the same circle `home_feed` uses — a
-- stranger cannot ping a stranger).
--
-- `push_nudges.kind` already admits `rsvp` (`push_nudges_kind_check`), so no
-- CHECK is widened here and the push function's existing curation applies.
--
-- Both are additive, both default what can be defaulted, and a client that
-- cannot find them renders the tag as unconfirmed and the plan without the
-- ask — which is exactly what both do today.
-- ============================================================================

-- ---------------------------------------------------------------------------
-- R15 · confirm_round_partner
-- ---------------------------------------------------------------------------
create or replace function public.confirm_round_partner(
  p_round uuid,
  p_confirm boolean default true)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  v uuid := auth.uid();
  v_found boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_round is null then raise exception 'Which round?'; end if;

  select true into v_found from round_players
   where round_id = p_round and profile_id = v;

  if not coalesce(v_found, false) then
    -- not an error worth a red screen: the tag may already have been answered
    -- and cleared. The honest answer is the state, not an exception.
    return jsonb_build_object('state', 'none');
  end if;

  if coalesce(p_confirm, true) then
    update round_players set confirmed_at = coalesce(confirmed_at, now())
     where round_id = p_round and profile_id = v;
    return jsonb_build_object('state', 'confirmed');
  else
    -- "I wasn't there" leaves no trace of the claim that they were
    delete from round_players where round_id = p_round and profile_id = v;
    return jsonb_build_object('state', 'removed');
  end if;
end $fn$;

comment on function public.confirm_round_partner(uuid, boolean) is
  'R15 (D239) · the tagged golfer answers. Only they may; declining REMOVES the row rather than writing a denial; no round is ever touched (L-02); confirming is not attesting (L-19).';

revoke all on function public.confirm_round_partner(uuid, boolean) from public, anon;
grant execute on function public.confirm_round_partner(uuid, boolean) to authenticated;

-- ---------------------------------------------------------------------------
-- my_open_tags — the tagged golfer's own question, and nobody else's
-- ---------------------------------------------------------------------------
create or replace function public.my_open_tags(p_limit integer default 10)
returns table(
  round_id uuid,
  played_on date,
  course_label text,
  gross integer,
  by_name text,
  by_profile uuid,
  tagged_at timestamptz)
language sql
stable
security definer
set search_path to 'public'
as $fn$
  select r.id, r.played_on, nullif(r.course_label, ''), r.gross,
         coalesce(p.display_name, 'A golfer'), r.profile_id, rp.created_at
    from round_players rp
    join rounds r on r.id = rp.round_id and not r.voided
    left join profiles p on p.id = r.profile_id
   where auth.uid() is not null
     and rp.profile_id = auth.uid()
     and rp.confirmed_at is null
     and r.profile_id <> auth.uid()
   order by rp.created_at desc
   limit greatest(coalesce(p_limit, 10), 1);
$fn$;

comment on function public.my_open_tags(integer) is
  'The rounds somebody has said I was out for and I have not answered. Only my own tags, never a browsable index (L-37). It exists so confirm_round_partner has a surface.';

revoke all on function public.my_open_tags(integer) from public, anon;
grant execute on function public.my_open_tags(integer) to authenticated;

-- ---------------------------------------------------------------------------
-- R16 · ask_for_a_seat
-- ---------------------------------------------------------------------------
create or replace function public.ask_for_a_seat(p_scheduled_round uuid)
returns jsonb
language plpgsql
security definer
set search_path to 'public'
as $fn$
declare
  v uuid := auth.uid();
  v_row scheduled_rounds%rowtype;
  v_me text;
  v_can boolean;
begin
  if v is null then raise exception 'Sign in first'; end if;
  if p_scheduled_round is null then raise exception 'Which round?'; end if;

  select * into v_row from scheduled_rounds where id = p_scheduled_round;
  if not found then raise exception 'That round is not on the tee sheet any more'; end if;
  if v_row.profile_id = v then raise exception 'That is your own round'; end if;
  if v_row.play_on < current_date then raise exception 'That round has already been played'; end if;
  if v = any(coalesce(v_row.tagged, '{}'::uuid[])) then
    -- they are already in the group; the RSVP control is the honest door
    return jsonb_build_object('state', 'already_in');
  end if;

  -- the circle: a buddy, a league mate, or somebody in the same event. A
  -- stranger cannot ping a stranger (L-37, and the same bound `home_feed` uses
  -- to decide whose plans reach whom).
  select exists (
    select 1 from friendships f
     where f.status = 'accepted'
       and ((f.requester = v and f.addressee = v_row.profile_id)
         or (f.addressee = v and f.requester = v_row.profile_id)))
    or exists (
    select 1 from league_members a join league_members b on b.league_id = a.league_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    or exists (
    select 1 from event_players a join event_players b on b.event_id = a.event_id
     where a.profile_id = v and b.profile_id = v_row.profile_id)
    into v_can;
  if not v_can then raise exception 'You can only ask somebody you play with'; end if;

  -- ONCE per person per plan (L-20/L-21)
  if exists (select 1 from push_nudges n
              where n.profile_id = v_row.profile_id
                and n.kind = 'rsvp'
                and n.payload->>'scheduled_round_id' = p_scheduled_round::text
                and n.payload->>'from' = v::text) then
    return jsonb_build_object('state', 'already_asked');
  end if;

  select coalesce(display_name, 'A golfer') into v_me from profiles where id = v;

  insert into push_nudges (profile_id, title, body, kind, payload)
  values (v_row.profile_id,
          v_me || ' wants in',
          v_me || ' is asking for a seat on your ' ||
            to_char(v_row.play_on, 'Dy Mon FMDD') || ' round' ||
            coalesce(' at ' || nullif(v_row.course_label, ''), '') || '.',
          'rsvp',
          jsonb_build_object('scheduled_round_id', p_scheduled_round,
                             'from', v,
                             'play_on', v_row.play_on));

  return jsonb_build_object('state', 'asked');
end $fn$;

comment on function public.ask_for_a_seat(uuid) is
  'R16 (IOS-032) · one push_nudges row of kind rsvp to the HOST, once per person per plan. A REQUEST, never a write to the tee sheet: no scheduled_rounds row and no round_rsvp row is touched, so D69''s consent rule is intact.';

revoke all on function public.ask_for_a_seat(uuid) from public, anon;
grant execute on function public.ask_for_a_seat(uuid) to authenticated;

-- ---------------------------------------------------------------------------
-- self-check — catalogue only, and one rolled-back proof; no real row is
-- left behind (L-05, D215)
-- ---------------------------------------------------------------------------
do $check$
declare
  v_def text;
begin
  if has_function_privilege('anon', 'public.confirm_round_partner(uuid, boolean)', 'EXECUTE')
     or has_function_privilege('anon', 'public.ask_for_a_seat(uuid)', 'EXECUTE')
     or has_function_privilege('anon', 'public.my_open_tags(integer)', 'EXECUTE') then
    raise exception 'wave 5: anon can execute a write (the anon surface stays at twelve)';
  end if;
  if not has_function_privilege('authenticated', 'public.confirm_round_partner(uuid, boolean)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.ask_for_a_seat(uuid)', 'EXECUTE')
     or not has_function_privilege('authenticated', 'public.my_open_tags(integer)', 'EXECUTE') then
    raise exception 'wave 5: authenticated cannot execute one of these (silent 403 on the phone)';
  end if;

  -- a signed-out caller sees nobody's tags
  perform * from my_open_tags(1);

  -- D69, mechanically: this function may not touch the tee sheet. A future
  -- edit that turns the request into a write fails the push here rather than
  -- in a review.
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'ask_for_a_seat';
  if v_def ~* '(insert|update|delete)\s+(into\s+)?(public\.)?(scheduled_rounds|round_rsvp)' then
    raise exception 'ask_for_a_seat writes to the tee sheet — it is a request, never a write (D69)';
  end if;

  -- L-02, mechanically: the partner''s answer may not touch a round
  select pg_get_functiondef(p.oid) into v_def
    from pg_proc p join pg_namespace ns on ns.oid = p.pronamespace
   where ns.nspname = 'public' and p.proname = 'confirm_round_partner';
  if v_def ~* '(update|delete)\s+(from\s+)?(public\.)?rounds\M' then
    raise exception 'confirm_round_partner mutates a round (L-02)';
  end if;

  -- both refuse a signed-out caller, which is the state a self-check runs in
  begin
    perform confirm_round_partner(null, true);
    raise exception 'confirm_round_partner: a signed-out caller was not refused';
  exception when others then
    if sqlerrm <> 'Sign in first' then raise; end if;
  end;
  begin
    perform ask_for_a_seat(null);
    raise exception 'ask_for_a_seat: a signed-out caller was not refused';
  exception when others then
    if sqlerrm <> 'Sign in first' then raise; end if;
  end;
end $check$;
