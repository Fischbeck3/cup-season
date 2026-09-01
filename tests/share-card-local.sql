-- ============================================================================
-- Cup Season — share_card (D186) local functional check
--
-- tests/db-checks.sql asserts GRANTS against prod. This one asserts BEHAVIOUR,
-- against a throwaway Postgres, so the card branch can be exercised before
-- 'supabase db push' ever runs. A remote session has no Supabase CLI; this is
-- how the migration was verified on 2026-09-01.
--
--   initdb -D /tmp/cs -U postgres --auth=trust      # as a non-root user
--   pg_ctl -D /tmp/cs -o '-p 55432' -l /tmp/cs/log start
--   psql -p 55432 -U postgres -f tests/share-card-local.sql
--
-- The stub schema below is deliberately minimal: enough for the ALTERs to bind
-- and for the CARD branch + share_buddy to RUN. The round / settlement / recap
-- branches are syntax-checked when the function is created and never called.
-- Expected output is inline at the bottom of this file.
-- ============================================================================

-- Minimal stand-in schema: enough for the ALTERs to bind and for the CARD
-- branch + share_buddy to actually RUN. The round/settlement/recap branches
-- are syntax-checked at create time and never called here.
create schema if not exists storage;
create table storage.objects (bucket_id text, name text);

create table public.profiles (
  id uuid primary key, display_name text, handle text, marker text, city text,
  home_course text, index_current numeric, ghin_number text, photo_path text,
  discoverable text not null default 'everyone' check (discoverable in ('everyone','friends','nobody')),
  created_at timestamptz not null default now(), deleted_at timestamptz,
  came_via_kind text, came_via_token text
);
alter table public.profiles add constraint profiles_came_via_kind_check
  check (came_via_kind in ('share','claim','join','recap','settlement'));

create table public.rounds (
  id uuid primary key default gen_random_uuid(), profile_id uuid, gross int,
  differential numeric, index_at_post numeric, played_on date,
  created_at timestamptz default now(), voided boolean default false,
  source text default 'app', holes_played int, course_label text, season_id uuid
);
create table public.achievements (
  profile_id uuid, kind text, label text, earned_on date, meta jsonb
);
create table public.friendships (
  id uuid primary key default gen_random_uuid(), requester uuid, addressee uuid,
  status text default 'pending', responded_at timestamptz
);
create table public.live_rounds (id uuid primary key, status text, game text,
  course_label text, game_result jsonb, started_at timestamptz, finished_at timestamptz,
  league_id uuid, started_by uuid);
create table public.live_round_players (live_round_id uuid, member_id uuid, position int,
  guest_name text, guest_gross int, claim_token uuid);
create table public.league_members (id uuid, league_id uuid, profile_id uuid);
create table public.leagues (id uuid, name text, code text);
create table public.seasons (id uuid, league_id uuid, starts_on date, ends_on date,
  status text, champion_squad_id uuid, points_king_member_id uuid);
create table public.squads (id uuid, season_id uuid, name text);
create table public.scan_claims (token uuid);
create view public.v_rounds_ranked as select null::uuid round_id, null::uuid season_id,
  null::numeric pvi, null::int points, null::uuid profile_id, null::date played_on;
create view public.v_squad_standings as select null::uuid squad_id, null::uuid season_id, null::int points;
create view public.v_individual_standings as select null::uuid member_id, null::uuid season_id, null::int points;

create table public.shares (
  token uuid primary key default gen_random_uuid(), kind text not null,
  ref_id uuid not null, created_by uuid not null, revoked boolean not null default false,
  created_at timestamptz not null default now()
);
alter table public.shares add constraint shares_kind_check
  check (kind in ('round','settlement','recap'));
create unique index shares_one_live on public.shares (kind, ref_id, created_by) where not revoked;

create table public.growth_events (
  id bigint generated always as identity primary key, at timestamptz not null default now(),
  node text not null, kind text, token text, league_id uuid, actor uuid,
  props jsonb not null default '{}'::jsonb
);
alter table public.growth_events add constraint growth_events_kind_check
  check (kind in ('share','claim','join','recap','settlement'));

-- the two things the real database supplies
create schema if not exists auth;
create table public.t_session (uid uuid);
create or replace function auth.uid() returns uuid language sql stable as
$$ select uid from public.t_session limit 1 $$;

-- friend_request, verbatim in shape from 20260827210000 minus the push half
create or replace function public.friend_request(p_profile uuid) returns text
language plpgsql security definer set search_path = public as $$
declare f record;
begin
  if p_profile = auth.uid() then raise exception 'That''s you'; end if;
  select * into f from friendships
   where least(requester, addressee)    = least(p_profile, auth.uid())
     and greatest(requester, addressee) = greatest(p_profile, auth.uid());
  if found then
    if f.status = 'accepted' then return 'friend'; end if;
    if f.requester = auth.uid() then return 'requested'; end if;
    update friendships set status = 'accepted', responded_at = now() where id = f.id;
    return 'friend';
  end if;
  insert into friendships (requester, addressee) values (auth.uid(), p_profile);
  return 'requested';
end $$;

create role anon; create role authenticated;

\i supabase/migrations/20260901120000_share_card.sql

\set ON_ERROR_STOP off
\pset tuples_only on
\pset format unaligned

