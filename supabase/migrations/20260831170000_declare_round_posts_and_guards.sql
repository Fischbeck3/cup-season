-- D178 · the tee sheet's front door was the quiet one.
--
-- `declare_round` has TWO overloads. The 5-arg one validates the tags and posts
-- the round to every league you are in. The 6-arg one — the one that takes
-- `p_course_id`, added when the round object learned about courses — does
-- NEITHER. And both clients call the 6-arg one, always:
--
--   index.html:18638      always sends p_course_id (the skew fallback that
--                         once dropped it can no longer fire)
--   ScheduleService.swift always passes it
--
-- So for as long as that overload has existed:
--
--   1. NOTHING has been posted to the board when a round is declared, while the
--      sheet's fine print says "Posts to your leagues' boards: tagged golfers
--      are named" and the success toast says "your group is named on the
--      boards". D107 made the tee sheet the free front door; declaring a round
--      is the whole point of it, and it has been silent.
--
--   2. THE TAG GUARD WAS MISSING. The 5-arg body refuses a tag that is neither
--      a buddy nor a league mate ('You can tag buddies and league mates') and
--      caps the list at seven. The 6-arg body checks neither, so the live path
--      would accept an arbitrary profile id and put a stranger's name on a
--      board post. Nothing is exposed by it — `scheduled_rounds` is read
--      through RLS either way — but it is a consent rule that has not been
--      enforced on the only path anyone uses.
--
-- This re-emits the 6-arg overload with both restored, keeping everything it
-- already does (course_id, and D104's RSVP nudge). The 5-arg overload stays:
-- it costs nothing, and dropping a function two clients might still reach on a
-- skewed deploy is a worse trade than leaving it.

create or replace function public.declare_round(
  p_play_on date,
  p_course text,
  p_note text,
  p_tagged uuid[] default '{}'::uuid[],
  p_tee time without time zone default null::time without time zone,
  p_course_id text default null::text)
returns uuid
language plpgsql
security definer
set search_path to 'public'
as $function$
declare
  v_id     uuid;
  v_course text := nullif(trim(coalesce(p_course,'')), '');
  v_note   text := nullif(trim(coalesce(p_note,'')), '');
  v_tags   uuid[];
  v_bad    integer;
  v_name   text;
  v_with   text;
  v_who    text;
  v_body   text;
begin
  if auth.uid() is null then raise exception 'Sign in first'; end if;
  if p_play_on is null or p_play_on < current_date then
    raise exception 'Pick a day that has not happened yet';
  end if;
  if p_play_on > current_date + 365 then
    raise exception 'One year out is far enough';
  end if;
  if v_note is not null and length(v_note) > 140 then
    raise exception 'Notes cap at 140 characters';
  end if;

  select array_agg(distinct t.pid) into v_tags
    from unnest(coalesce(p_tagged, '{}')) t(pid)
   where t.pid <> auth.uid();
  v_tags := coalesce(v_tags, '{}');

  -- D178 · the cap and the consent rule, restored from the 5-arg body.
  if array_length(v_tags, 1) > 7 then
    raise exception 'Tag up to seven — it is golf, not a scramble league';
  end if;
  select count(*) into v_bad
    from unnest(v_tags) t(pid)
   where not (
     exists (select 1 from friendships f
              where f.status = 'accepted'
                and ((f.requester = auth.uid() and f.addressee = t.pid)
                  or (f.addressee = auth.uid() and f.requester = t.pid)))
     or exists (select 1 from league_members a
                   join league_members b on b.league_id = a.league_id
                 where a.profile_id = auth.uid() and b.profile_id = t.pid)
   );
  if v_bad > 0 then raise exception 'You can tag buddies and league mates'; end if;

  insert into scheduled_rounds (profile_id, play_on, course_label, note, tagged, tee_time, course_id)
  values (auth.uid(), p_play_on, v_course, v_note, v_tags, p_tee,
          nullif(trim(coalesce(p_course_id,'')), ''))
  returning id into v_id;

  -- D178 · the board post, restored. Same sentence the 5-arg overload writes,
  -- in D165's natural case — the shouting generation is over.
  select coalesce(display_name, 'A golfer') into v_name
    from profiles where id = auth.uid();
  select string_agg(coalesce(display_name, 'a golfer'), ' & ') into v_with
    from profiles where id = any(v_tags);

  insert into posts (league_id, kind, member_id, body)
  select lm.league_id, 'system', lm.id,
         v_name || ' put a round on the books — '
         || to_char(p_play_on, 'Dy Mon DD')
         || coalesce(' · ' || to_char(p_tee, 'FMHH12:MIAM'), '')
         || coalesce(' · ' || v_course, '')
         || coalesce(' · with ' || v_with, '')
         || coalesce(' · "' || v_note || '"', '')
    from league_members lm
   where lm.profile_id = auth.uid();

  -- D104 · ask the tagged. In / Out answer from the lock screen (CS_RSVP →
  -- set_round_rsvp); scheduled_round_id lands the round sheet.
  if array_length(v_tags, 1) > 0 then
    v_who  := coalesce(nullif(split_part(trim(playerlabel(auth.uid())), ' ', 1), ''), 'Someone');
    v_body := trim(to_char(p_play_on, 'Dy Mon FMDD'))
              || coalesce(' · ' || v_course, '') || ' — in or out?';
    insert into push_nudges (profile_id, kind, title, body, payload)
    select t.pid, 'rsvp', v_who || ' put you on the tee sheet', v_body,
           jsonb_build_object('scheduled_round_id', v_id, 'profile_id', auth.uid())
      from unnest(v_tags) t(pid);
  end if;

  return v_id;
end $function$;

revoke execute on function public.declare_round(date, text, text, uuid[], time without time zone, text) from public, anon;
grant execute on function public.declare_round(date, text, text, uuid[], time without time zone, text) to authenticated;

-- ---- self-enforcing ---------------------------------------------------------
do $chk$
declare v_n int;
begin
  -- BOTH overloads must post to the board and guard the tags. This check is the
  -- point of the migration: the drift it repairs was invisible for weeks
  -- precisely because one overload was right and nobody read the other.
  select count(*) into v_n from pg_proc
   where proname = 'declare_round'
     and pg_get_functiondef(oid) like '%insert into posts%';
  if v_n <> 2 then
    raise exception 'D178: % of 2 declare_round overloads post to the board', v_n;
  end if;

  select count(*) into v_n from pg_proc
   where proname = 'declare_round'
     and pg_get_functiondef(oid) like '%You can tag buddies and league mates%';
  if v_n <> 2 then
    raise exception 'D178: % of 2 declare_round overloads guard their tags', v_n;
  end if;

  -- and the one the clients actually call stays reachable
  if not has_function_privilege('authenticated',
        'public.declare_round(date, text, text, uuid[], time without time zone, text)', 'execute') then
    raise exception 'D37: declare_round(6-arg) is not executable by authenticated';
  end if;
end $chk$;
