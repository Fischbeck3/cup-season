// W6 corrections 1, 3, 4 and 6 — the weekly report's SQL, run on SYNTHETIC
// fixtures in a disposable copy of the sandbox chain. Never a linked project.
//
//   PGBIN=/usr/lib/postgresql/16/bin tests/sim/sandbox/apply.sh   (once; builds `cupseason`)
//   CS_PG_BIN=<psql dir> node --test tests/pilot/scorecard-db.test.mjs
//
// Each run copies `cupseason` to cs_w6_fixture_test, loads
// tests/pilot/fixtures/w6-fixtures.sql, runs tools/pilot-scorecard.mjs
// (--sandbox --synthetic --json) at several report dates, and drops the copy.
// Without a running sandbox every test SKIPS and says why: CI has no database.
import { test, before, after } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');
const PG = process.env.CS_PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
const DB = 'cs_w6_fixture_test';
const CONN = ['-h', '/tmp/cs-sim-sock', '-p', '5478', '-U', 'postgres', '-X', '-q', '-v', 'ON_ERROR_STOP=1'];

function psql(db, args, input) {
  return spawnSync(join(PG, 'psql'), [...CONN, '-d', db, ...args], { encoding: 'utf8', input });
}
function sql(text) {
  const r = psql(DB, ['-At', '-c', text]);
  if (r.status) throw new Error(r.stderr);
  return r.stdout.trim();
}
const up = existsSync(join(PG, 'psql')) && psql('cupseason', ['-Atc', 'select 1']).status === 0;
const skip = up ? false : 'the sandbox is not running — build it with tests/sim/sandbox/apply.sh; CS_PG_BIN names the psql directory';

before(() => {
  if (skip) return;
  let r = psql('postgres', ['-c', `drop database if exists ${DB}`, '-c', `create database ${DB} template cupseason`]);
  if (r.status) throw new Error(r.stderr);
  r = psql(DB, ['-f', join(root, 'tests', 'pilot', 'fixtures', 'w6-fixtures.sql')]);
  if (r.status) throw new Error(r.stderr);
});
after(() => { if (!skip) psql('postgres', ['-c', `drop database if exists ${DB}`]); });

const cache = new Map();
function report(asOf, ...extra) {
  const key = [asOf, ...extra].join(' ');
  if (!cache.has(key)) {
    const r = spawnSync(process.execPath, [join(root, 'tools', 'pilot-scorecard.mjs'), '--sandbox', '--db', DB, '--synthetic', '--json', '--as-of', asOf, ...extra],
      { encoding: 'utf8', env: { ...process.env, CS_PG_BIN: PG } });
    assert.equal(r.status, 0, r.stderr);
    cache.set(key, JSON.parse(r.stdout));
  }
  return cache.get(key);
}
function rows(rep, section) {
  const s = rep.sections[section];
  assert.ok(s.rows, `${section}: ${JSON.stringify(s)}`);
  return s.rows.map(r => Object.fromEntries(s.header.map((h, i) => [h, r[i]])));
}
const one = (list, where) => {
  const hit = list.filter(r => Object.entries(where).every(([k, v]) => r[k] === v));
  assert.equal(hit.length, 1, `expected one row matching ${JSON.stringify(where)}, got ${hit.length}`);
  return hit[0];
};
const gate = (asOf, week, cohort) => one(rows(report(asOf), 'assistance_weekly'), { week, cohort });
const counts = r => [r.assisted_sessions, r.completions, r.assisted_completions, r.unassisted_completions, r.unknown_completions].map(Number);

// ── correction 1 · the assistance gate ──────────────────────────────────────

test('an all-assisted week is a STOP, and one game with two cards is one completion', { skip }, () => {
  const r = gate('2026-11-02', '2026-10-19', 'friends');
  assert.deepEqual(counts(r), [2, 2, 2, 0, 0]);
  assert.equal(r.cards_posted, '2');            // game 4 posted two cards; it is still one completion
  assert.equal(r.support_contacts, '1');        // support is shown beside, never counted as assistance
  assert.match(r.stop_condition, /^STOP/);
});

