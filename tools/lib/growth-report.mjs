// Cup Season · the acquisition half of the weekly growth report (W6).
//
// Pure functions, no I/O, tested by tests/growth-report.test.mjs. The runner
// (tools/pilot-scorecard.mjs) reads two owner-kept files of COUNTS, never names:
//
//   docs/pilot/acquisition-log.csv       one row per week per channel — the
//     pipeline (prospects, organizers, groups) and the week's LOGGED first-time
//     App Store downloads and TestFlight installs. These are SUBTOTALS: a week
//     that was not logged is missing, and weekly totals cannot say what happened
//     before a mid-week date.
//   docs/pilot/appstore-readings.csv     DATED App Analytics readings: the
//     cumulative first-time App Store downloads from the listing's first day
//     through `through_date`, inclusive, as App Store Connect reported them.
//
// W6 correction 2: a checkpoint (500 by Oct 31 · 2,000 by Nov 30 · 5,000 by
// Dec 31) is MET or MISSED only on a dated reading — met when a reading on or
// before the checkpoint date has reached the target, missed when a reading on or
// after it (and on or before the report date) is still short. Otherwise it is
// OPEN before the date and UNVERIFIED after it. Weekly subtotals are printed
// beside, labelled as subtotals, and never decide a checkpoint.
//
// Three numbers are never summed: first-time App Store downloads, TestFlight
// installs and web sign-ups. A blank is missing ("—"); only a written 0 is zero.
// W6 correction 5: every date is a real calendar date (log weeks end on a
// Sunday), every count is a plain whole number, a duplicate key rejects every
// row that shares it, a malformed CSV row is reported and left out, and nothing
// here throws on bad input.

export const CHECKPOINTS = [
  { on: '2026-10-31', downloads: 500 },
  { on: '2026-11-30', downloads: 2000 },
  { on: '2026-12-31', downloads: 5000 },
];

/** The first week the launch objective counts: the week ending the Sunday after
 *  the October 1 submission. Coverage is expected from here (or from an earlier
 *  logged week, whichever comes first). */
export const FIRST_EXPECTED_WEEK = '2026-10-04';

export const LOG_COLUMNS = ['week_ending', 'channel', 'prospects_contacted', 'organizers_activated',
  'groups_playing', 'appstore_first_time_downloads', 'testflight_installs', 'notes'];
const LOG_COUNTS = LOG_COLUMNS.slice(2, 7);
export const READING_COLUMNS = ['through_date', 'appstore_first_time_downloads_cumulative', 'source', 'notes'];

// ── dates, strictly ─────────────────────────────────────────────────────────

/** A real calendar date in YYYY-MM-DD, or false. `2026-99-99` and `2026-02-30` are false. */
export function isRealDate(s) {
  if (typeof s !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(s)) return false;
  const [y, m, d] = s.split('-').map(Number);
  const t = new Date(Date.UTC(y, m - 1, d));
  return t.getUTCFullYear() === y && t.getUTCMonth() === m - 1 && t.getUTCDate() === d;
}
/** 0 = Sunday … 6 = Saturday, for a real date; null otherwise. */
export function weekday(s) {
  if (!isRealDate(s)) return null;
  const [y, m, d] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay();
}
export function isSunday(s) { return weekday(s) === 0; }
export function addDays(s, n) {
  if (!isRealDate(s)) return null;
  const [y, m, d] = s.split('-').map(Number);
  return new Date(Date.UTC(y, m - 1, d + n)).toISOString().slice(0, 10);
}
/** The Monday of the ISO week a real date falls in; null for anything else — never throws. */
export function mondayOf(s) {
  const w = weekday(s);
  if (w == null) return null;
  return addDays(s, w === 0 ? -6 : 1 - w);
}
/** Every Sunday from the first on/after `from` through `to`, inclusive. */
export function sundaysBetween(from, to) {
  if (!isRealDate(from) || !isRealDate(to) || from > to) return [];
  const out = [];
  let d = addDays(from, (7 - weekday(from)) % 7);
  while (d <= to) { out.push(d); d = addDays(d, 7); }
  return out;
}

