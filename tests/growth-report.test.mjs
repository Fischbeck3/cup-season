// W6 · the acquisition half of the weekly growth report (tools/lib/growth-report.mjs).
// Corrections 2 and 5 of docs/planning/2026-09-22-w6-review-and-claude-prompt.md:
// the review's own inputs are the first tests; what 82cb92f answered for each is
// recorded in docs/pilot/examples/w6-reproduction.md.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import {
  LOG_COLUMNS, READING_COLUMNS, parseAcquisitionCsv, parseReadingsCsv, parseCsv, parseCount, parseStoreLive,
  isRealDate, isSunday, mondayOf, sundaysBetween, checkpointTable, coverage, weekly, loggedSubtotal,
  downloadsByChannel, storeContradiction, readingsInconsistency, acquisitionModel, renderAcquisition, cell,
} from '../tools/lib/growth-report.mjs';

const log = (...rows) => [LOG_COLUMNS.join(','), ...rows].join('\n');
const readings = (...rows) => [READING_COLUMNS.join(','), ...rows].join('\n');
const NO_READINGS = { readings: [], problems: [], leftOutAfterAsOf: 0 };
/** The October checkpoint row for a log and a set of readings, as the report computes it. */
const oct = (rows, asOf, rd = []) => acquisitionModel({
  log: parseAcquisitionCsv(log(...rows), { asOf }), readings: parseReadingsCsv(readings(...rd), { asOf }), asOf,
}).checkpoints[0];

// ── correction 2 · a checkpoint is judged on a dated reading, never on subtotals ─

test('review case 1: only Oct 4 logged, 100 downloads, report Nov 1 → unverified, not missed', () => {
  const c = oct(['2026-10-04,by_hand,,,,100,,'], '2026-11-01');
  assert.equal(c.status, 'unverified');
  assert.equal(c.logged.value, 100);
  assert.deepEqual([c.logged.weeksLogged, c.logged.weeksExpected], [1, 4]);   // Oct 4, 11, 18, 25 expected through Oct 31
});

test('review case 2: the same row pasted twice is rejected with an actionable message, never summed to 600', () => {
  const p = parseAcquisitionCsv(log('2026-10-04,by_hand,,,,300,,', '2026-10-04,by_hand,,,,300,,'));
  assert.equal(p.rows.length, 0);
  assert.equal(p.problems.length, 1);
  assert.match(p.problems[0], /lines 2, 3 are all week 2026-10-04 \/ channel by_hand — one row per key; merge them into one row/);
  const c = oct(['2026-10-04,by_hand,,,,300,,', '2026-10-04,by_hand,,,,300,,'], '2026-11-01');
  assert.equal(c.status, 'unverified');
  assert.equal(c.logged.value, null);
});

test('review case 3: 450 through Oct 25 and 100 in the week ending Nov 1 cannot decide Oct 31', () => {
  const c = oct(['2026-10-25,by_hand,,,,450,,', '2026-11-01,by_hand,,,,100,,'], '2026-11-01');
  assert.equal(c.status, 'unverified');
  assert.equal(c.logged.value, 450);            // subtotal through Oct 31: the Nov 1 week is not in it
});

test('a dated App Analytics reading decides it: met on or before the date, missed on or after', () => {
  assert.equal(oct([], '2026-11-01', ['2026-10-31,512,App Analytics,']).status, 'met');
  assert.equal(oct([], '2026-11-01', ['2026-10-29,505,App Analytics,']).status, 'met');     // cumulative cannot fall
  assert.equal(oct([], '2026-11-01', ['2026-10-31,480,App Analytics,']).status, 'missed');
  assert.equal(oct([], '2026-11-03', ['2026-11-02,490,App Analytics,']).status, 'missed');  // still short after the date
  // a reading past the date that has reached the target cannot say WHEN it did
  assert.equal(oct([], '2026-11-03', ['2026-11-02,530,App Analytics,']).status, 'unverified');
  // before the date it is open, whatever the reading says so far
  const open = oct([], '2026-10-20', ['2026-10-19,210,App Analytics,']);
  assert.equal(open.status, 'open');
  assert.equal(open.evidence.value, 210);
});