test('two overlapping sessions on one game make one assisted completion, not two', { skip }, () => {
  const r = gate('2026-11-02', '2026-10-12', 'friends');
  assert.deepEqual(counts(r), [2, 3, 1, 2, 0]);
  assert.equal(r.stop_condition, 'ok');         // 2 sessions, 2 unassisted: not exceeded
});

test('a mixed week counts only the uncovered games as unassisted', { skip }, () => {
  const r = gate('2026-11-02', '2026-10-19', 'independent');
  assert.deepEqual(counts(r), [1, 3, 1, 2, 0]);
  assert.equal(r.stop_condition, 'ok');
});

test('incomplete session evidence is UNKNOWN, never unassisted', { skip }, () => {
  // s6 is linked to game 12 by its league but has no end time; s7 names a
  // free-text group and no golfers and overlaps game 13
  const r = gate('2026-11-02', '2026-10-26', 'independent');
  assert.deepEqual(counts(r), [2, 2, 0, 0, 2]);
  assert.match(r.stop_condition, /^UNKNOWN: 2 completion\(s\) lack session evidence/);
});

test('a good prior week does not hide a failing current week', { skip }, () => {
  assert.equal(gate('2026-11-02', '2026-10-26', 'competition').stop_condition, 'ok');
  const now = gate('2026-11-02', '2026-11-02', 'competition');
  assert.deepEqual(counts(now), [1, 1, 1, 0, 0]);   // s9 and game 17 are after the cutoff
  assert.match(now.stop_condition, /^STOP/);
  // the report dated the day before has no such week: nothing after its cutoff
  assert.equal(rows(report('2026-11-01'), 'assistance_weekly').filter(r => r.week === '2026-11-02').length, 0);
});

test('the owner cohort is shown and never gated; an empty week says so rather than ok', { skip }, () => {
  assert.equal(gate('2026-11-02', '2026-10-26', 'owner').stop_condition, 'not gated');
  assert.equal(gate('2026-11-02', '2026-09-28', 'friends').stop_condition, 'no activity');
  assert.equal(gate('2026-11-02', '2026-10-05', 'friends').stop_condition, 'ok');   // three games, no session
});

test('the old four-week aggregate, on the same rows, said ok where the week says STOP', { skip }, () => {
  // what 82cb92f compared: every assisted session in four weeks against every
  // finished game in four weeks (reproduced in docs/pilot/examples/w6-reproduction.md)
  const four = rows(report('2026-10-25'), 'assistance_weekly').filter(r => r.cohort === 'friends');
  const sessions = four.reduce((a, r) => a + Number(r.assisted_sessions), 0);
  const games = four.reduce((a, r) => a + Number(r.completions), 0);
  assert.ok(!(sessions > games), 'the aggregate cannot see it');
  assert.match(one(four, { week: '2026-10-19' }).stop_condition, /^STOP/);
});

// ── correction 4 · one eligible population ──────────────────────────────────

test('founder, App Review, test-seed and deleted accounts are outside every activation count', { skip }, () => {
  const w41 = one(rows(report('2026-11-02'), 'activation_weekly'), { week: '2026-10-05' });
  assert.equal(w41.accounts_created, '1');      // G1 only: the reviewer, bot and deleted account share the day
  assert.equal(w41.first_rounds, '1');          // G1 only: the founder, bot and deleted rounds are that day too
});

test('weekly events are not a signup funnel: older accounts activate later', { skip }, () => {
  const wk = rows(report('2026-11-02'), 'activation_weekly');
  const w43 = one(wk, { week: '2026-10-19' });
  assert.equal(w43.accounts_created, '0');
  assert.equal(w43.first_rounds, '2');          // A1 and A2, accounts from August
  assert.equal(w43.second_rounds, '1');         // G1
  const w42 = one(wk, { week: '2026-10-12' });
  assert.equal(w42.first_rounds, '1');          // G2's first counted round; the voided one never counts
  const cohort = one(rows(report('2026-11-02'), 'activation_cohort'), { signup_week: '2026-10-05' });
  assert.deepEqual([cohort.accounts, cohort.posted_a_round_by_cutoff, cohort.posted_a_second_by_cutoff].map(Number), [1, 1, 1]);
});