/** A strict whole count: digits only — no sign, decimal, exponent or unit. */
export function parseCount(raw) {
  const s = String(raw ?? '').trim();
  if (s === '') return { value: null };
  if (!/^\d+$/.test(s)) return { error: `"${s}" is not a whole number` };
  const n = Number(s);
  if (!Number.isSafeInteger(n)) return { error: `"${s}" is too large` };
  return { value: n };
}

/** `--store-live`: exactly `true` or `false`. */
export function parseStoreLive(raw) {
  if (raw === 'true') return true;
  if (raw === 'false') return false;
  throw new Error(`--store-live must be exactly "true" or "false", not "${raw}"`);
}

// ── CSV, strictly ───────────────────────────────────────────────────────────

/** RFC 4180-style parse of the whole text: quoted fields may hold commas, ""
 *  escapes and newlines. Returns { header, records: [{ line, cells }], problems }.
 *  An unterminated quote drops that record with a diagnostic; so does a record
 *  whose cell count differs from the header's. Never throws. */
export function parseCsv(text) {
  const src = String(text ?? '').replace(/^﻿/, '');
  const problems = [];
  const raw = [];                          // { line, cells, open }
  let cells = [], cur = '', q = false, line = 1, start = 1, any = false;
  for (let i = 0; i < src.length; i++) {
    const ch = src[i];
    if (q) {
      if (ch === '"' && src[i + 1] === '"') { cur += '"'; i++; }
      else if (ch === '"') q = false;
      else { if (ch === '\n') line++; cur += ch; }
      continue;
    }
    if (ch === '"') { q = true; any = true; }
    else if (ch === ',') { cells.push(cur); cur = ''; any = true; }
    else if (ch === '\r') { /* CRLF */ }
    else if (ch === '\n') {
      cells.push(cur);
      if (any || cells.some(c => c.trim() !== '')) raw.push({ line: start, cells });
      cells = []; cur = ''; any = false; line++; start = line;
    } else { cur += ch; any = true; }
  }
  if (q) problems.push(`line ${start}: a quoted field is never closed — the rest of the file from here was left out`);
  else { cells.push(cur); if (any || cells.some(c => c.trim() !== '')) raw.push({ line: start, cells }); }
  if (!raw.length) return { header: [], records: [], problems: problems.length ? problems : ['the file is empty'] };
  const header = raw[0].cells.map(h => h.trim());
  const records = [];
  for (const r of raw.slice(1)) {
    if (r.cells.length !== header.length) {
      problems.push(`line ${r.line}: ${r.cells.length} cells where the header has ${header.length} — check for an unquoted comma; the row was left out`);
      continue;
    }
    records.push({ line: r.line, cells: r.cells.map(c => c.trim()) });
  }
  return { header, records, problems };
}

function checkHeader(header, want) {
  const problems = [];
  const missing = want.filter(c => !header.includes(c));
  const unknown = header.filter(c => !want.includes(c));
  const dup = header.filter((c, i) => header.indexOf(c) !== i);
  if (missing.length) problems.push(`header is missing: ${missing.join(', ')}`);
  if (unknown.length) problems.push(`header has columns the report does not read: ${unknown.join(', ')}`);
  if (dup.length) problems.push(`header repeats: ${[...new Set(dup)].join(', ')}`);
  return problems;
}

/** Reject every record that shares a key with another; say which lines and how to fix it. */
function rejectDuplicates(recs, keyOf, describe, problems) {
  const byKey = new Map();
  for (const r of recs) { const k = keyOf(r); if (!byKey.has(k)) byKey.set(k, []); byKey.get(k).push(r); }
  const keep = [];
  for (const [, group] of byKey) {
    if (group.length === 1) { keep.push(group[0]); continue; }
    problems.push(`lines ${group.map(g => g.line).join(', ')} are all ${describe(group[0])} — one row per key; merge them into one row. The report left every one of them out.`);
  }
  return keep;
}