-- two golfers
insert into profiles (id, display_name, handle, marker, city, index_current, discoverable)
values ('11111111-1111-1111-1111-111111111111','Jerecho Fischbeck','jerecho','saguaro','Tempe, AZ',12.4,'everyone'),
       ('22222222-2222-2222-2222-222222222222','Dana Reyes','dana','island','Mesa, AZ',8.1,'everyone');
insert into rounds (profile_id, gross, differential, index_at_post, played_on)
values ('11111111-1111-1111-1111-111111111111', 79, 9.2, 12.4, current_date),
       ('11111111-1111-1111-1111-111111111111', 88, 15.9, 12.4, current_date - 7);
insert into achievements values ('11111111-1111-1111-1111-111111111111','sub_80','Broke 80',current_date);

create or replace function be(u uuid) returns void language sql as
$$ delete from t_session; insert into t_session values (u); $$;

select be('11111111-1111-1111-1111-111111111111');

\echo '--- 1 mint own card'
select 'token: ' || (create_share('card','11111111-1111-1111-1111-111111111111'))::text;
\echo '--- 2 re-mint returns the SAME token (one artifact, one link)'
select 'same: ' || (
  (select token from shares where kind='card') = create_share('card','11111111-1111-1111-1111-111111111111'))::text;
\echo '--- 3 someone ELSE''s card is refused'
select create_share('card','22222222-2222-2222-2222-222222222222');
\echo '--- 4 share_info: the card, with the number (discoverable=everyone)'
select jsonb_pretty(share_info((select token from shares where kind='card'))
  #- '{career}' #- '{recent}' #- '{trophies}');
\echo '--- 5 career/recent/trophies are populated'
select 'rounds=' || (share_info((select token from shares where kind='card'))->'career'->>'rounds')
    || ' recent=' || jsonb_array_length(share_info((select token from shares where kind='card'))->'recent')
    || ' beat0=' || (share_info((select token from shares where kind='card'))->'recent'->0->>'beat')
    || ' trophies=' || jsonb_array_length(share_info((select token from shares where kind='card'))->'trophies');

\echo '--- 6 discoverable=friends + a NON-buddy viewer: card renders, number withheld'
update profiles set discoverable='friends' where id='11111111-1111-1111-1111-111111111111';
select be('22222222-2222-2222-2222-222222222222');
select 'name=' || (share_info((select token from shares where kind='card'))->>'name')
    || ' index=' || coalesce(share_info((select token from shares where kind='card'))->>'index_current','(withheld)');
\echo '--- 7 same card, once they ARE buddies: the number appears'
insert into friendships (requester, addressee, status)
values ('11111111-1111-1111-1111-111111111111','22222222-2222-2222-2222-222222222222','accepted');
select 'index=' || coalesce(share_info((select token from shares where kind='card'))->>'index_current','(withheld)');
delete from friendships;

\echo '--- 8 share_buddy from the other golfer -> requested'
select 'share_buddy: ' || share_buddy((select token from shares where kind='card'));
\echo '--- 9 share_buddy twice -> still requested, no duplicate row'
select 'again: ' || share_buddy((select token from shares where kind='card'))
    || ' rows=' || (select count(*) from friendships)::text;
\echo '--- 10 share_buddy on your OWN card -> self'
select be('11111111-1111-1111-1111-111111111111');
select 'self: ' || share_buddy((select token from shares where kind='card'));
\echo '--- 11 share_buddy on a made-up token -> the same refusal'
select share_buddy('00000000-0000-0000-0000-000000000000');

\echo '--- 12 discoverable=nobody kills every card link already minted'
update profiles set discoverable='nobody' where id='11111111-1111-1111-1111-111111111111';
select 'share_info: ' || coalesce(share_info((select token from shares where kind='card'))::text,'NULL');
select share_buddy((select token from shares where kind='card'));
\echo '--- 13 ...and a NEW mint is refused while unfindable'
select create_share('card','11111111-1111-1111-1111-111111111111');

\echo '--- 14 revoked token -> the same NULL as a bad one'
update profiles set discoverable='everyone' where id='11111111-1111-1111-1111-111111111111';
update shares set revoked=true where kind='card';
select 'revoked: ' || coalesce(share_info((select token from shares where kind='card'))::text,'NULL')
    || ' | garbage: ' || coalesce(share_info('00000000-0000-0000-0000-000000000000')::text,'NULL');

\echo '--- 15 the funnel takes kind=card, signed-out, only for a LIVE token'
update shares set revoked=false where kind='card';
delete from t_session;   -- auth.uid() is null: a signed-out reader
select log_growth_event('link_opened','card',(select token::text from shares where kind='card'));
select log_growth_event('link_opened','card','00000000-0000-0000-0000-000000000000');
select 'logged=' || (select count(*) from growth_events where kind='card')::text
    || ' (expect 1: the live token only)';

-- ---- expected (2026-09-01, Postgres 16.13) ---------------------------------
--  1 token minted · 2 same:true · 3 ERROR Nothing to share
--  4 kind=card, name, handle, marker, city, member_since, index_current=12.4
--  5 rounds=2 recent=2 beat0=true trophies=1
--  6 discoverable=friends, non-buddy viewer -> index=(withheld)
--  7 once buddies -> index=12.4
--  8 requested · 9 requested, rows=1 · 10 self · 11 ERROR That link is not live
-- 12 discoverable=nobody -> share_info NULL + share_buddy refuses
-- 13 new mint refused while unfindable
-- 14 revoked NULL, identical to a garbage token's NULL
-- 15 logged=1 — the funnel takes kind=card signed-out only for a LIVE token
