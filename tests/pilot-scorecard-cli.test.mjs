// W6 corrections 3 and 5 — the runner's flags, dates and inputs, with no
// database (--no-db). Every invalid input exits 2 with one sentence and no stack;
// a malformed log is reported and never crashes the report.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, writeFileSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { LOG_COLUMNS, READING_COLUMNS } from '../tools/lib/growth-report.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const runner = join(root, 'tools', 'pilot-scorecard.mjs');
const dir = mkdtempSync(join(tmpdir(), 'cs-w6-cli-'));
const file = (name, text) => { const p = join(dir, name); writeFileSync(p, text); return p; };
const EMPTY_LOG = file('empty-log.csv', LOG_COLUMNS.join(',') + '\n');
const EMPTY_READINGS = file('empty-readings.csv', READING_COLUMNS.join(',') + '\n');
const run = (...args) => spawnSync(process.execPath, [runner, ...args], { encoding: 'utf8' });
const inputs = ['--csv', EMPTY_LOG, '--readings', EMPTY_READINGS];

function refused(args, pattern) {
  const r = run(...args);
  assert.equal(r.status, 2, `${args.join(' ')} → exit ${r.status}\n${r.stdout}${r.stderr}`);
  assert.match(r.stderr, pattern);
  assert.doesNotMatch(r.stderr, /\n\s+at /, 'no stack trace');
  assert.equal(r.stdout, '');
}

test('a report date is a real calendar date', () => {
  refused(['--no-db', '--as-of', '2026-99-99'], /--as-of "2026-99-99" is not a real calendar date/);
  refused(['--no-db', '--as-of', '2026-02-30'], /not a real calendar date/);
  refused(['--no-db', '--as-of', '10/05/2026'], /not a real calendar date/);
});

test('a report is never dated ahead of today, except a labelled synthetic run', () => {
  refused(['--no-db', '--as-of', '2099-01-04'], /is after today/);
  const r = run('--no-db', '--synthetic', '--as-of', '2099-01-04', ...inputs);
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /^# SYNTHETIC — fixture data, not a measurement/);
});

test('--synthetic never touches the linked project', () => {
  refused(['--synthetic', '--as-of', '2026-09-20'], /--synthetic is for fixture runs only/);
});

test('the time zone is an IANA zone the runtime knows', () => {
  refused(['--no-db', '--tz', 'Mars/Olympus_Mons'], /is not a zone this runtime knows/);
  refused(['--no-db', '--tz', "UTC'; select 1; --"], /is not an IANA zone name/);
  const r = run('--no-db', '--as-of', '2026-09-20', '--tz', 'UTC', ...inputs);
  assert.equal(r.status, 0, r.stderr);
  assert.match(r.stdout, /everything before the end of \*\*2026-09-20\*\* in \*\*UTC\*\*/);
});

test('flags are strict: unknown, repeated, valueless or conflicting flags are refused', () => {
  refused(['--no-db', '--bogus'], /unknown flag --bogus/);
  refused(['--no-db', '--as-of', '2026-09-20', '--as-of', '2026-09-21'], /--as-of was given twice/);
  refused(['--no-db', '--as-of'], /--as-of needs a value/);
  refused(['--no-db', '--csv', '--json'], /--csv needs a value/);
  refused(['--no-db', 'stray'], /unexpected argument "stray"/);
  refused(['--no-db', '--sandbox'], /choose one target/);
  refused(['--db', 'cupseason'], /--db names a sandbox database; add --sandbox/);
  refused(['--sandbox', '--db', 'x; drop'], /is not a plain database name/);
  refused(['--no-db', '--store-live', 'yes'], /--store-live must be exactly "true" or "false"/);
  refused(['--no-db', '--csv', join(dir, 'nope.csv')], /does not exist/);
});

test('a malformed log is reported row by row and the report still renders', () => {
  const bad = file('bad-log.csv', [LOG_COLUMNS.join(','),
    '2026-99-99,by_hand,1,1,1,1,1,',                 // not a date: the 82cb92f runner crashed here
    '2026-10-05,by_hand,1,1,1,1,1,',                 // a Monday
    '2026-10-04,by_hand,1e2,,,,,',                   // not a whole number
    '2026-10-04,public_link,,,,3,,note, unquoted',   // shifted cells
    '2026-10-11,by_hand,,,,4,,', '2026-10-11,by_hand,,,,4,,',   // a duplicate key
    '2026-10-18,by_hand,,,,5,,"never closed',
  ].join('\n'));
  const r = run('--no-db', '--synthetic', '--as-of', '2026-10-20', '--csv', bad, '--readings', EMPTY_READINGS);
  assert.equal(r.status, 0, r.stderr);
  for (const p of [/week_ending "2026-99-99" is not a real calendar date/, /2026-10-05 is not a Sunday/, /"1e2" is not a whole number/,
    /9 cells where the header has 8/, /lines 6, 7 are all week 2026-10-11 \/ channel by_hand/, /a quoted field is never closed/]) assert.match(r.stdout, p);
  assert.match(r.stdout, /no rows logged yet/);    // every row above was left out; none was guessed
});

test('the acquisition half obeys the report date and the checkpoint rule, in JSON too', () => {
  const lg = file('log.csv', [LOG_COLUMNS.join(','), '2026-10-25,by_hand,,,,450,,', '2026-11-01,by_hand,,,,100,,'].join('\n'));
  const rd = file('readings.csv', [READING_COLUMNS.join(','), '2026-10-31,512,App Analytics,', '2026-11-30,1900,App Analytics,'].join('\n'));
  const r = run('--no-db', '--synthetic', '--json', '--as-of', '2026-11-01', '--csv', lg, '--readings', rd, '--store-live', 'true');
  assert.equal(r.status, 0, r.stderr);
  const j = JSON.parse(r.stdout);
  assert.equal(j.synthetic, true);
  assert.deepEqual(j.acquisition.checkpoints.map(c => c.status), ['met', 'open', 'open']);
  assert.equal(j.acquisition.leftOut.readings, 1);           // the Nov 30 reading is after the report date
  assert.equal(j.acquisition.checkpoints[0].logged.value, 450);
  assert.ok(Object.values(j.sections).every(s => /not read: no database/.test(s.skipped)));
});

test('no reading is said as no reading: every checkpoint open or unverified, never a zero', () => {
  const r = run('--no-db', '--json', '--as-of', '2026-09-20', ...inputs);
  assert.equal(r.status, 0, r.stderr);
  const j = JSON.parse(r.stdout);
  assert.deepEqual(j.acquisition.checkpoints.map(c => [c.status, c.evidence]), [['open', null], ['open', null], ['open', null]]);
  const late = JSON.parse(run('--no-db', '--synthetic', '--json', '--as-of', '2027-01-04', ...inputs).stdout);
  assert.deepEqual(late.acquisition.checkpoints.map(c => c.status), ['unverified', 'unverified', 'unverified']);
});

test('the SQL has one clock: no now(), current_date or current_timestamp anywhere', () => {
  const sql = readFileSync(join(root, 'tests', 'pilot', 'scorecard.sql'), 'utf8')
    .split('\n').filter(l => !/^\s*--/.test(l)).join('\n');
  assert.doesNotMatch(sql, /\bnow\s*\(|\bcurrent_date\b|\bcurrent_timestamp\b|\blocaltimestamp\b/i);
  // and every section that groups by week groups by the report zone's week
  assert.doesNotMatch(sql, /date_trunc\('week',\s*[a-z_.]+\s*\)/i);
});