/** The weekly log. `asOf` (optional) leaves out rows for weeks ending after it. */
export function parseAcquisitionCsv(text, { asOf = null } = {}) {
  const { header, records, problems } = parseCsv(text);
  if (!header.length) return { rows: [], problems, leftOutAfterAsOf: 0 };
  const hp = checkHeader(header, LOG_COLUMNS);
  if (hp.some(p => /missing|repeats/.test(p))) return { rows: [], problems: [...problems, ...hp], leftOutAfterAsOf: 0 };
  problems.push(...hp);
  const valid = [];
  for (const r of records) {
    const rec = { line: r.line };
    header.forEach((h, j) => { rec[h] = r.cells[j]; });
    if (!isRealDate(rec.week_ending)) { problems.push(`line ${r.line}: week_ending "${rec.week_ending}" is not a real calendar date (YYYY-MM-DD); the row was left out`); continue; }
    if (!isSunday(rec.week_ending)) { problems.push(`line ${r.line}: week_ending ${rec.week_ending} is not a Sunday — a week is logged on the Sunday it ends; the row was left out`); continue; }
    rec.channel = rec.channel === '' ? 'unattributed' : rec.channel;
    if (!/^[a-z0-9][a-z0-9_./-]*$/.test(rec.channel)) { problems.push(`line ${r.line}: channel "${rec.channel}" — use a lowercase name from acquisition-log.md; the row was left out`); continue; }
    let bad = false;
    for (const c of LOG_COUNTS) {
      const p = parseCount(rec[c]);
      if (p.error) { problems.push(`line ${r.line}: ${c} ${p.error}; the row was left out`); bad = true; break; }
      rec[c] = p.value;
    }
    if (!bad) valid.push(rec);
  }
  const unique = rejectDuplicates(valid, r => `${r.week_ending}|${r.channel}`, r => `week ${r.week_ending} / channel ${r.channel}`, problems);
  const rows = asOf ? unique.filter(r => r.week_ending <= asOf) : unique;
  return { rows, problems, leftOutAfterAsOf: unique.length - rows.length };
}

/** The dated App Analytics readings. `asOf` leaves out readings dated after it. */
export function parseReadingsCsv(text, { asOf = null } = {}) {
  const { header, records, problems } = parseCsv(text);
  if (!header.length) return { readings: [], problems, leftOutAfterAsOf: 0 };
  const hp = checkHeader(header, READING_COLUMNS);
  if (hp.some(p => /missing|repeats/.test(p))) return { readings: [], problems: [...problems, ...hp], leftOutAfterAsOf: 0 };
  problems.push(...hp);
  const valid = [];
  for (const r of records) {
    const rec = { line: r.line };
    header.forEach((h, j) => { rec[h] = r.cells[j]; });
    if (!isRealDate(rec.through_date)) { problems.push(`line ${r.line}: through_date "${rec.through_date}" is not a real calendar date; the reading was left out`); continue; }
    const p = parseCount(rec.appstore_first_time_downloads_cumulative);
    if (p.error || p.value == null) { problems.push(`line ${r.line}: appstore_first_time_downloads_cumulative ${p.error || 'is blank'} — a reading is a number; the reading was left out`); continue; }
    rec.value = p.value;
    valid.push(rec);
  }
  const unique = rejectDuplicates(valid, r => r.through_date, r => `readings through ${r.through_date}`, problems);
  unique.sort((a, b) => (a.through_date < b.through_date ? -1 : 1));
  const readings = asOf ? unique.filter(r => r.through_date <= asOf) : unique;
  return { readings, problems, leftOutAfterAsOf: unique.length - readings.length };
}

// ── what the inputs can and cannot say ─────────────────────────────────────

