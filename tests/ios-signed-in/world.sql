-- Cup Season · UI-test review world (LOCAL STACK ONLY).
--
-- Re-runnable: every object has a fixed id and is created only if absent, so a
-- second run changes nothing. Fictional golfers only (@example.invalid); the
-- one course is the catalogue name the tests search for ("Bajamar", id 100)
-- with an INVENTED local test card (figures are not the real course's).
--
-- Expects (set by seed.sh):  rcui.golfer = the signed-in test golfer's email
--                            rcui.bots   = comma-separated bot emails (7)
-- Run as the local `postgres` role. Never point this at a linked project.

do $$
declare
  v_golfer_email text := current_setting('rcui.golfer');
  v_bot_emails   text[] := string_to_array(current_setting('rcui.bots'), ',');
  v_me     uuid;
  v_bots   uuid[] := '{}';
  v_id     uuid;
  -- fixed ids: the world is found again on every run
  c_league uuid := 'cafe0000-0000-4000-8000-000000000001';
  c_season uuid := 'cafe0000-0000-4000-8000-000000000002';
  c_sq_a   uuid := 'cafe0000-0000-4000-8000-000000000003';
  c_sq_b   uuid := 'cafe0000-0000-4000-8000-000000000004';
  v_names  text[] := array['Avery Lin','Blake Harmon','Dana Ortiz','Emery Cole','Finley Shaw','Gray Morales','Harper Quinn'];
  v_handles text[] := array['rcui_avery','rcui_blake','rcui_dana','rcui_emery','rcui_finley','rcui_gray','rcui_harper'];
  v_idx    numeric[] := array[6.2, 11.4, 14.9, 9.1, 18.3, 21.7, 16.0];
  v_starts date := current_date - 49;            -- seven weeks in
  v_member uuid;
  v_members uuid[] := '{}';
  v_roster uuid[];
  v_rindex numeric[];
  v_courses text[] := array['Papago GC','Encanto GC','Aguila GC','Cave Creek GC'];
  v_noise int[] := array[-3, 1, 4, -1, 6, 2, -2, 3, 0, 5];
  v_tee uuid;
  v_par int[] := array[4,5,3,4,4,5,4,3,4, 4,4,3,5,4,4,3,5,4];
  v_si  int[] := array[7,1,17,11,5,3,13,15,9, 8,2,18,4,10,6,16,12,14];
  i int; k int; n int; ri int;
  v_day date; v_rating numeric; v_slope int; v_gross int;
begin
  -- ---- golfers -----------------------------------------------------------
  select id into v_me from auth.users where lower(email) = lower(v_golfer_email);
  if v_me is null then raise exception 'test golfer % not found (seed.sh creates it)', v_golfer_email; end if;
  for i in 1..array_length(v_bot_emails, 1) loop
    select id into v_id from auth.users where lower(email) = lower(v_bot_emails[i]);
    if v_id is null then raise exception 'bot % not found (seed.sh creates it)', v_bot_emails[i]; end if;
    v_bots := v_bots || v_id;
  end loop;

  update profiles set display_name = 'Casey Ridgeway', handle = 'rcui_casey', marker = 'saguaro',
         city = 'Tempe, AZ', index_current = 12.4, index_source = 'self', discoverable = 'nobody',
         home_course = 'Bajamar'
   where id = v_me;
  for i in 1..7 loop
    update profiles set display_name = v_names[i], handle = v_handles[i], marker = 'saguaro',
           city = 'Mesa, AZ', index_current = v_idx[i], index_source = 'self', discoverable = 'nobody'
     where id = v_bots[i];
  end loop;

  -- ---- the course the offline tests search for (cache tables) ------------
  insert into api_courses (id, club_name, course_name, city, state, country)
  values ('100', 'Bajamar', 'Local test card', 'Ensenada', 'BC', 'Mexico')
  on conflict (id) do nothing;
  if not exists (select 1 from api_course_tees where course_id = '100') then
    insert into api_course_tees (course_id, gender, tee_name, course_rating, slope_rating, par_total, total_yards, number_of_holes)
    values ('100', 'male', 'Black', 73.1, 136, 72, 6904, 18) returning id into v_tee;
    for k in 1..18 loop
      insert into api_course_holes (tee_id, hole_number, par, yardage, handicap)
      values (v_tee, k, v_par[k], 300 + v_par[k] * 25 + k, v_si[k]);
    end loop;
    insert into api_course_tees (course_id, gender, tee_name, course_rating, slope_rating, par_total, total_yards, number_of_holes)
    values ('100', 'male', 'White', 69.8, 124, 72, 6212, 18) returning id into v_tee;
    for k in 1..18 loop
      insert into api_course_holes (tee_id, hole_number, par, yardage, handicap)
      values (v_tee, k, v_par[k], 270 + v_par[k] * 22 + k, v_si[k]);
    end loop;
  end if;

  -- ---- one live season the golfer plays in (squads2, seven weeks in) -----
  if exists (select 1 from leagues where id = c_league) then
    raise notice 'world already seeded; nothing to do';
    return;
  end if;

  insert into leagues (id, name, code, phase, commissioner_id)
  values (c_league, 'Saguaro Test Cup', 'RCUIT1', 'season', v_bots[1]);
  insert into league_settings (league_id, structure, season_format, preset, counting_cap, season_months, locked_at)
  values (c_league, 'squads2', 'hybrid', 'standard', 4, 6, now());
  insert into seasons (id, league_id, number, starts_on, ends_on, status, kicked_off)
  values (c_season, c_league, 1, v_starts, v_starts + 6 * 28 - 1, 'active', true);

  insert into league_members (league_id, profile_id, role, index_current)
  values (c_league, v_me, 'player', 12.4) returning id into v_member;
  v_members := v_members || v_member;
  for i in 1..7 loop
    insert into league_members (league_id, profile_id, role, index_current)
    values (c_league, v_bots[i], case when i = 1 then 'commissioner' else 'player' end, v_idx[i])
    returning id into v_member;
    v_members := v_members || v_member;
  end loop;

  insert into squads (id, season_id, name, color, captain_member_id) values (c_sq_a, c_season, 'Gila Monsters', 0, v_members[1]);
  insert into squads (id, season_id, name, color) values (c_sq_b, c_season, 'Roadrunners', 1);
  for i in 1..4 loop insert into squad_members (squad_id, member_id) values (c_sq_a, v_members[i]); end loop;
  for i in 5..8 loop insert into squad_members (squad_id, member_id) values (c_sq_b, v_members[i]); end loop;

  -- ---- rounds: 6–9 each across the seven weeks; the golfer's newest is at
  -- Bajamar (api_course_id 100), so a normal boot keeps that course on the phone
  v_roster := array[v_me] || v_bots;
  v_rindex := array[12.4::numeric] || v_idx;
  for ri in 1..8 loop
    n := 6 + ((ri - 1) % 4);
    for k in 0..(n - 1) loop
      v_day := v_starts + least(48, k * 5 + ((ri - 1) % 4));
      v_rating := 70 + ((k + ri) % 3);
      v_slope := 121 + ((k + ri) % 8);
      v_gross := greatest(66, round(v_rating + v_rindex[ri] * v_slope / 113.0 + v_noise[((k + ri) % 10) + 1])::int);
      if ri = 1 and k >= n - 2 then
        -- the golfer's two newest rounds: Bajamar, Black tees
        insert into rounds (profile_id, season_id, course_label, api_course_id, played_on, holes_played, gross, rating, slope, index_at_post, source)
        values (v_me, c_season, 'Bajamar', '100', v_day, 18, v_gross, 73.1, 136, 12.4, 'quick');
      else
        insert into rounds (profile_id, season_id, course_label, played_on, holes_played, gross, rating, slope, index_at_post, source)
        values (v_roster[ri], c_season, v_courses[((k + ri) % 4) + 1], v_day, 18, v_gross, v_rating, v_slope, v_rindex[ri], 'quick');
      end if;
    end loop;
  end loop;

  insert into posts (league_id, season_id, kind, body)
  values (c_league, c_season, 'system', 'Saguaro Test Cup is live. Say hello on the board.');

  -- ---- buddies: three accepted ------------------------------------------
  for i in 1..3 loop
    insert into friendships (requester, addressee, status, responded_at)
    values (v_me, v_bots[i * 2 - 1], 'accepted', now());
  end loop;

  raise notice 'seeded: league %, season %, % members', c_league, c_season, array_length(v_members, 1);
end $$;