test('no reading at all: open before the date, unverified after it — never missing-as-zero', () => {
  const t = checkpointTable([], '2026-12-01');
  assert.deepEqual(t.map(c => c.status), ['unverified', 'unverified', 'open']);
});

test('a reading dated after the report date is left out and said so', () => {
  const rd = parseReadingsCsv(readings('2026-10-31,512,App Analytics,', '2026-11-30,2100,App Analytics,'), { asOf: '2026-11-01' });
  assert.equal(rd.readings.length, 1);
  assert.equal(rd.leftOutAfterAsOf, 1);
});

test('duplicate reading dates are rejected; a falling cumulative blocks every checkpoint', () => {
  const dup = parseReadingsCsv(readings('2026-10-31,512,,', '2026-10-31,515,,'));
  assert.equal(dup.readings.length, 0);
  assert.match(dup.problems[0], /readings through 2026-10-31/);
  const falling = parseReadingsCsv(readings('2026-10-25,450,,', '2026-10-31,440,,')).readings;
  assert.match(readingsInconsistency(falling), /cannot fall/);
  const m = acquisitionModel({ log: parseAcquisitionCsv(log()), readings: { readings: falling, problems: [], leftOutAfterAsOf: 0 }, asOf: '2026-11-01' });
  assert.deepEqual(m.checkpoints.map(c => c.status), ['inconsistent readings', 'inconsistent readings', 'inconsistent readings']);
});

test('coverage says which weeks are missing; blank is missing, a written 0 is zero', () => {
  const { rows } = parseAcquisitionCsv(log('2026-10-04,by_hand,6,2,,0,3,first week', '2026-10-18,by_hand,1,,,,,'));
  assert.equal(rows[0].groups_playing, null);
  assert.equal(rows[0].appstore_first_time_downloads, 0);
  assert.equal(cell(rows[0].groups_playing), '—');
  assert.equal(cell(rows[0].appstore_first_time_downloads), '0');
  assert.deepEqual(coverage(rows, '2026-10-20').missing, ['2026-10-11']);
  assert.deepEqual(coverage(rows, '2026-10-20', 'appstore_first_time_downloads').missing, ['2026-10-11', '2026-10-18']);
  assert.deepEqual(loggedSubtotal(rows, '2026-10-20'), { value: 0, weeksLogged: 1, weeksExpected: 3 });
});

test('weeks sum across channels; the store count is never summed with TestFlight or web', () => {
  const { rows } = parseAcquisitionCsv(log('2026-10-04,by_hand,6,2,1,4,,', '2026-10-04,public_link,,,,,9,', '2026-09-27,by_hand,3,,,,,'));
  const w = weekly(rows);
  assert.equal(w[0].week_ending, '2026-10-04');
  assert.deepEqual([w[0].prospects_contacted, w[0].appstore_first_time_downloads, w[0].testflight_installs], [6, 4, 9]);
  assert.deepEqual(w[0].channels, ['by_hand', 'public_link']);
  assert.equal(w[1].organizers_activated, null);
  const out = renderAcquisition({ log: { rows, problems: [], leftOutAfterAsOf: 0 }, readings: NO_READINGS, asOf: '2026-10-05',
    webFirstEventByMonday: new Map([['2026-09-28', 7]]) }).lines.join('\n');
  assert.match(out, /\| 2026-10-04 \| 6 \| 2 \| 1 \| 4 \| 9 \| 7 \| by_hand, public_link \|/);
  assert.doesNotMatch(out, /\b20\b/);   // 4 + 9 + 7 never appears
});

test('downloads by channel are subtotals from rows that carry the number, through the report date', () => {
  const { rows } = parseAcquisitionCsv(log('2026-10-11,r/golf,,,,50,,', '2026-10-11,by_hand,2,1,,10,,', '2026-10-18,by_hand,,,,,3,', '2026-11-01,by_hand,,,,70,,'));
  assert.deepEqual(downloadsByChannel(rows, '2026-10-31'), [{ channel: 'r/golf', downloads: 50, weeks: 1 }, { channel: 'by_hand', downloads: 10, weeks: 1 }]);
});