/** A cumulative count cannot go down. Returns the problem, or null. */
export function readingsInconsistency(readings) {
  for (let i = 1; i < readings.length; i++) {
    if (readings[i].value < readings[i - 1].value)
      return `App Analytics readings go down: ${readings[i - 1].value} through ${readings[i - 1].through_date}, then ${readings[i].value} through ${readings[i].through_date} — a cumulative count cannot fall; check the date range each reading used. No checkpoint is judged until this is corrected.`;
  }
  return null;
}

/** `--store-live false` says the listing is not live, so every App Store count
 *  must be zero. Anything else is contradictory input, said explicitly. */
export function storeContradiction({ rows = [], readings = [], storeLive = null }) {
  if (storeLive !== false) return null;
  const logged = rows.filter(r => (r.appstore_first_time_downloads ?? 0) > 0);
  const read = readings.filter(r => r.value > 0);
  if (!logged.length && !read.length) return null;
  const parts = [];
  if (read.length) parts.push(`App Analytics readings of ${read.map(r => `${r.value} through ${r.through_date}`).join(', ')}`);
  if (logged.length) parts.push(`logged weekly downloads in ${logged.map(r => `${r.week_ending}/${r.channel}`).join(', ')}`);
  return `CONTRADICTION: --store-live false says the App Store listing is not live, but the inputs record first-time App Store downloads (${parts.join('; ')}). Before approval that count is zero by definition — correct the flag or the entry. No checkpoint is judged on contradictory input.`;
}

/** The checkpoint table, from dated readings only (see the header). */
export function checkpointTable(readings, asOf, { blocked = null } = {}) {
  return CHECKPOINTS.map(cp => {
    const base = { on: cp.on, target: cp.downloads };
    if (blocked) return { ...base, status: blocked, evidence: null };
    const upTo = cp.on <= asOf ? cp.on : asOf;
    const proveMet = readings.filter(r => r.through_date <= upTo && r.value >= cp.downloads).pop();
    if (proveMet) return { ...base, status: 'met', evidence: proveMet };
    if (asOf < cp.on) {
      const latest = readings.filter(r => r.through_date <= asOf).pop() || null;
      return { ...base, status: 'open', evidence: latest };
    }
    const proveMissed = readings.find(r => r.through_date >= cp.on && r.through_date <= asOf && r.value < cp.downloads);
    if (proveMissed) return { ...base, status: 'missed', evidence: proveMissed };
    const before = readings.filter(r => r.through_date < cp.on).pop() || null;
    return { ...base, status: 'unverified', evidence: before };
  });
}

/** Which weeks the log should have, which it has, and which it lacks, through `asOf`. */
export function coverage(rows, asOf, col = null) {
  const logged = new Set(rows.filter(r => r.week_ending <= asOf && (col == null || r[col] != null)).map(r => r.week_ending));
  const first = [FIRST_EXPECTED_WEEK, ...logged].sort()[0];
  const expected = sundaysBetween(first, asOf);
  return { expected, logged: expected.filter(w => logged.has(w)), missing: expected.filter(w => !logged.has(w)) };
}

/** Sum a column across rows; null when EVERY row is missing it. */
function sumOrMissing(rows, col) {
  const present = rows.filter(r => r[col] != null);
  return present.length ? present.reduce((a, r) => a + r[col], 0) : null;
}

/** One line per logged week, newest first: the pipeline counts and the two
 *  install counts, each null when missing. */
export function weekly(rows) {
  const byWeek = new Map();
  for (const r of rows) { if (!byWeek.has(r.week_ending)) byWeek.set(r.week_ending, []); byWeek.get(r.week_ending).push(r); }
  return [...byWeek.entries()].sort((a, b) => (a[0] < b[0] ? 1 : -1)).map(([week, rs]) => ({
    week_ending: week,
    prospects_contacted: sumOrMissing(rs, 'prospects_contacted'),
    organizers_activated: sumOrMissing(rs, 'organizers_activated'),
    groups_playing: sumOrMissing(rs, 'groups_playing'),
    appstore_first_time_downloads: sumOrMissing(rs, 'appstore_first_time_downloads'),
    testflight_installs: sumOrMissing(rs, 'testflight_installs'),
    channels: [...new Set(rs.map(r => r.channel))],
  }));
}