test('a real game is non-sandbox with an eligible golfer — the same rule in every game count', { skip }, () => {
  const rep = report('2026-11-02');
  const lg = rows(rep, 'live_games'), act = rows(rep, 'activation_weekly');
  // W43: the sandbox league's game with a bot is not counted anywhere
  assert.equal(one(lg, { week: '2026-10-19' }).finished_by_cutoff, '5');
  assert.equal(one(act, { week: '2026-10-19' }).live_games_finished, '5');
  // W44: the founder's solo game is not a real game
  assert.equal(one(lg, { week: '2026-10-26' }).finished_by_cutoff, '4');
  assert.equal(one(act, { week: '2026-10-26' }).live_games_finished, '4');
  // league-less games are real games
  assert.equal(one(lg, { week: '2026-10-26' }).league_less, '3');
});

test('a guest seat is account-less at play, not any seat carrying the default claim token', { skip }, () => {
  const w41 = one(rows(report('2026-11-02'), 'sharing_outcomes'), { week: '2026-10-05' });
  assert.equal(w41.guest_seats, '2');
  assert.equal(w41.guest_seats_claimed_now, '1');
});

// ── correction 3 · one cutoff, local weeks, current state labelled ─────────

test('the end of the report date is the cutoff, in the report zone', { skip }, () => {
  const w45 = one(rows(report('2026-11-02'), 'activation_weekly'), { week: '2026-11-02' });
  assert.equal(w45.through, '2026-11-02');      // a partial week says so
  assert.equal(w45.accounts_created, '1');      // G4 at 23:30 counts; G5 at 00:10 the next day does not
  assert.ok(!rows(report('2026-11-02'), 'eligible').some(r => r.cohort === 'founding'), 'a cohort added after the cutoff is not in the report');
});

test('a backdated report counts nothing after its own date', { skip }, () => {
  const rep = report('2026-11-01');
  const wk = rows(rep, 'activation_weekly');
  assert.equal(wk[0].week, '2026-10-26');
  assert.equal(wk[0].through, '2026-11-01');
  assert.equal(one(wk, { week: '2026-10-26' }).accounts_created, '1');   // G3 only
  const earlier = rows(report('2026-10-25'), 'activation_weekly');
  assert.equal(earlier[0].week, '2026-10-19');
  assert.equal(one(earlier, { week: '2026-10-19' }).live_games_finished, '5');
});

test('weeks are local: Sunday 23:50 in Phoenix is that week, and --tz moves it', { skip }, () => {
  // G6's first round is posted Sun Nov 1 23:50 Phoenix = Mon Nov 2 06:50 UTC
  assert.equal(one(rows(report('2026-11-01'), 'activation_weekly'), { week: '2026-10-26' }).first_rounds, '1');
  assert.equal(one(rows(report('2026-11-01', '--tz', 'UTC'), 'activation_weekly'), { week: '2026-10-26' }).first_rounds, '0');
});