// ── correction 3 · the report date bounds the acquisition half too ──────────

test('a backdated report leaves out later log rows and says how many', () => {
  const p = parseAcquisitionCsv(log('2026-10-04,by_hand,,,,10,,', '2026-11-01,by_hand,,,,90,,'), { asOf: '2026-10-05' });
  assert.equal(p.rows.length, 1);
  assert.equal(p.leftOutAfterAsOf, 1);
  const out = renderAcquisition({ log: p, readings: NO_READINGS, asOf: '2026-10-05' }).lines.join('\n');
  assert.doesNotMatch(out, /2026-11-01 \|/);
  assert.match(out, /Left out as after the report date 2026-10-05: 1 log row\(s\), 0 reading\(s\)/);
});

// ── correction 5 · strict dates, counts, flags and CSV; nothing throws ──────

test('only a real calendar date is a date, and a log week ends on a Sunday', () => {
  for (const bad of ['2026-99-99', '2026-02-30', '2026-13-01', '2026-10-4', 'Oct 4', '', null, undefined]) assert.equal(isRealDate(bad), false, String(bad));
  assert.equal(isRealDate('2028-02-29'), true);
  assert.equal(isSunday('2026-10-04'), true);
  assert.equal(isSunday('2026-10-05'), false);
  const p = parseAcquisitionCsv(log('2026-99-99,by_hand,1,1,1,1,1,', '2026-02-30,by_hand,1,1,1,1,1,', '2026-10-05,by_hand,1,1,1,1,1,', '2026-10-04,by_hand,1,1,1,1,1,'));
  assert.deepEqual(p.rows.map(r => r.week_ending), ['2026-10-04']);
  assert.match(p.problems[0], /line 2: week_ending "2026-99-99" is not a real calendar date/);
  assert.match(p.problems[1], /line 3: week_ending "2026-02-30" is not a real calendar date/);
  assert.match(p.problems[2], /line 4: week_ending 2026-10-05 is not a Sunday/);
});

test('mondayOf never throws, and maps a Sunday to its ISO week Monday', () => {
  assert.equal(mondayOf('2026-99-99'), null);
  assert.equal(mondayOf('garbage'), null);
  assert.equal(mondayOf('2026-10-04'), '2026-09-28');
  assert.equal(mondayOf('2026-09-30'), '2026-09-28');
  assert.equal(mondayOf('2026-09-28'), '2026-09-28');
  assert.deepEqual(sundaysBetween('2026-10-01', '2026-10-31'), ['2026-10-04', '2026-10-11', '2026-10-18', '2026-10-25']);
});

test('a count is digits only — no exponent, hex, sign, decimal or unit', () => {
  for (const bad of ['1e2', '0x10', '-1', '3.0', '3.5', 'ten', '5k']) assert.ok(parseCount(bad).error, bad);
  assert.deepEqual(parseCount(' 12 '), { value: 12 });   // surrounding space is trimmed, nothing else
  assert.deepEqual(parseCount(''), { value: null });
  assert.deepEqual(parseCount('0'), { value: 0 });
  const p = parseAcquisitionCsv(log('2026-10-04,by_hand,1e2,,,,,'));
  assert.equal(p.rows.length, 0);
  assert.match(p.problems[0], /prospects_contacted "1e2" is not a whole number; the row was left out/);
});