/** The logged weekly subtotal of first-time App Store downloads for weeks ending
 *  on or before `through`, with how many of the expected weeks carry the number.
 *  A SUBTOTAL: it never decides a checkpoint. */
export function loggedSubtotal(rows, through) {
  const cov = coverage(rows, through, 'appstore_first_time_downloads');
  return { value: sumOrMissing(rows.filter(r => r.week_ending <= through), 'appstore_first_time_downloads'),
           weeksLogged: cov.logged.length, weeksExpected: cov.expected.length };
}

/** Logged first-time App Store downloads by channel, through `asOf` — subtotals. */
export function downloadsByChannel(rows, asOf) {
  const out = new Map();
  for (const r of rows) {
    if (r.week_ending > asOf || r.appstore_first_time_downloads == null) continue;
    const e = out.get(r.channel) || { downloads: 0, weeks: 0 };
    e.downloads += r.appstore_first_time_downloads; e.weeks += 1;
    out.set(r.channel, e);
  }
  return [...out.entries()].sort((a, b) => b[1].downloads - a[1].downloads).map(([channel, e]) => ({ channel, ...e }));
}

/** The cell rule: missing is "—", zero is "0". */
export function cell(v) { return v == null ? '—' : String(v); }

/** Everything the acquisition section says, as data (the runner's --json). */
export function acquisitionModel({ log, readings: rd, asOf, storeLive = null }) {
  const rows = log.rows, readings = rd.readings;
  const problems = [...log.problems.map(p => `log: ${p}`), ...rd.problems.map(p => `readings: ${p}`)];
  const contradiction = storeContradiction({ rows, readings, storeLive });
  const inconsistent = readingsInconsistency(readings);
  if (contradiction) problems.push(contradiction);
  if (inconsistent) problems.push(inconsistent);
  const blocked = contradiction ? 'contradictory input' : inconsistent ? 'inconsistent readings' : null;
  const checkpoints = checkpointTable(readings, asOf, { blocked })
    .map(c => ({ ...c, logged: loggedSubtotal(rows, c.on <= asOf ? c.on : asOf) }));
  return {
    asOf, storeLive, problems, checkpoints,
    coverage: coverage(rows, asOf), downloadsCoverage: coverage(rows, asOf, 'appstore_first_time_downloads'),
    weeks: weekly(rows), byChannel: downloadsByChannel(rows, asOf), readings,
    leftOut: { log: log.leftOutAfterAsOf || 0, readings: rd.leftOutAfterAsOf || 0 },
  };
}

const STATUS_WORDS = {
  met: 'met', missed: 'missed', open: 'open', unverified: 'unverified — needs an App Analytics reading through the date',
  'contradictory input': 'not judged — contradictory input', 'inconsistent readings': 'not judged — inconsistent readings',
};

/** Render the acquisition section as markdown lines. `webFirstEventByMonday`
 *  is the database's weekly count of accounts whose first event came from the
 *  web (a proxy, keyed by the ISO week's Monday); it is shown beside the store
 *  count and never added to it. */
