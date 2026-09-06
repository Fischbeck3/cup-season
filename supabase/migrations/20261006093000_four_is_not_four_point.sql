-- Cup Season — a whole number is not a number with a point after it.
--
-- Home has been saying **"You are 4. back of Galen with 8 weeks left."**
--
-- `to_char(4.0, 'FM999990.9')` returns `'4.'`. FM suppresses the trailing
-- ZERO after the decimal point and leaves the POINT, so every gap that lands
-- on a whole number — which is most of them, because strokes usually do —
-- renders with a full stop wedged into the middle of the sentence. Verified
-- against production before this was written:
--
--   to_char(4.0,'FM999990.9') -> '4.'      to_char(12,'FM999990.9') -> '12.'
--   to_char(4.5,'FM999990.9') -> '4.5'     (the fractional case was always fine)
--
-- `rtrim(..., '.')` removes a trailing point and nothing else: '4.' -> '4',
-- '4.5' -> '4.5'. It cannot touch a number that has a fraction, because such
-- a number never ends in a point.
--
-- Four call sites, all inside `home_dispatch`: the participation floor's
-- "you need N more", the CHANGED item's "N back of", its "N clear of", and
-- the standfirst's "worth up to N". This replaces the function with the same
-- signature and the same body, those four expressions excepted — so there is
-- no new overload for PostgREST to resolve (`home_dispatch` has exactly one,
-- checked before writing this) and no client change is required.

create or replace function public.home_dispatch(p_days integer default 21)
returns jsonb
language plpgsql stable security definer set search_path = public as $$
declare
  v          uuid := auth.uid();
  v_me       jsonb;
  v_today    date := current_date;
  v_items    jsonb := '[]'::jsonb;
  v_out      jsonb := '[]'::jsonb;
  v_days     int  := greatest(1, coalesce(p_days, 21));
  m          jsonb;       -- one membership
  st         jsonb;       -- its standing
  se         jsonb;       -- its season
  cl         jsonb;       -- its clash
  pu         jsonb;       -- its pulse
  bi         jsonb;       -- its buy_in
  e          jsonb;       -- a generic element
  v_nearest  uuid;        -- the league with the nearest dated thing (M11)
  v_best     date;
  v_lead_ix  int;
  v_rank     int := 0;
  v_sup      jsonb := '[]'::jsonb;
  v_friends  int := 0;
  v_rounds   int := 0;
  v_when_s   text;