test('CSV: quoted commas and quotes parse; an unterminated quote and a wrong cell count are reported, not guessed', () => {
  const ok = parseAcquisitionCsv(log('2026-10-04,by_hand,1,,,,,"called Sam, then ""Jo"""'));
  assert.equal(ok.rows[0].notes, 'called Sam, then "Jo"');
  const shift = parseAcquisitionCsv(log('2026-10-04,by_hand,1,1,1,1,1,note, with a comma', '2026-10-11,by_hand,1,,,,,'));
  assert.deepEqual(shift.rows.map(r => r.week_ending), ['2026-10-11']);
  assert.match(shift.problems[0], /line 2: 9 cells where the header has 8 — check for an unquoted comma/);
  const open = parseAcquisitionCsv(log('2026-10-04,by_hand,1,1,1,1,1,ok', '2026-10-11,by_hand,1,1,1,1,1,"never closed', '2026-10-18,by_hand,1,1,1,1,1,'));
  assert.deepEqual(open.rows.map(r => r.week_ending), ['2026-10-04']);
  assert.match(open.problems[0], /line 3: a quoted field is never closed/);
  assert.deepEqual(parseCsv('').problems, ['the file is empty']);
});

test('the header must be exact: a missing or repeated column refuses the file', () => {
  assert.match(parseAcquisitionCsv('week_ending,channel\n2026-10-04,by_hand').problems[0], /header is missing/);
  const rep = parseAcquisitionCsv([...LOG_COLUMNS, 'channel'].join(',') + '\n');
  assert.equal(rep.rows.length, 0);
  assert.ok(rep.problems.some(p => /header repeats: channel/.test(p)));
});

test('a channel is a lowercase name; blank is unattributed', () => {
  const p = parseAcquisitionCsv(log('2026-10-04,,1,,,,,', '2026-10-11,By Hand,1,,,,,'));
  assert.deepEqual(p.rows.map(r => r.channel), ['unattributed']);
  assert.match(p.problems[0], /channel "By Hand"/);
});

test('--store-live is exactly true or false', () => {
  assert.equal(parseStoreLive('true'), true);
  assert.equal(parseStoreLive('false'), false);
  for (const bad of ['yes', 'TRUE', '1', '', undefined]) assert.throws(() => parseStoreLive(bad), /exactly "true" or "false"/);
});

test('store-live false with any App Store count is a contradiction, and no checkpoint is judged on it', () => {
  const lg = parseAcquisitionCsv(log('2026-10-04,by_hand,,,,25,,'));
  const rd = parseReadingsCsv(readings('2026-10-04,25,App Analytics,'));
  assert.match(storeContradiction({ rows: lg.rows, readings: rd.readings, storeLive: false }), /^CONTRADICTION: --store-live false/);
  assert.equal(storeContradiction({ rows: lg.rows, readings: rd.readings, storeLive: true }), null);
  assert.equal(storeContradiction({ rows: parseAcquisitionCsv(log('2026-10-04,by_hand,,,,0,4,')).rows, readings: [], storeLive: false }), null);
  const out = renderAcquisition({ log: lg, readings: rd, asOf: '2026-10-05', storeLive: false }).lines.join('\n');
  assert.match(out, /CONTRADICTION/);
  assert.match(out, /not judged — contradictory input/);
  assert.doesNotMatch(out, /\| met \|/);
});

test('nothing in the module throws on hostile input', () => {
  for (const text of [null, undefined, '', '\n\n', '"', 'a,b\n"', '﻿' + LOG_COLUMNS.join(',') + '\n2026-99-99,,,,,,,']) {
    assert.doesNotThrow(() => {
      const l = parseAcquisitionCsv(text, { asOf: '2026-10-05' });
      const r = parseReadingsCsv(text, { asOf: '2026-10-05' });
      renderAcquisition({ log: l, readings: r, asOf: '2026-10-05', storeLive: false });
    }, String(text));
  }
});

test('the render labels subtotals, readings and missing weeks, and does not forecast', () => {
  const out = renderAcquisition({ log: parseAcquisitionCsv(log()), readings: NO_READINGS, asOf: '2026-10-05', storeLive: false }).lines.join('\n');
  assert.match(out, /zero by definition until Apple approves/);
  assert.match(out, /\| 2026-10-31 \| 500 \| open \| — \| — \(0 of 1 weeks logged\) \|/);
  assert.match(out, /no rows logged yet/);
  assert.match(out, /no reading recorded yet/);
  assert.match(out, /Weekly log totals are subtotals/);
  assert.match(out, /unverified \(launch plan §0\)/);
  assert.doesNotMatch(out, /forecast(?!\.)/i);
});
