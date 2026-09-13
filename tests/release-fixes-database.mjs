// Cup Season — disposable PostgreSQL contract tests for the 2026-09-13 release
// fixes. Never accepts a remote database URL. Deliberately small fixtures: they
// validate the new wrappers' identity, replay and grant behaviour, not Cup
// Season's already-existing scoring engine. Same shape as
// tests/offline-post-database.py, in Node so it runs where that suite runs.
//
//   node tests/release-fixes-database.mjs
//
// Covers:
//   · round_post_status       (20261027090000) — read-only, owner-scoped, null when no receipt
//   · create_league_once      (20261028090000) — replay returns the same league, owner-scoped, private receipts
//   · join_covenant_info / join_covenant_for_invite (20261029090000) — allowance, cap, every-round-counts, dates; invite door == code door
//   · league_pulse            (20261030090000) — joined_this_month and bye_available, grants restated after the drop

import { readFileSync, mkdtempSync, mkdirSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomUUID } from 'node:crypto';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const bin = '/opt/homebrew/opt/postgresql@17/bin';
const mig = join(root, 'supabase', 'migrations');
const read = (name) => readFileSync(join(mig, name), 'utf8');

const temp = mkdtempSync(join(tmpdir(), 'cs-release-pg-'));
const data = join(temp, 'data'), sock = join(temp, 'socket'); mkdirSync(sock);
const PORT = '55438';

function run(cmd, args, input) {
  const p = spawnSync(cmd, args, { input, encoding: 'utf8' });
  return p;
}
let r = run(join(bin, 'initdb'), ['-D', data, '-A', 'trust', '--no-locale']);
if (r.status) { console.error(r.stderr); process.exit(1); }
r = run(join(bin, 'pg_ctl'), ['-D', data, '-l', join(temp, 'log'), '-o', `-k ${sock} -p ${PORT} -c listen_addresses=''`, 'start']);
if (r.status) { console.error(r.stderr); process.exit(1); }

function sql(text, ok = true) {
  const p = run(join(bin, 'psql'), ['-h', sock, '-p', PORT, '-d', 'postgres', '-q', '-v', 'ON_ERROR_STOP=1', '-At'], text);
  if (ok && p.status) throw new Error(p.stderr + '\n--- while running ---\n' + text.slice(0, 400));
  if (!ok && !p.status) throw new Error('Expected rejection: ' + text.slice(0, 300));
  return (p.stdout || '').trim();
}
const assert = (cond, msg) => { if (!cond) throw new Error('ASSERT: ' + msg); };