begin
  if v is null then
    return jsonb_build_object('me', null, 'items', '[]'::jsonb, 'generated_at', now());
  end if;

  begin
    v_me := native_home();
  exception when others then
    v_me := null;
  end;
  if v_me is null then
    return jsonb_build_object('me', null, 'items', '[]'::jsonb, 'generated_at', now());
  end if;

  v_rounds  := coalesce((v_me #>> '{profile,rounds_count}')::int, 0);
  begin
    select count(*)::int into v_friends from friendships f
     where f.status = 'accepted' and (f.requester = v or f.addressee = v);
  exception when others then
    v_friends := 0;
  end;

  -- M11 · which season carries the nearest dated thing (its week's close,
  -- else its end). One pass, before any item is built.
  for m in select * from jsonb_array_elements(coalesce(v_me->'memberships', '[]'::jsonb)) loop
    se := m->'season';
    if se is not null and se <> 'null'::jsonb then
      v_when_s := coalesce(nullif(se->>'week_ends_on', ''), nullif(se->>'ends_on', ''));
      if v_when_s is not null then
        begin
          if v_best is null or v_when_s::date < v_best then
            v_best := v_when_s::date;
            v_nearest := (m->>'league_id')::uuid;
          end if;
        exception when others then null;
        end;
      end if;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 1 · CLOSING — a clock I can still change
  -- =========================================================================

  -- my live round: the highest score the function can produce, and the one
  -- state where the lead is a place I am already standing in (S11).
  if (v_me->'live_round') is not null and (v_me->'live_round') <> 'null'::jsonb then
    e := v_me->'live_round';
    -- R-04 · TWO FACES. `native_home.live_round` is "a live round the caller
    -- is SEATED in", which includes a round somebody else started and I have
    -- never opened — where "You are on the card right now" and "the card is
    -- open" are both false, the host is unnamed and the verb JOIN is missing.
    -- LV-09 · and the noun: §2.1 splits "your card" (the person) from "your
    -- scorecard" (the holes). This is the holes.
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'live:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          70, 'mod_reason', 'M1 30 (live) + M2 40 (me)',
      'subject',       case when (e->>'mine')::boolean is not false then 'you'
                            else coalesce(firstname(e->>'host'), 'a golfer') end,
      'human_subject', true,
      'eyebrow',       case when (e->>'mine')::boolean is not false
                            then upper(coalesce(nullif(e->>'course_label', ''), 'A round is live'))
                            else 'JUST TEED OFF · NOTHING SCORED YET' end,
      'headline',      case when (e->>'mine')::boolean is not false
                            then 'You’re in a live round right now.'
                            else coalesce(firstname(e->>'host'), 'Somebody')
                                   || ' started a live round with you.' end,
      'standfirst',    case when (e->>'mine')::boolean is not false
                            then case when nullif(e->>'league_name', '') is not null
                                      then e->>'league_name' || ' — the scorecard is open.' end
                            else coalesce(nullif(e->>'course_label', ''), nullif(e->>'league_name', '')) end,
      'action',        case when (e->>'mine')::boolean is not false then 'Back to the round' else 'Join' end,
      'route',         jsonb_build_object('kind', 'live', 'id', e->>'id'),
      'league_id',     e->>'league_id',
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'started_at'));
  end if;

  -- an invitation waiting: band 1 with a buddy's weight. The verb is "See the
  -- terms", never "Join" — every join passes the covenant (L-12, D136).
  for e in select * from jsonb_array_elements(coalesce(v_me->'invites', '[]'::jsonb)) loop
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'invite:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          12, 'mod_reason', 'M6 12 (a buddy asked)',
      'subject',       coalesce(firstname(e->>'inviter'), 'A golfer'),
      'human_subject', nullif(e->>'inviter', '') is not null,
      'eyebrow',       'AN INVITATION',
      'headline',      coalesce(firstname(e->>'inviter'), 'A golfer') || ' put you on '
                         || coalesce(nullif(e->>'container_name', ''), 'a season') || '.',
      'standfirst',    'See the terms before you are in.',
      'action',        'See the terms',
      'route',         jsonb_build_object('kind', 'invite', 'id', e->>'container_id',
                                          'pane', e->>'kind'),
      'league_id',     case when e->>'kind' = 'league' then e->>'container_id' end,
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'created_at'));
  end loop;

  -- a buddy request waiting: answered in place, so its door is the Golfers list
  for e in
    select jsonb_build_object('id', f.requester, 'name', firstname(p.display_name),
                              'at', f.created_at)
      from friendships f join profiles p on p.id = f.requester
     where f.addressee = v and f.status = 'pending'
     order by f.created_at desc limit 3
  loop
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key',           'friend:' || coalesce(e->>'id', ''),
      'tier',          'closing', 'band', 1000,
      'mods',          8, 'mod_reason', 'M8 8 (recent)',
      'subject',       coalesce(e->>'name', 'A golfer'), 'human_subject', true,
      'eyebrow',       'A BUDDY REQUEST',
      'headline',      coalesce(e->>'name', 'A golfer') || ' wants to be golf buddies.',
      'standfirst',    null,
      'action',        'Answer it',
      'route',         jsonb_build_object('kind', 'people', 'id', e->>'id'),
      'league_id',     null,
      'suppress',      '[]'::jsonb,
      'spine',         'ember',
      'at',            e->>'at'));
  end loop;

  -- =========================================================================
  -- per membership: the clash, the floor, the movement, the chapter
  -- =========================================================================
  for m in select * from jsonb_array_elements(coalesce(v_me->'memberships', '[]'::jsonb)) loop
    se := nullif(m->'season', 'null'::jsonb);
    st := nullif(m->'standing', 'null'::jsonb);
    cl := nullif(m->'clash', 'null'::jsonb);
    pu := nullif(m->'pulse', 'null'::jsonb);
    bi := nullif(m->'buy_in', 'null'::jsonb);

    -- ---- the weekly clash -------------------------------------------------
    if cl is not null then
      declare
        v_them  text := coalesce(firstname(cl->>'them_name'), 'your opponent');
        v_mine  jsonb := nullif(cl->'mine', 'null'::jsonb);
        v_their jsonb := nullif(cl->'theirs', 'null'::jsonb);
        v_left  int  := coalesce((cl->>'days_left')::int, 0);
        v_close boolean := coalesce((cl->>'closes_today')::boolean, false);
        v_idle  boolean;
        v_when  text;
        v_head  text;
        v_stand text;
        v_act   text;
        v_route jsonb;
        v_band  int;
        v_mods  int;
        v_why   text;
        v_up    text := nullif(m #>> '{standing,next_up,name}', '');
        v_dn    text := nullif(m #>> '{standing,next_down,name}', '');
      begin
        v_idle  := (v_mine is null and v_their is null);
        v_when  := case when v_close then 'today'
                        when v_left = 1 then 'tomorrow'
                        else 'in ' || v_left || ' days' end;
        -- G4 · D216's yield, verbatim: nobody has played, so there is no
        -- stake yet and the clash drops to band 3. It re-enters the moment
        -- either side posts, or on the last-call day.
        if v_idle and v_left > 1 and not v_close then
          v_band := 600;
          v_head := 'Your clash with ' || v_them || ' is open.';
          v_stand := 'Best round of the week takes it.';
          v_act  := 'Add my round';
          v_route := jsonb_build_object('kind', 'composer');
        elsif v_their is not null and v_mine is null then
          v_band := 1000;
          v_head := v_them || ' posted ' || coalesce((v_their->>'gross'), 'a round')
                      || case when nullif(v_their->>'played_on', '') is not null
                              then ' on ' || to_char((v_their->>'played_on')::date, 'Dy') else '' end || '.';
          v_stand := 'That is the number, and the week closes ' || v_when || '.';
          v_act  := 'Add my round';
          v_route := jsonb_build_object('kind', 'composer');
        elsif v_mine is not null and v_their is null then
          -- SA-2 · "I have posted, they have not" — the state the owner's own
          -- account is in most weeks, and the one the shipped lead had no
          -- sentence for. The subject is the OPPONENT, and the pressure is
          -- named where it actually sits.
          v_band := 1000;
          v_head := v_them || ' has ' || (case when v_close then 'today' when v_left = 1 then 'one day'
                                               else v_left || ' days' end)
                      || ' to answer your ' || coalesce((v_mine->>'gross'), 'round') || '.';
          v_stand := 'Your round is the number to beat.';
          v_act  := 'See the receipt';
          v_route := case when nullif(v_mine->>'round_id', '') is not null
                          then jsonb_build_object('kind', 'receipt', 'id', v_mine->>'round_id')
                          else jsonb_build_object('kind', 'season', 'id', m->>'league_id') end;
        else
          v_band := 1000;
          v_head := 'You and ' || v_them || ' are both in.';
          v_stand := 'The week closes ' || v_when || '. Best round takes it.';
          v_act  := 'See the receipt';
          v_route := case when nullif(v_mine->>'round_id', '') is not null
                          then jsonb_build_object('kind', 'receipt', 'id', v_mine->>'round_id')
                          else jsonb_build_object('kind', 'season', 'id', m->>'league_id') end;
        end if;
        -- M1 the clock (band 1 only), M4 an opponent, M3 the man I am chasing
        v_mods := case when v_band = 1000 then greatest(0, 30 - (v_left * 10)) else 0 end + 24;
        v_why  := case when v_band = 1000 then 'M1 ' || greatest(0, 30 - (v_left * 10)) || ' (the clock) + ' else '' end
                    || 'M4 24 (an opponent)';
        if v_up is not null and firstname(cl->>'them_name') = v_up then
          v_mods := v_mods + 30; v_why := v_why || ' + M3 30 (he is the man above me)';
        elsif v_dn is not null and firstname(cl->>'them_name') = v_dn then
          v_mods := v_mods + 30; v_why := v_why || ' + M3 30 (she is the row below me)';
        end if;
        if (m->>'league_id')::uuid = v_nearest then
          v_mods := v_mods + 5; v_why := v_why || ' + M11 5 (the nearest season)';
        end if;
        v_items := v_items || jsonb_build_array(jsonb_build_object(
          'key',           'clash:' || coalesce(m->>'league_id', '') || ':' || coalesce(cl->>'week_no', ''),
          'tier',          case when v_band = 1000 then 'closing' else 'coming' end,
          'band',          v_band, 'mods', least(99, v_mods), 'mod_reason', v_why,
          'subject',       v_them, 'human_subject', true,
          'eyebrow',       upper(coalesce(nullif(cl->>'rivalry', ''), m->>'name'))
                             || ' · THE CLASH · CLOSES ' || upper(v_when),
          'headline',      v_head,
          'standfirst',    v_stand,
          'action',        v_act,
          'route',         v_route,
          'league_id',     m->>'league_id',
          'suppress',      case when v_mine is not null then '["my_last_round"]'::jsonb else '[]'::jsonb end,
          'spine',         'ember',
          'at',            cl->>'ends_on'));
      end;
    end if;

    -- ---- the month floor (D140 · squads only, never a solo season) --------
    if pu is not null and coalesce(m #>> '{settings,structure}', '') <> 'solo'
       and coalesce((pu->>'floor')::numeric, 0) > 0
       and coalesce((pu->>'partial')::boolean, false) = false
       and coalesce((pu->>'credits')::numeric, 0) < coalesce((pu->>'floor')::numeric, 0)
       and (date_trunc('month', v_today) + interval '1 month - 1 day')::date - v_today <= 3 then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'floor:' || coalesce(m->>'league_id', ''),
        'tier',          'closing', 'band', 1000,
        'mods',          70, 'mod_reason', 'M1 30 (the month) + M2 40 (me)',
        'subject',       'you', 'human_subject', true,
        'eyebrow',       upper(to_char(v_today, 'FMMonth')) || ' CLOSES '
                           || upper(to_char((date_trunc('month', v_today) + interval '1 month - 1 day')::date, 'Dy')),
        'headline',      'You are '
                           || rtrim(trim(to_char(coalesce((pu->>'floor')::numeric, 0) - coalesce((pu->>'credits')::numeric, 0), 'FM999990.9')), '.')
                           || ' short of the minimum.',
        'standfirst',    case when nullif(m #>> '{squad,name}', '') is not null
                              then 'The ' || (m #>> '{squad,name}') || ' carry the penalty, not you.' end,
        'action',        'Add my round',
        'route',         jsonb_build_object('kind', 'composer'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'ember',
        'at',            null));
    end if;

    -- ---- BAND 2 · CHANGED — my rank moved, and the label carries its clock
    -- A-4: `prev_rank` is a SUNDAY snapshot, so the movement is stated
    -- "since Sunday" or it is not stated at all. A bare "held" is unwritable.
    if st is not null and coalesce(se->>'status', '') = 'active'
       and nullif(st->>'prev_rank', '') is not null
       and (st->>'prev_rank')::int <> (st->>'rank')::int then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'move:' || coalesce(m->>'league_id', ''),
        'tier',          'changed', 'band', 800,
        'mods',          60, 'mod_reason', 'M2 40 (me) + M8 20 (this week)',
        'subject',       'you', 'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?'),
        'headline',      case when (st->>'prev_rank')::int > (st->>'rank')::int
                              then 'You moved up ' || ((st->>'prev_rank')::int - (st->>'rank')::int) || ' since Sunday.'
                              else 'You were passed since Sunday.' end,
        'standfirst',    case when nullif(st #>> '{next_up,name}', '') is not null
                              then (st #>> '{next_up,name}') || ' is the next one up.' end,
        'action',        'See the table',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id', 'pane', 'table'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'gold',
        'at',            null));
    end if;

    -- ---- BAND 3 · COMING — the first tee, when the season has not started
    if se is not null and nullif(se->>'days_to_first_tee', '') is not null then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'firsttee:' || coalesce(m->>'league_id', ''),
        'tier',          case when (se->>'days_to_first_tee')::int <= 3 then 'closing' else 'coming' end,
        'band',          case when (se->>'days_to_first_tee')::int <= 3 then 1000 else 600 end,
        'mods',          14, 'mod_reason', 'M8 14 (a dated thing)',
        'subject',       coalesce(nullif(m->>'pro_name', ''), 'you'),
        'human_subject', true,
        'eyebrow',       'FIRST TEE ' || upper(to_char((se->>'starts_on')::date, 'Dy Mon FMDD')),
        'headline',      m->>'name' || ' starts in ' || (se->>'days_to_first_tee')
                           || case when (se->>'days_to_first_tee')::int = 1 then ' day.' else ' days.' end,
        'standfirst',    'Rounds you post before then still build your number — they just do not score yet.',
        'action',        'Open the season',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'ember',
        'at',            se->>'starts_on'));
    end if;

    -- ---- BAND 5 · CHAPTER — the season's slow truth, told by a person -----
    if st is not null and coalesce(se->>'status', '') in ('active', 'cup_final')
       and nullif(st->>'leader_name', '') is not null then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'chapter:' || coalesce(m->>'league_id', ''),
        'tier',          'chapter', 'band', 200,
        'mods',          case when (m->>'league_id')::uuid = v_nearest then 5 else 0 end,
        'mod_reason',    case when (m->>'league_id')::uuid = v_nearest
                              then 'M11 5 (the nearest season)' else 'none' end,
        'subject',       st->>'leader_name', 'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?')
                           || ' OF ' || coalesce(se->>'weeks_total', '?'),
        'headline',      case when (st->>'rank')::int = 1
                              then 'You are the one to catch.'
                              else (st->>'leader_name') || ' is the one to catch.' end,
        'standfirst',    case when coalesce((se->>'days_left')::int, 0) > 0
                              then coalesce(se->>'days_left', '?') || ' days still to play.' end,
        'action',        'Open the season',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'mut',
        'at',            null));
    end if;

    -- ---- BAND 5b · R-H's reach into history ------------------------------
    -- A quiet day reaches BACK for an older true fact rather than stopping at
    -- "nothing has moved". The last completed season of this league is that
    -- fact, it is on the payload already, and it is the state every member of
    -- a wrapped season is in the morning after (S7).
    if nullif(m->'last_season', 'null'::jsonb) is not null
       and nullif(m #>> '{last_season,champion_name}', '') is not null
       and coalesce(se->>'status', '') <> 'active' then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'lastseason:' || coalesce(m->>'league_id', ''),
        'tier',          'chapter', 'band', 200, 'mods', 0, 'mod_reason', 'none',
        -- LV-11 · the champion may be the CALLER. Without the branch a golfer
        -- who WON read their own name in the third person, beside "You
        -- finished 1 of 8." The file already branches this way one item down
        -- ("You are the one to catch.").
        'subject',       case when (m #>> '{last_season,champion_is_me}')::boolean is true
                              then 'you' else m #>> '{last_season,champion_name}' end,
        'human_subject', true,
        'eyebrow',       upper(m->>'name') || ' · SEASON COMPLETE',
        'headline',      case when (m #>> '{last_season,champion_is_me}')::boolean is true
                              then 'You took the last one.'
                              else (m #>> '{last_season,champion_name}') || ' took the last one.' end,
        -- LV-11 · an ORDINAL, the way the Swift fallback prints it
        -- (`CSCopy.ordinal`). This printed a raw rank — "You finished 3 of 8."
        'standfirst',    case when nullif(m #>> '{last_season,my_rank}', '') is not null
                                   and nullif(m #>> '{last_season,of}', '') is not null
                              then 'You finished ' || ordinal((m #>> '{last_season,my_rank}')::int)
                                     || ' of ' || (m #>> '{last_season,of}') || '.' end,
        'action',        'See how it ended',
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'gold',
        'at',            m #>> '{last_season,ended_on}'));
    end if;

    -- ---- BAND 6 · OPPORTUNITY — a wrapped season with nothing live -------
    if coalesce(se->>'status', '') = 'complete' then
      v_items := v_items || jsonb_build_array(jsonb_build_object(
        'key',           'runitback:' || coalesce(m->>'league_id', ''),
        'tier',          'opportunity', 'band', 100,
        'mods',          case when coalesce(bi->>'note', '') <> '' then 6 else 0 end,
        'mod_reason',    'none',
        'subject',       case when m->>'role' = 'commissioner' then 'you'
                              else coalesce(nullif(m->>'pro_name', ''), 'the Pro') end,
        'human_subject', true,
        'eyebrow',       upper(m->>'name'),
        'headline',      case when m->>'role' = 'commissioner'
                              then 'Season two starts when you say it does.'
                              else 'Season two starts when '
                                     || coalesce(nullif(m->>'pro_name', ''), 'the Pro') || ' says it does.' end,
        'standfirst',    null,
        'action',        case when m->>'role' = 'commissioner' then 'Run it back'
                              else 'Ask ' || coalesce(nullif(m->>'pro_name', ''), 'the Pro') || ' to run it back' end,
        'route',         jsonb_build_object('kind', 'season', 'id', m->>'league_id'),
        'league_id',     m->>'league_id',
        'suppress',      '[]'::jsonb,
        'spine',         'mut',
        'at',            null));
    end if;

    -- ---- v2 / D257 · THE PLAN YOU NEED (R-K, second half) -----------------
    -- A round that has to be SCHEDULED to close a gap or hold a lead. It is a
    -- ranked item, not a sixth slot on the plan sheet, and its whole design is
    -- the fence: L-21 forbids a manufactured stake, so every guard below is a
    -- condition on the ARITHMETIC being real, not on the sentence being good.
    if st is not null
       and coalesce(se->>'status', '') = 'active'
       and coalesce(m #>> '{settings,structure}', '') = 'solo'
       and nullif(st->>'rank', '') is not null
       and coalesce((st->>'of')::int, 0) >= 2
       and nullif(m #>> '{settings,counting_cap}', '') is not null
       and (m #>> '{settings,counting_cap}')::int > 0
    then
      declare
        v_cap   int := (m #>> '{settings,counting_cap}')::int;
        v_mc    jsonb;
        v_used  int;
        v_worst numeric;
        v_gain  numeric;
        v_wkl   int;
        v_when2 text;
        v_gap2  numeric;
        v_who2  text;
        v_head2 text;
        v_sub2  text;
      begin
        v_mc    := month_counters((m->>'member_id')::uuid, (se->>'id')::uuid, v_cap, v_today);
        v_used  := coalesce((v_mc->>'used')::int, 0);
        v_worst := (v_mc->>'worst')::numeric;
        v_gain  := round_worth(v_cap, v_used, v_worst);
        -- "the counting rounds are in hand": a slot the golfer can still fill
        -- this month. With the month full the honest item is the climb's, on
        -- the season page, and Home says nothing.
        if v_used < v_cap and v_gain is not null and v_gain > 0 then
          -- weeks left comes from D246's ONE week producer (native_home), never
          -- from a second ceil(days/7) — §4.27's whole point.
          v_wkl := greatest(0, coalesce((se->>'weeks_total')::int, 0) - coalesce((se->>'week_no')::int, 0));
          v_when2 := case when v_wkl = 0 then 'in the last week'
                          when v_wkl = 1 then 'with one week left'
                          else 'with ' || v_wkl || ' weeks left' end;
          v_head2 := null;
          if (st->>'rank')::int > 1
             and nullif(st #>> '{next_up,name}', '') is not null
             and nullif(st->>'gap_to_next', '') is not null then
            -- CHASING · one top-band round must genuinely close it, which is
            -- the same refusal the climb makes: two rounds each bump a better
            -- counter, so "two rounds closes it" is arithmetic nobody can
            -- stand behind.
            v_gap2 := (st->>'gap_to_next')::numeric;
            if v_gap2 > 0 and v_gain >= v_gap2 then
              v_who2  := firstname(st #>> '{next_up,name}');
              v_head2 := 'You are ' || rtrim(trim(to_char(v_gap2, 'FM999990.9')), '.') || ' back of ' || v_who2 || ' ' || v_when2 || '.';
              v_sub2  := 'One counting round in the top band closes it — your best ' || v_cap
                           || ' count this month and you have ' || v_used || '.';
            end if;
          elsif (st->>'rank')::int = 1
             and nullif(st #>> '{next_down,name}', '') is not null
             and nullif(st #>> '{next_down,points}', '') is not null then
            -- LEADING · the row below must be inside ONE top-band round of me.
            -- That is a challenger the engine can point at; a lead nobody can
            -- take in one round is not a thing to nudge anybody about.
            v_gap2 := coalesce((st->>'points')::numeric, 0) - (st #>> '{next_down,points}')::numeric;
            if v_gap2 > 0 and v_gap2 <= cup_points(3)::numeric then
              v_who2  := firstname(st #>> '{next_down,name}');
              v_head2 := 'You are ' || rtrim(trim(to_char(v_gap2, 'FM999990.9')), '.') || ' clear of ' || v_who2 || ' ' || v_when2 || '.';
              v_sub2  := 'One more counting round is worth up to ' || rtrim(trim(to_char(v_gain, 'FM999990.9')), '.')
                           || ' — your best ' || v_cap || ' count this month and you have ' || v_used || '.';
            end if;
          end if;
          if v_head2 is not null then
            v_items := v_items || jsonb_build_array(jsonb_build_object(
              'key',           'need:' || coalesce(m->>'league_id', ''),
              'tier',          'coming', 'band', 600,
              'mods',          70, 'mod_reason', 'M2 40 (me) + M3 30 (the row beside me)',
              'subject',       v_who2, 'human_subject', true,
              'eyebrow',       upper(m->>'name') || ' · WEEK ' || coalesce(se->>'week_no', '?'),
              'headline',      v_head2,
              'standfirst',    v_sub2,
              'action',        'Put a round on the schedule',
              'route',         jsonb_build_object('kind', 'declare'),
              'league_id',     m->>'league_id',
              'suppress',      '[]'::jsonb,
              'spine',         'mut',
              'at',            se->>'week_ends_on'));
          end if;
        end if;
      end;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 3 · COMING — a plan on the sheet. The ME strip owns NEXT (L-34), so
  -- this item names the COURSE and the PEOPLE, never the time a second time.
  -- =========================================================================
  for e in select * from jsonb_array_elements(coalesce(v_me->'upcoming_rounds', '[]'::jsonb)) loop
    if coalesce(e->>'my_rsvp', '') <> 'out'
       and (coalesce((e->>'mine')::boolean, false) or coalesce((e->>'tagged_me')::boolean, false))
       and nullif(e->>'play_on', '') is not null
       and (e->>'play_on')::date between v_today and v_today + 8 then
      declare
        v_in  int := greatest(0, coalesce((e->>'rsvp_in')::int, 0));
        v_d   int := (e->>'play_on')::date - v_today;
        v_who text := coalesce(firstname(e->>'display_name'), 'A golfer');
        -- the day as a WORD, for a sentence rather than a slot. `MeStripCopy
        -- .dayWord` is its twin on the phone and `HomeFallbackItems` uses it
        -- for the same item, so the ranker and the declared fallback say the
        -- same thing about the same plan.
        v_day text := case ((e->>'play_on')::date - v_today)
                        when 0 then 'today' when 1 then 'tomorrow'
                        else case when (e->>'play_on')::date - v_today between 2 and 6
                                  then to_char((e->>'play_on')::date, 'FMDay')
                                  else to_char((e->>'play_on')::date, 'FMMon FMDD') end end;
      begin
        v_items := v_items || jsonb_build_array(jsonb_build_object(
          'key',           'plan:' || coalesce(e->>'id', ''),
          'tier',          case when v_d <= 3 then 'closing' else 'coming' end,
          'band',          case when v_d <= 3 then 1000 else 600 end,
          'mods',          least(99, greatest(0, 20 - v_d * 2) + 12),
          'mod_reason',    'M8 ' || greatest(0, 20 - v_d * 2) || ' (a dated thing) + M6 12 (a buddy)',
          'subject',       case when coalesce((e->>'mine')::boolean, false) then 'you' else v_who end,
          'human_subject', true,
          'eyebrow',       upper(to_char((e->>'play_on')::date, 'Dy'))
                             || case when nullif(e->>'course_label', '') is not null
                                     then ' · ' || upper(e->>'course_label') else '' end,
          -- L-34 · the EYEBROW above already carries the where-and-when, so the
          -- headline carries the who-and-what and the standfirst the detail.
          -- It read `MON · GOLD CANYON — DINOSAUR MOUNTAIN · BLACK/BLUE` with
          -- `Galen has you down for Gold Canyon — Dinosaur Mountain ·
          -- Black/Blue.` immediately under it: the same fact, in full, twice
          -- on one card. That is the whole reason the grammar has three slots.
          'headline',      case when coalesce((e->>'mine')::boolean, false)
                                then 'You have a round on ' || v_day || '.'
                                else v_who || ' has you down for ' || v_day || '.' end,
          'standfirst',    nullif(concat_ws(' · ',
                                   nullif(to_char((e->>'tee_time')::time, 'FMHH12:MI'), '') || ' tee',
                                   case when v_in > 1 then v_in || ' of you on the sheet' end)
                                 || '.', '.'),
          'action',        case when coalesce(e->>'my_rsvp', '') = '' then 'Say you''re in' else 'Open the plan' end,
          'route',         jsonb_build_object('kind', 'plan', 'id', e->>'id'),
          'league_id',     null,
          'suppress',      '[]'::jsonb,
          'spine',         'ember',
          'at',            e->>'play_on'));
      end;
    end if;
  end loop;

  -- =========================================================================
  -- BAND 4 · CIRCLE — someone I know did something. One item, the freshest.
  -- =========================================================================
  begin
    select jsonb_build_object(
             'key',           'story:' || s.round_id,
             'tier',          'circle', 'band', 400,
             'mods',          12, 'mod_reason', 'M6 12 (a buddy)',
             'subject',       firstname(s.golfer), 'human_subject', true,
             'eyebrow',       'AROUND YOUR BUDDIES',
             'headline',      firstname(s.golfer) || ' posted ' || s.gross
                                || case when nullif(s.course, '') is not null then ' at ' || s.course else '' end || '.',
             'standfirst',    case when s.is_pr then 'A personal best.'
                                   when s.is_sub80 then 'Under 80 for the first time.'
                                   when s.is_first then 'Their first round on the card.'
                                   when not s.has_rating then 'No rating on that one, so it builds a number and nothing else.'
                              end,
             'action',        'See the round',
             'route',         jsonb_build_object('kind', 'receipt', 'id', s.round_id),
             'league_id',     null,
             'suppress',      '[]'::jsonb,
             'spine',         case when s.is_pr or s.is_sub80 then 'gold' else 'mut' end,
             'at',            s.created_at)
      into e
      from home_stories(v_days, null) s
     where not s.is_me and s.gross is not null
     order by s.created_at desc
     limit 1;
    if e is not null then v_items := v_items || jsonb_build_array(e); end if;
  exception when others then
    null;
  end;

  -- =========================================================================
  -- BAND 6 · OPPORTUNITY — the door worth walking through today, fired only
  -- on a REAL shape. Never a tip, never a promotion.
  -- =========================================================================
  if v_rounds = 0 then
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', 'first_round', 'tier', 'opportunity', 'band', 100, 'mods', 40,
      'mod_reason', 'M2 40 (me)',
      'subject', 'you', 'human_subject', true,
      'eyebrow', 'NEW HERE',
      'headline', 'Your first round is the only thing missing.',
      'standfirst', 'Add one you already played — course, score, done. Your number starts building at three.',
      'action', 'Add my round',
      'route', jsonb_build_object('kind', 'composer'),
      'league_id', null, 'suppress', '[]'::jsonb, 'spine', 'ember', 'at', null));
  elsif v_friends = 0 then
    v_items := v_items || jsonb_build_array(jsonb_build_object(
      'key', 'find_golfers', 'tier', 'opportunity', 'band', 100, 'mods', 40,
      'mod_reason', 'M2 40 (me)',
      'subject', 'you', 'human_subject', true,
      'eyebrow', v_rounds || ' ROUNDS IN',
      'headline', 'Your number is yours, and nobody has seen it.',
      'standfirst', 'The golfers you already play with are the ones worth adding.',
      'action', 'Find golfers',
      'route', jsonb_build_object('kind', 'people'),
      'league_id', null, 'suppress', '[]'::jsonb, 'spine', 'mut', 'at', null));
  end if;

  -- =========================================================================
  -- The gates, applied after the score.
  -- =========================================================================

  -- G1 · the fence. An item with no door does not render. (Every item above
  -- carries one; the clause is here so a later item that forgets is dropped
  -- rather than shipped as a dead sentence.)
  select coalesce(jsonb_agg(x order by (x->>'band')::int + (x->>'mods')::int desc,
                            coalesce(x->>'at', '') desc, x->>'key'), '[]'::jsonb)
    into v_items
    from jsonb_array_elements(v_items) x
   where nullif(x #>> '{route,kind}', '') is not null;

  -- G2 · the veto. Rank 1 goes to the highest-scoring item WITH A HUMAN
  -- SUBJECT. A bare standing can never lead; it keeps its score and sits in
  -- the deck. This is one clause and it is the whole difference between this
  -- Home and the shipped one.
  v_lead_ix := null;
  for i in 0 .. coalesce(jsonb_array_length(v_items), 0) - 1 loop
    if v_lead_ix is null and coalesce((v_items->i->>'human_subject')::boolean, false) then
      v_lead_ix := i;
    end if;
  end loop;

  v_rank := 0;
  if v_lead_ix is not null then
    e := v_items->v_lead_ix;
    v_rank := 1;
    v_sup := coalesce(e->'suppress', '[]'::jsonb);
    v_out := jsonb_build_array(e || jsonb_build_object(
      'rank', 1,
      'score', (e->>'band')::int + (e->>'mods')::int,
      'rank_reason', 'B' || (case (e->>'tier')
                               when 'closing' then '1' when 'changed' then '2'
                               when 'coming' then '3' when 'circle' then '4'
                               when 'chapter' then '5' else '6' end)
                       || ' ' || (e->>'band') || ' + ' || (e->>'mods') || ' ('
                       || coalesce(e->>'mod_reason', 'none') || ') = '
                       || ((e->>'band')::int + (e->>'mods')::int) || ' · lead (the veto is satisfied)'));
  end if;

  -- G5 · the cap. One lead plus at most four.
  for i in 0 .. coalesce(jsonb_array_length(v_items), 0) - 1 loop
    e := v_items->i;
    if v_rank >= 5 then exit; end if;
    if exists (select 1 from jsonb_array_elements(v_out) o where o->>'key' = e->>'key') then
      continue;
    end if;
    v_rank := v_rank + 1;
    v_out := v_out || jsonb_build_array(e || jsonb_build_object(
      'rank', v_rank,
      'score', (e->>'band')::int + (e->>'mods')::int,
      'rank_reason', 'B' || (case (e->>'tier')
                               when 'closing' then '1' when 'changed' then '2'
                               when 'coming' then '3' when 'circle' then '4'
                               when 'chapter' then '5' else '6' end)
                       || ' ' || (e->>'band') || ' + ' || (e->>'mods') || ' ('
                       || coalesce(e->>'mod_reason', 'none') || ') = '
                       || ((e->>'band')::int + (e->>'mods')::int)));
  end loop;

  return jsonb_build_object(
    'me',           v_me,
    'items',        v_out,
    'lead_suppress', v_sup,
    'generated_at', now());
end $$;
revoke all on function public.home_dispatch(integer) from public, anon;
grant execute on function public.home_dispatch(integer) to authenticated;