test('current-state columns carry _now and the markdown says what that means', { skip }, () => {
  const rep = report('2026-11-02');
  assert.ok(rep.sections.sharing_outcomes.header.includes('invitations_accepted_now'));
  assert.ok(rep.sections.live_games.header.includes('abandoned_now'));
  const md = spawnSync(process.execPath, [join(root, 'tools', 'pilot-scorecard.mjs'), '--sandbox', '--db', DB, '--synthetic', '--as-of', '2026-11-02'],
    { encoding: 'utf8', env: { ...process.env, CS_PG_BIN: PG } });
  assert.equal(md.status, 0, md.stderr);
  assert.match(md.stdout, /^# SYNTHETIC — fixture data, not a measurement/);
  assert.match(md.stdout, /Columns ending `_now` are the state when this report ran/);
  assert.match(md.stdout, /Reporting cutoff: everything before the end of \*\*2026-11-02\*\* in \*\*America\/Phoenix\*\*/);
});

// ── correction 6 · the attribution writer that already exists ───────────────

test('log_growth_event writes attribution once, for a claim and a join, and never for a direct arrival', { skip }, () => {
  // One transaction, rolled back: the trace leaves the fixture exactly as loaded.
  // Three fresh accounts with no golfer card yet; each "saves the card" by calling
  // the RPC as itself through the authenticated grant, as both clients do.
  const U = n => `00000000-0000-4000-8000-00000000090${n}`;
  const guestSeat = '00000000-0000-4000-a000-000000000002';   // game 1's unclaimed guest seat
  const call = (n, args) => `select set_config('sim.uid', '${U(n)}', true); select public.log_growth_event(${args});`;
  const read = (tag, id) => `select '${tag}=' || coalesce(came_via_kind, '∅') || '|' || coalesce(came_via_token, '∅') from public.profiles where id = '${id}';`;
  const out = sql(`begin;
    insert into auth.users (id, email, created_at) values
      ('${U(1)}', 'trace-claim@example.com', now()), ('${U(2)}', 'trace-join@example.com', now()), ('${U(3)}', 'trace-direct@example.com', now());
    insert into public.profiles (id, display_name, email)
      select id, 'trace', email from auth.users where id in ('${U(1)}', '${U(2)}', '${U(3)}') on conflict (id) do nothing;
    set local role authenticated;
    ${call(1, `'profile_created', 'claim', '${guestSeat}', '{"via":"claim"}'::jsonb, null`)}
    ${call(2, `'profile_created', 'join', 'synth1', '{"via":"join"}'::jsonb, null`)}
    ${call(3, `'profile_created', null, null, '{"via":"direct"}'::jsonb, null`)}
    ${call(1, `'profile_created', 'join', 'SYNTH1', '{}'::jsonb, null`)}
    reset role;
    ${read('claim', U(1))} ${read('join', U(2))} ${read('direct', U(3))}
    ${read('existing', '00000000-0000-4000-8000-000000000011')}
    select 'league=' || league_id from public.growth_events where actor = '${U(2)}' and node = 'profile_created';
    select 'events=' || count(*) from public.growth_events where actor in ('${U(1)}', '${U(2)}', '${U(3)}') and node = 'profile_created';
    rollback;`);
  const got = Object.fromEntries(out.split('\n').filter(l => l.includes('=')).map(l => l.split(/=(.*)/s).slice(0, 2)));
  assert.equal(got.claim, `claim|${guestSeat}`);        // the second call (a join) did not overwrite it
  assert.equal(got.join, 'join|synth1');
  assert.equal(got.direct, '∅|∅');                      // a direct arrival gains no acquisition history
  assert.equal(got.existing, '∅|∅');                    // nothing backfills an existing profile
  assert.equal(got.league, '00000000-0000-4000-b000-000000000001');   // the join code resolves to its league
  assert.equal(got.events, '4');                        // every call is still an event
  assert.equal(sql(`select count(*) from public.profiles where id::text like '00000000-0000-4000-8000-00000000090_'`), '0');
});

test('the attribution proxy column reads the writer, and the platform is the first event, not the door', { skip }, () => {
  const sf = rows(report('2026-11-02'), 'signups_first_event_platform');
  const w44 = one(sf, { week: '2026-10-26' });
  assert.equal(w44.attributed_to_a_link, '1');
  assert.equal(w44.link_kinds, 'claim');
  assert.equal(w44.first_event_ios, '1');       // G3's first event came a day after sign-up, from the phone
  const w41 = one(sf, { week: '2026-10-05' });
  assert.equal(w41.first_event_web, '1');       // G1: web first, the phone later — counted once, as web
  assert.equal(one(sf, { week: '2026-11-02' }).no_event_yet, '1');          // G4's only event is after the cutoff
  // a day later: G4's event counts, and it carried no platform — unlabelled, never guessed
  const w45 = one(rows(report('2026-11-03'), 'signups_first_event_platform'), { week: '2026-11-02' });
  assert.deepEqual([w45.accounts, w45.first_event_unlabelled, w45.no_event_yet].map(Number), [2, 1, 1]);
});