try {
  // ---- the fixture world: auth, roles, and the minimum of the public schema ----
  sql(`create role anon; create role authenticated; create role service_role;
    create schema auth; create table auth.users(id uuid primary key);
    create function auth.uid() returns uuid language sql as $$select nullif(current_setting('request.jwt.claim.sub',true),'')::uuid$$;
    create table public.profiles(id uuid primary key, display_name text, marker text, index_current numeric);
    create table public.leagues(id uuid primary key default gen_random_uuid(), name text, code text unique, commissioner_id uuid, phase text default 'setup');
    create table public.league_members(id uuid primary key default gen_random_uuid(), league_id uuid references public.leagues(id), profile_id uuid, role text, index_current numeric, joined_at timestamptz default now(), left_at timestamptz, unique(league_id, profile_id));
    create table public.league_settings(league_id uuid primary key references public.leagues(id), season_format text, structure text, season_months int, buyin_cents int default 0,
      preset text default 'standard', participation_floor int default 2, finish text default 'cup_final', buy_in_note text, buy_in_due_on date,
      counting_cap int, handicap_allowance int default 95, payout_champ int default 60, payout_runnerup int default 25, payout_king int default 15);
    create table public.seasons(id uuid primary key default gen_random_uuid(), league_id uuid, number int default 1, starts_on date, ends_on date, status text default 'active', timezone text default 'America/Phoenix');
    create table public.member_invites(id uuid primary key default gen_random_uuid(), league_id uuid, event_id uuid, profile_id uuid, invited_by uuid, status text default 'pending', created_at timestamptz default now());
    create table public.season_adjustments(id uuid primary key default gen_random_uuid(), season_id uuid, squad_id uuid, member_id uuid, month date, kind text, points numeric, reason text, created_by uuid);
    create table public.v_rounds_ranked(member_id uuid, season_id uuid, played_on date, floor_credit numeric, points numeric, month_rank int);
    create function public.is_league_member(p uuid) returns boolean language sql as $$ select exists(select 1 from public.league_members where league_id = p and profile_id = auth.uid()) $$;
    create table public.rounds(id uuid primary key default gen_random_uuid(), owner_id uuid, gross int);
    create table public.round_holes(round_id uuid references public.rounds(id) on delete cascade, hole_number int, strokes int check(strokes between 1 and 15));
    create function public.post_round(p_gross int,p_rating numeric,p_slope int,p_holes_played int default 18,p_nine_rating numeric default null,p_course_id text default null,p_course_label text default null,p_played_on date default current_date,p_photo_path text default null,p_played_with uuid[] default '{}') returns jsonb language plpgsql as $$
      declare r uuid; begin insert into public.rounds(owner_id,gross) values(auth.uid(),p_gross) returning id into r;
      return jsonb_build_object('round',jsonb_build_object('id',r)); end $$;
    -- the live create_league, verbatim in shape: league, commissioner seat, settings
    create function public.create_league(p_name text, p_code text) returns json language plpgsql security definer set search_path = public as $$
      declare v_league leagues; v_member league_members;
      begin
        insert into leagues (name, code, commissioner_id, phase) values (p_name, p_code, auth.uid(), 'setup') returning * into v_league;
        insert into league_members (league_id, profile_id, role) values (v_league.id, auth.uid(), 'commissioner') returning * into v_member;
        insert into league_settings (league_id, season_format, structure, season_months, buyin_cents) values (v_league.id, 'points', 'squads2', 3, 0);
        return json_build_object('league', row_to_json(v_league), 'member', row_to_json(v_member));
      end $$;
    grant usage on schema public to anon, authenticated;
    grant execute on function public.create_league(text, text) to authenticated;`);
  // the pre-existing covenant + pulse producers this sprint extends, in prod order
  sql(read('20260722211500_covenant_pulse_pairings.sql').split('create or replace function public.generate_pairings')[0]);
  sql(read('20260924110000_the_covenant_names_the_crew.sql'));
  sql(read('20261021090000_idempotent_phone_rounds.sql'));
  sql(read('20261026090000_the_terms_reach_every_door.sql'));
  // ---- the four new migrations, in order ----
  sql(read('20261027090000_a_post_can_be_asked_about.sql'));
  sql(read('20261028090000_one_league_however_many_times_start_is_pressed.sql'));
  sql(read('20261029090000_the_covenant_says_the_allowance.sql'));
  sql(read('20261030090000_the_pulse_says_who_joined_and_who_has_a_bye.sql'));

  const a = randomUUID(), b = randomUUID();
  sql(`insert into auth.users values('${a}'),('${b}'); insert into public.profiles values('${a}','Jerecho Fixture','saguaro',12.4),('${b}','Galen Fixture','owl',8.1);`);
  const asu = (who, text, role = 'authenticated') => `set request.jwt.claim.sub='${who}'; set role ${role}; ${text}`;

  // ======================= round_post_status =======================
  {
    const key = randomUUID();
    const payload = JSON.stringify({ gross: 72, rating: 72, slope: 113, holes_played: 18, played_on: '2026-09-13', course_label: 'QA fixture' });
    assert(sql(asu(a, `select public.round_post_status('${key}') is null;`)) === 't', 'no receipt → null');
    const posted = JSON.parse(sql(asu(a, `select public.post_round_once('${key}','${payload}'::jsonb, ARRAY[]::int[], '{}'::uuid[]);`)));
    const status = JSON.parse(sql(asu(a, `select public.round_post_status('${key}');`)));
    assert(status.round.id === posted.round.id, 'the status is the stored response, verbatim');
    assert(sql(asu(b, `select public.round_post_status('${key}') is null;`)) === 't', 'another golfer sees nothing');
    assert(sql('select count(*) from rounds') === '1', 'asking never posts');
    sql(asu(a, `select public.round_post_status('${key}');`, 'anon'), false);
    console.log('PASS  round_post_status · null before, verbatim after, owner-scoped, never posts, anon refused');
  }

  // ======================= create_league_once =======================
  let first;
  {
    const req = randomUUID();
    first = JSON.parse(sql(asu(a, `select public.create_league_once('${req}','The Fellas','FELLAS26');`)));
    const again = JSON.parse(sql(asu(a, `select public.create_league_once('${req}','The Fellas','FELLAS26');`)));
    assert(first.league.id === again.league.id, 'a replay returns the SAME league');
    assert(again.replayed === true && first.replayed !== true, 'and says it was a replay');
    assert(sql('select count(*) from leagues') === '1', 'one league');
    const renamed = JSON.parse(sql(asu(a, `select public.create_league_once('${req}','The Lads','LADS26');`)));
    assert(renamed.league.id === first.league.id && renamed.league.name === 'The Fellas', 'a conflicting body returns the stored league');
    assert(sql('select count(*) from leagues') === '1', 'a conflicting body mints nothing');
    const other = JSON.parse(sql(asu(b, `select public.create_league_once('${req}','Their League','THEIRS26');`)));
    assert(other.league.id !== first.league.id && sql('select count(*) from leagues') === '2', 'identity is (owner, request)');
    sql(asu(a, `select public.create_league_once('${randomUUID()}','Dupe','FELLAS26');`), false);
    assert(sql('select count(*) from cupseason_private.league_create_receipts') === '2', 'a refusal leaves no receipt');
    sql(asu(a, `select public.create_league_once('${randomUUID()}','Anon','ANON26');`, 'anon'), false);
    sql('set role authenticated; select * from cupseason_private.league_create_receipts', false);
    console.log('PASS  create_league_once · replay = same league, conflicting body mints nothing, owner-scoped, refusal leaves no receipt, private receipts');
  }

  // ======================= the covenant, from a code and from an invitation =======================
  const lid = first.league.id;
  {
    sql(`update league_settings set counting_cap = 3, participation_floor = 2, handicap_allowance = 90, buyin_cents = 5000 where league_id = '${lid}';`);
    sql(`insert into seasons(league_id, starts_on, ends_on) values ('${lid}','2026-09-13','2026-12-12');`);
    const codeView = JSON.parse(sql(asu(b, `select public.join_covenant_info('FELLAS26');`)));
    assert(codeView.handicap_allowance === 90 && codeView.counting_cap === 3 && codeView.every_round_counts === false, 'allowance and cap');
    assert(codeView.starts_on === '2026-09-13' && codeView.ends_on === '2026-12-12' && codeView.weeks === 13, 'dates and weeks');
    assert(codeView.floor === 2 && codeView.finish === 'cup_final', 'floor and finish');
    // a real anon caller carries NO sub claim; the fixture's auth.uid() reads the claim, not the role
    const anonView = JSON.parse(sql(`set request.jwt.claim.sub=''; set role anon; select public.join_covenant_info('FELLAS26');`));
    assert(!('handicap_allowance' in anonView) && !('roster' in anonView) && !('starts_on' in anonView), 'anon still gets the small object');
    const inv = sql(`insert into member_invites(league_id, profile_id, invited_by) values ('${lid}','${b}','${a}') returning id;`);
    const invView = JSON.parse(sql(asu(b, `select public.join_covenant_for_invite('${inv}');`)));
    assert(JSON.stringify(invView) === JSON.stringify(codeView), 'the invitation door shows exactly what the code door shows');
    assert(!('code' in invView), 'and never the code');
    assert(sql(asu(a, `select public.join_covenant_for_invite('${inv}') is null;`)) === 't', "somebody else's invitation is not a door");
    sql(`update member_invites set status = 'declined' where id = '${inv}';`);
    assert(sql(asu(b, `select public.join_covenant_for_invite('${inv}') is null;`)) === 't', 'a resolved invitation is not a door');
    sql(`update league_settings set counting_cap = null where league_id = '${lid}';`);
    const unl = JSON.parse(sql(asu(b, `select public.join_covenant_info('FELLAS26');`)));
    assert(unl.every_round_counts === true && unl.counting_cap === null, 'Unlimited is a present boolean, not an absent key');
    sql(asu(b, `select public.join_covenant_for_invite('${inv}');`, 'anon'), false);
    console.log('PASS  covenant · allowance, cap, every_round_counts, dates, weeks; invite door == code door; anon unchanged; no code');
  }

  // ======================= league_pulse: who joined this month, who still has a bye =======================
  {
    const sid = sql(`select id from seasons where league_id = '${lid}'`);
    const ma = sql(`select id from league_members where league_id = '${lid}' and profile_id = '${a}'`);
    sql(`insert into league_members(league_id, profile_id, role, joined_at) values ('${lid}','${b}','player', date_trunc('month', now()) + interval '3 days');`);
    sql(`update league_members set joined_at = date_trunc('month', now()) - interval '40 days' where id = '${ma}';`);
    let rows = sql(asu(a, `select row_to_json(p) from public.league_pulse('${lid}') p;`)).split('\n').map(JSON.parse);
    let by = Object.fromEntries(rows.map(r => [r.profile_id, r]));
    assert(by[a].joined_this_month === false && by[b].joined_this_month === true, 'joined_at against the league month');
    assert(by[a].bye_available === true && by[b].bye_available === true, 'nobody has spent a bye yet');
    sql(`insert into season_adjustments(season_id, member_id, month, kind, points, reason) values ('${sid}','${ma}', (date_trunc('month', now()) - interval '1 month')::date, 'bye', 0, 'Auto-bye');`);
    rows = sql(asu(a, `select row_to_json(p) from public.league_pulse('${lid}') p;`)).split('\n').map(JSON.parse);
    by = Object.fromEntries(rows.map(r => [r.profile_id, r]));
    assert(by[a].bye_available === false && by[b].bye_available === true, 'a spent bye is spent for the season');
    for (const k of ['credits', 'floor', 'at_floor', 'is_me', 'partial']) assert(k in by[a], `old column ${k} still there`);
    assert(sql(asu(b, `select count(*) from public.league_pulse('${lid}');`)) === '2', 'a member reads the table');
    sql(asu(a, `select * from public.league_pulse('${lid}');`, 'anon'), false);
    console.log('PASS  league_pulse · joined_this_month, bye_available, old columns intact, grants restated after the drop');
  }
  console.log('ALL PASS');
} catch (e) {
  console.error('FAIL', e.message);
  process.exitCode = 1;
} finally {
  run(join(bin, 'pg_ctl'), ['-D', data, 'stop', '-m', 'immediate']);
  rmSync(temp, { recursive: true, force: true });
}