export function renderAcquisition({ log, readings, asOf, webFirstEventByMonday = new Map(), storeLive = null }) {
  const m = acquisitionModel({ log, readings, asOf, storeLive });
  const L = [];
  L.push('## acquisition');
  L.push('');
  L.push('_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **accounts whose first event came from the web** (the database; a proxy, not a door). A — is missing; only a written 0 is zero._');
  L.push('');
  if (storeLive === false) { L.push('_`--store-live false`: the App Store listing is not live, so the store count is zero by definition until Apple approves._'); L.push(''); }
  if (storeLive == null) { L.push('_`--store-live` was not given: the report makes no claim about whether the listing is live._'); L.push(''); }
  if (m.problems.length) { L.push('**Input problems (the rows named were left out; nothing here was guessed):**'); for (const p of m.problems) L.push(`- ${p}`); L.push(''); }
  if (m.leftOut.log || m.leftOut.readings) { L.push(`_Left out as after the report date ${asOf}: ${m.leftOut.log} log row(s), ${m.leftOut.readings} reading(s)._`); L.push(''); }
  L.push('### checkpoints — cumulative first-time App Store downloads');
  L.push('');
  L.push('_Judged on dated App Analytics readings only: **met** when a reading on or before the date reached the target, **missed** when a reading on or after it (up to the report date) is still short. Weekly log totals are subtotals: they cannot say what happened before a mid-week date and never decide a checkpoint._');
  L.push('');
  L.push('| checkpoint | target | status | App Analytics reading | logged weekly subtotal (not a verified total) |');
  L.push('|---|---:|---|---|---|');
  for (const c of m.checkpoints) {
    const ev = c.evidence ? `${c.evidence.value.toLocaleString('en-US')} through ${c.evidence.through_date}` : '—';
    const sub = c.logged.weeksExpected ? `${cell(c.logged.value)} (${c.logged.weeksLogged} of ${c.logged.weeksExpected} weeks logged)` : '—';
    L.push(`| ${c.on} | ${c.target.toLocaleString('en-US')} | ${STATUS_WORDS[c.status]} | ${ev} | ${sub} |`);
  }
  L.push('');
  L.push('_Every acquisition assumption behind these checkpoints is unverified (launch plan §0). The checkpoints steer; they do not forecast. The October 15 review decides the channel mix, not the target._');
  L.push('');
  L.push('### the weekly log — logged subtotals');
  L.push('');
  const cov = m.coverage;
  L.push(cov.expected.length
    ? `_Weeks logged: ${cov.logged.length} of ${cov.expected.length} from ${cov.expected[0]} to ${cov.expected[cov.expected.length - 1]}${cov.missing.length ? `; not logged: ${cov.missing.join(', ')}` : ''}._`
    : `_No week is expected yet: the first counted week ends ${FIRST_EXPECTED_WEEK}._`);
  L.push('');
  L.push('| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads (logged) | TestFlight installs | accounts, first event on web (db, proxy) | channels |');
  L.push('|---|---:|---:|---:|---:|---:|---:|---|');
  if (!m.weeks.length) L.push('| — | — | — | — | — | — | — | no rows logged yet |');
  for (const w of m.weeks) {
    const mon = mondayOf(w.week_ending);
    const web = mon && webFirstEventByMonday.has(mon) ? webFirstEventByMonday.get(mon) : null;
    L.push(`| ${w.week_ending} | ${cell(w.prospects_contacted)} | ${cell(w.organizers_activated)} | ${cell(w.groups_playing)} | ${cell(w.appstore_first_time_downloads)} | ${cell(w.testflight_installs)} | ${cell(web)} | ${w.channels.join(', ')} |`);
  }
  L.push('');
  L.push('### by channel — logged subtotals, not verified totals');
  L.push('');
  L.push('| channel | first-time App Store downloads logged | weeks with a number |');
  L.push('|---|---:|---:|');
  if (!m.byChannel.length) L.push('| — | — | — |');
  for (const c of m.byChannel) L.push(`| ${c.channel} | ${c.downloads} | ${c.weeks} |`);
  L.push('');
  L.push('### App Analytics readings used');
  L.push('');
  L.push('| through | cumulative first-time downloads | source |');
  L.push('|---|---:|---|');
  if (!m.readings.length) L.push('| — | — | no reading recorded yet |');
  for (const r of m.readings) L.push(`| ${r.through_date} | ${r.value} | ${r.source || '—'} |`);
  L.push('');
  return { lines: L, model: m };
}
