// W6 · the acquisition half of the weekly growth report (tools/lib/growth-report.mjs).
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { parseAcquisitionCsv, weekly, cumulativeDownloads, checkpointTable, downloadsByChannel, cell, renderAcquisition, mondayOf, COLUMNS } from '../tools/lib/growth-report.mjs';

const HEADER = COLUMNS.join(',');
const csv = (...rows) => [HEADER, ...rows].join('\n');

test('a blank cell is missing, a 0 is zero, and the two never mix', () => {
  const { rows, problems } = parseAcquisitionCsv(csv('2026-10-04,by_hand,6,2,,0,3,"first week"'));
  assert.deepEqual(problems, []);
  assert.equal(rows[0].groups_playing, null);
  assert.equal(rows[0].appstore_first_time_downloads, 0);
  assert.equal(cell(rows[0].groups_playing), '—');
  assert.equal(cell(rows[0].appstore_first_time_downloads), '0');
});

test('a malformed row is reported and left out, never summed', () => {
  const { rows, problems } = parseAcquisitionCsv(csv('2026-10-04,by_hand,6,2,1,4,3,', 'Oct 11,by_hand,1,1,1,1,1,', '2026-10-18,by_hand,x,1,1,1,1,'));
  assert.equal(rows.length, 1);
  assert.equal(problems.length, 2);
  assert.match(problems[0], /week_ending/);
  assert.match(problems[1], /prospects_contacted/);
});

test('a missing header column is refused outright', () => {
  const r = parseAcquisitionCsv('week_ending,channel\n2026-10-04,by_hand');
  assert.equal(r.rows.length, 0);
  assert.match(r.problems[0], /header is missing/);
});

test('weeks sum across channels and stay missing when every row is blank', () => {
  const { rows } = parseAcquisitionCsv(csv('2026-10-04,by_hand,6,2,1,4,,', '2026-10-04,public_link,,,,,9,', '2026-09-27,by_hand,3,,,,,'));
  const w = weekly(rows);
  assert.equal(w[0].week_ending, '2026-10-04');
  assert.equal(w[0].prospects_contacted, 6);
  assert.equal(w[0].appstore_first_time_downloads, 4);
  assert.equal(w[0].testflight_installs, 9);
  assert.deepEqual(w[0].channels, ['by_hand', 'public_link']);
  assert.equal(w[1].organizers_activated, null);
});

test('the store count is never summed with TestFlight or web', () => {
  const { rows } = parseAcquisitionCsv(csv('2026-10-04,by_hand,,,,4,9,'));
  assert.equal(cumulativeDownloads(rows, '2026-10-31'), 4);
  const out = renderAcquisition({ rows, problems: [], asOf: '2026-10-05', webSignupsByWeek: new Map([['2026-10-04', 7]]) }).join('\n');
  assert.match(out, /\| 2026-10-04 \| — \| — \| — \| 4 \| 9 \| 7 \|/);
  assert.doesNotMatch(out, /\b20\b/);   // 4 + 9 + 7 never appears
});

test('checkpoints are met or missed on the count through their date, open before it, missing without data', () => {
  const { rows } = parseAcquisitionCsv(csv('2026-10-11,by_hand,,,,120,,', '2026-10-25,by_hand,,,,400,,', '2026-11-08,by_hand,,,,900,,'));
  const nov = checkpointTable(rows, '2026-11-10');
  assert.deepEqual(nov.map(c => [c.on, c.cumulative, c.gap, c.status]), [
    ['2026-10-31', 520, 0, 'met'],
    ['2026-11-30', 1420, 580, 'open'],
    ['2026-12-31', 1420, 3580, 'open'],
  ]);
  const early = checkpointTable([], '2026-10-05');
  assert.equal(early[0].status, 'missing');
  assert.equal(early[0].cumulative, null);
  const missed = checkpointTable(parseAcquisitionCsv(csv('2026-10-25,by_hand,,,,400,,')).rows, '2026-11-02');
  assert.equal(missed[0].status, 'missed');
});

test('downloads by channel are attributed only from rows that carry the number', () => {
  const { rows } = parseAcquisitionCsv(csv('2026-10-11,r/golf,,,,50,,', '2026-10-11,by_hand,2,1,,10,,', '2026-10-18,by_hand,,,,,3,'));
  assert.deepEqual(downloadsByChannel(rows, '2026-10-31'), [{ channel: 'r/golf', downloads: 50 }, { channel: 'by_hand', downloads: 10 }]);
});

test('the render says missing is missing, and does not forecast', () => {
  const out = renderAcquisition({ rows: [], problems: [], asOf: '2026-10-05', storeLive: false }).join('\n');
  assert.match(out, /zero by definition until Apple approves/);
  assert.match(out, /\| 2026-10-31 \| 500 \| — \| — \| missing \|/);
  assert.match(out, /no rows logged yet/);
  assert.match(out, /unverified/);
  assert.doesNotMatch(out, /forecast(?!\.)/i);
});

test('a week-ending Sunday maps to the ISO week Monday the database uses', () => {
  assert.equal(mondayOf('2026-10-04'), '2026-09-28');
  assert.equal(mondayOf('2026-09-30'), '2026-09-28');
  assert.equal(mondayOf('2026-09-28'), '2026-09-28');
});
