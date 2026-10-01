-- D403 · a word list at the door — the text filter App Store 1.2 asks for, with no AI.
--
-- Guideline 1.2 lists "a method for filtering objectionable material from being
-- posted" as its own requirement, beside reporting and blocking. Until this
-- migration nothing was screened before publication: `_clean_text` strips control
-- characters and that is all. The owner ruled (2026-10-01) that the filter is a word
-- list in the database, not an AI service: no golfer's words leave for a third party.
--
-- What it refuses, and only this: slurs, explicit sexual content, and stated threats.
-- Ordinary swearing and golf banter pass ("kill it", "shoot 72", "we'll beat you
-- Saturday", "who's the bitch?"). It cannot understand context and does not read
-- images; a threat in plain words with no listed phrase is still the report path's.
--
-- How it reads text (public.cs_text_refused):
--   fold    NFKD, combining marks and zero-width characters dropped, lower case,
--           Cyrillic look-alikes and the common swaps (0 1 3 4 5 7 @ $ ! |) mapped
--           to letters, any run of 3+ of one character cut to two.
--   A       the words, split on anything that is not a letter, single letters spelled
--           out with separators glued back ("n i g g e r", "k.y.s") — for phrases.
--   B       each whitespace word with its separators removed ("f.a.g.g.o.t") — for words.
--   match   whole words only (\m … \M), so "Scunthorpe", "Hancock", "Dick", "Van Dyke",
--           "Cummings" and "spic and span" pass. A name field skips the one listed
--           word that is also a common given name.
--
-- Where it runs: BEFORE INSERT OR UPDATE triggers on every column a golfer types into
-- that another golfer can read (the list is the trigger block at the foot), including
-- the typed course name wherever one is stored. A course field (':course') passes any
-- official course or club name in the cached catalogue (api_courses), so a real place
-- is never refused for its name; only typed words outside an official name are read. An UPDATE is checked only when that
-- column changed, so an old row can never block an unrelated edit, and a server write
-- that copies nothing new is never refused. Posts are filtered only for the kinds a
-- golfer writes (chat, announce, bag): a round, system or moment post is written by
-- the server from facts, so a round can never be lost to its own story. The same rule
-- for rounds: only a round a golfer types in (source 'quick') has its course name read;
-- a round the server copies from a live round or a scan claim carries a name that was
-- read when it was typed, so finishing or claiming one is never refused.
--
-- What the golfer reads: one sentence, the same on both clients, naming no word:
--   "Cup Season can't take that wording — no slurs, sexual content or threats. Edit it and try again."
-- It is a plain `raise exception` (P0001), which both clients' error mappers pass
-- through verbatim (index.html ourSentence allowlist; BoardText.ourRaises).
--
-- Grants: every function here is internal. Nothing is granted to anon or
-- authenticated; triggers run with the writer's rights and call the helpers as the
-- definer.

create or replace function public._cs_fold(p text)
returns text
language sql immutable parallel safe
set search_path = pg_catalog
as $$
  select regexp_replace(
           translate(
             regexp_replace(lower(normalize(coalesce(p, ''), NFKD)),
                            '[̀-ͯ​-‏⁠﻿]', '', 'g'),
             -- look-alikes and swaps → letters (equal-length lists)
             'аеорсухіј013457@$!|€',
             'aeopcyxijoieastasiie'),
           '(.)\1{2,}', '\1\1', 'g')
$$;
revoke all on function public._cs_fold(text) from public, anon, authenticated;

create or replace function public.cs_text_refused(p text, p_name boolean default false)
returns boolean
language plpgsql immutable parallel safe
set search_path = public, pg_catalog
as $$
declare
  f      text;
  tok    text;
  buf    text := '';
  a      text := '';
  b      text;
  -- words: matched against both A and B
  words  constant text :=
    '\m(' ||
    -- slurs
      'n+i+g+g+(e+r+|a+|u+h+)[sz]?'
    || '|s+a+n+d+n+i+g+g+(e+r+|a+)[sz]?'
    || '|f+a+g+(g+(o+|i+)t+)?s?'
    || '|w+e+t+b+a+c+k+s?|b+e+a+n+e+r+s?|g+o+o+k+s?|r+a+g+h+e+a+d+s?|t+o+w+e+l+h+e+a+d+s?'
    || '|j+i+g+a+b+o+o+s?|z+i+p+p+e+r+h+e+a+d+s?|g+o+l+l+i+w+o+g+s?|p+a+k+i+s?'
    || '|t+r+a+n+n+(y+|i+e+s?)|s+h+e+m+a+l+e+s?|r+e+t+a+r+d+(s|e+d)?'
    -- explicit sexual content
    || '|b+l+o+w+j+o+b+s?|h+a+n+d+j+o+b+s?|r+i+m+j+o+b+s?|c+u+m+s+h+o+t+s?|c+r+e+a+m+p+i+e+s?'
    || '|g+a+n+g+b+a+n+g+s?|d+e+e+p+t+h+r+o+a+t+|j+i+z+z+|d+i+l+d+o+e?s?'
    || '|p+o+r+n+(o+|s|h+u+b+)?|x+v+i+d+e+o+s?|n+u+d+e+s|p+e+d+o+(p+h+i+l+e+s?)?|t+i+t+t*y*f+u+c+k+'
    -- sexual violence
    || '|r+a+p+(e+|e+s|e+d|i+n+g+|i+s+t+s?)'
    || ')\M';
  -- separately, so a name field can skip them: listed words that are also given names
  name_words constant text := '\m(k+i+k+e+s?)\M';
  -- words that need a following-context exception
  idioms constant text :=
    '\m(c+h+i+n+k+s?)\M(?!\s+in\M)'
    || '|\m(s+p+i+c+k?s?)\M(?!\s+(and|n)\s+span)';
  -- phrases: matched against A only (spacing matters)
  phrases constant text :=
    '\m(' ||
      '(blow|hand|rim)\s+jobs?|cum\s+shots?|cream\s+pies?|gang\s+bangs?|deep\s+throat|send\s+nudes|porch\s+monkeys?'
    || '|kill\s+(your|ur)\s*self|go\s+kill\s+(your|ur)\s*self|k+y+s+'
    || '|(i\s+)?hope\s+(you|u|ya)\s+(die|dies|get\s+cancer)|(you|u)\s+should\s+(die|kill\s+(your|ur)\s*self)|go\s+die'
    || '|(i\s+ll|ill|i\s+will|i\s+m\s+(going\s+to|gonna)|im\s+(going\s+to|gonna)|imma|ima|gonna|going\s+to|we\s+will|we\s+ll)'
    ||   '\s+(murder|stab|strangle|rape)\s+(you|u|ya|ur|your|him|her|them)'
    || '|kill\s+(you|u|ya)\s+in\s+(your|ur)\s+sleep|kill\s+(you|u|ya)\s+and\s+(your|ur)\s+(family|kids|wife)'
    || '|shoot\s+(you|u|ya|him|her|them)\s+(dead|in\s+the\s+(head|face))'
    || '|i\s+know\s+where\s+(you|u)\s+live'
    || ')\M';
begin
  if p is null or btrim(p) = '' then return false; end if;
  f := _cs_fold(left(p, 5000));

  -- A: words split on non-letters; runs of single letters glued back together
  foreach tok in array regexp_split_to_array(f, '[^a-z]+') loop
    if tok = '' then continue; end if;
    if length(tok) = 1 then
      buf := buf || tok;
    else
      if buf <> '' then a := a || ' ' || buf; buf := ''; end if;
      a := a || ' ' || tok;
    end if;
  end loop;
  if buf <> '' then a := a || ' ' || buf; end if;
  a := a || ' ';

  -- B: each whitespace word, its inner separators removed
  b := ' ' || regexp_replace(regexp_replace(f, '[^a-z\s]+', '', 'g'), '\s+', ' ', 'g') || ' ';

  if a ~ words or b ~ words then return true; end if;
  if not p_name and (a ~ name_words or b ~ name_words) then return true; end if;
  if a ~ idioms then return true; end if;
  if a ~ phrases then return true; end if;
  return false;
end $$;
revoke all on function public.cs_text_refused(text, boolean) from public, anon, authenticated;

-- the one sentence; a function so tests and the trigger read the same constant
create or replace function public.cs_text_refusal()
returns text language sql immutable parallel safe set search_path = pg_catalog as $$
  select 'Cup Season can''t take that wording — no slurs, sexual content or threats. Edit it and try again.'::text
$$;
revoke all on function public.cs_text_refusal() from public, anon, authenticated;

-- TG_ARGV: column names; a trailing ':name' marks a name field, ':course' a course name
create or replace function public._cs_text_guard()
returns trigger
language plpgsql
security definer
set search_path = public, pg_catalog
as $$
declare
  arg    text;
  col    text;
  mode   text;
  v_new  text;
  v_old  text;
  v_left text;
  r      record;
  j_new  jsonb := to_jsonb(new);
  j_old  jsonb;
begin
  if tg_op = 'UPDATE' then j_old := to_jsonb(old); end if;
  foreach arg in array tg_argv loop
    col   := split_part(arg, ':', 1);
    mode  := split_part(arg, ':', 2);
    v_new := j_new ->> col;
    if v_new is null then continue; end if;
    if tg_op = 'UPDATE' then
      v_old := j_old ->> col;
      if v_new is not distinct from v_old then continue; end if;
    end if;
    if not cs_text_refused(v_new, mode = 'name') then continue; end if;
    if mode = 'course' then
      -- an official name inside the text is the place, not the golfer's words: take
      -- every catalogue club, course and town name out (whole words, longest first),
      -- then read what is left
      v_left := lower(v_new);
      for r in
        select o.n from (
          select distinct lower(btrim(v.n)) as n
            from api_courses c, lateral (values (c.club_name), (c.course_name), (c.city)) v(n)
           where v.n is not null and length(btrim(v.n)) >= 3
             and position(lower(btrim(v.n)) in lower(v_new)) > 0) o
         order by length(o.n) desc, o.n
      loop
        v_left := regexp_replace(v_left,
                    '\m' || regexp_replace(r.n, '([.^$*+?()\[\]{}|\\-])', '\\\1', 'g') || '\M', ' ', 'g');
      end loop;
      if not cs_text_refused(v_left) then continue; end if;
    end if;
    raise exception using message = cs_text_refusal(), hint = 'cs_text_refused';
  end loop;
  return new;
end $$;
revoke all on function public._cs_text_guard() from public, anon, authenticated;

-- ---- the columns a golfer types into ---------------------------------------
-- (create trigger has no IF NOT EXISTS; drop first so a re-run is clean)
drop trigger if exists cs_text_guard on public.posts;
create trigger cs_text_guard before insert or update of body on public.posts
  for each row when (new.kind in ('chat','announce','bag'))
  execute function public._cs_text_guard('body');

drop trigger if exists cs_text_guard on public.post_comments;
create trigger cs_text_guard before insert or update of body on public.post_comments
  for each row execute function public._cs_text_guard('body');

drop trigger if exists cs_text_guard on public.round_comments;
create trigger cs_text_guard before insert or update of body on public.round_comments
  for each row execute function public._cs_text_guard('body');

drop trigger if exists cs_text_guard on public.scheduled_rounds;
create trigger cs_text_guard before insert or update of name, note, course_label on public.scheduled_rounds
  for each row execute function public._cs_text_guard('name', 'note', 'course_label:course');

drop trigger if exists cs_text_guard on public.leagues;
create trigger cs_text_guard before insert or update of name, identity_description on public.leagues
  for each row execute function public._cs_text_guard('name', 'identity_description');

drop trigger if exists cs_text_guard on public.profiles;
create trigger cs_text_guard before insert or update of display_name, handle, city, home_course on public.profiles
  for each row execute function public._cs_text_guard('display_name:name', 'handle:name', 'city', 'home_course:course');

drop trigger if exists cs_text_guard on public.forfeits;
create trigger cs_text_guard before insert or update of name, terms, hangs_on, settled_note on public.forfeits
  for each row execute function public._cs_text_guard('name', 'terms', 'hangs_on', 'settled_note');

drop trigger if exists cs_text_guard on public.rivalry_names;
create trigger cs_text_guard before insert or update of name on public.rivalry_names
  for each row execute function public._cs_text_guard('name');

drop trigger if exists cs_text_guard on public.squads;
create trigger cs_text_guard before insert or update of name on public.squads
  for each row execute function public._cs_text_guard('name');

drop trigger if exists cs_text_guard on public.events;
create trigger cs_text_guard before insert or update of name, course_label on public.events
  for each row execute function public._cs_text_guard('name', 'course_label:course');

drop trigger if exists cs_text_guard on public.event_teams;
create trigger cs_text_guard before insert or update of name on public.event_teams
  for each row execute function public._cs_text_guard('name');

drop trigger if exists cs_text_guard on public.bag_items;
create trigger cs_text_guard before insert or update of label on public.bag_items
  for each row execute function public._cs_text_guard('label');

drop trigger if exists cs_text_guard on public.course_ratings;
create trigger cs_text_guard before insert or update of note on public.course_ratings
  for each row execute function public._cs_text_guard('note');

drop trigger if exists cs_text_guard on public.league_settings;
create trigger cs_text_guard before insert or update of buy_in_note on public.league_settings
  for each row execute function public._cs_text_guard('buy_in_note');

drop trigger if exists cs_text_guard on public.live_round_players;
create trigger cs_text_guard before insert or update of guest_name on public.live_round_players
  for each row execute function public._cs_text_guard('guest_name:name');

-- the course name a live round is started with (it becomes each golfer's round)
drop trigger if exists cs_text_guard on public.live_rounds;
create trigger cs_text_guard before insert or update of course_label on public.live_rounds
  for each row execute function public._cs_text_guard('course_label:course');

-- a scorecard scan's partner rows: the name and course a claim link shows its recipient
-- (scan_claim_info) and the claimed round carries
drop trigger if exists cs_text_guard on public.scan_claims;
create trigger cs_text_guard before insert or update of guest_name, course_label on public.scan_claims
  for each row execute function public._cs_text_guard('guest_name:name', 'course_label:course');

-- a round a golfer types in: its course name (the board and the round card show it).
-- Server-copied rounds ('live', 'scan_claim') were read when their name was typed.
drop trigger if exists cs_text_guard on public.rounds;
create trigger cs_text_guard before insert or update of course_label on public.rounds
  for each row when (new.source = 'quick')
  execute function public._cs_text_guard('course_label:course');

-- the Pro's ruling: its reason is posted to the board (adjust_points). Only the Pro's
-- own kind; the month close writes its reasons from facts and must never stop.
drop trigger if exists cs_text_guard on public.season_adjustments;
create trigger cs_text_guard before insert or update of reason on public.season_adjustments
  for each row when (new.kind = 'override')
  execute function public._cs_text_guard('reason');

-- self-check: the filter refuses what it must and passes what it must, or this
-- migration does not apply
do $$
begin
  if not cs_text_refused('you f4gg0t') then raise exception 'D403 self-check: obfuscated slur passed'; end if;
  if not cs_text_refused('kill yourself') then raise exception 'D403 self-check: threat passed'; end if;
  if cs_text_refused('Shot 79 at Scunthorpe, killed that drive. Fuck yeah.') then
    raise exception 'D403 self-check: banter refused';
  end if;
  if cs_text_refused('Kike Hernandez', true) then raise exception 'D403 self-check: a given name refused'; end if;
end $$;
