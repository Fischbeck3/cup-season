// Cup Season · the acquisition half of the weekly growth report (W6).
//
// Pure functions, no I/O, tested by tests/growth-report.test.mjs. The runner
// (tools/pilot-scorecard.mjs) reads the owner's acquisition log — a CSV of
// COUNTS, never names — and prints it beside the database sections. Three
// numbers are kept apart and never summed: first-time App Store downloads
// (App Store Connect → App Analytics, the checkpoint metric), TestFlight
// installs (App Store Connect → TestFlight) and web sign-ups (the database).
// A week with no row is MISSING and prints as "—"; only a row that says 0
// prints 0.

export const CHECKPOINTS = [
  { on: '2026-10-31', downloads: 500 },
  { on: '2026-11-30', downloads: 2000 },
  { on: '2026-12-31', downloads: 5000 },
];

export const COLUMNS = ['week_ending', 'channel', 'prospects_contacted', 'organizers_activated',
  'groups_playing', 'appstore_first_time_downloads', 'testflight_installs', 'notes'];

const COUNT_COLUMNS = COLUMNS.slice(2, 7);

/** Parse the CSV. Header row required; blank cells are null (missing), "0" is
 *  zero. Returns { rows, problems } — a malformed row is reported, not summed. */
export function parseAcquisitionCsv(text) {
  const lines = String(text || '').split(/\r?\n/).filter(l => l.trim() !== '');
  const problems = [];
  if (!lines.length) return { rows: [], problems: ['the log is empty'] };
  const header = lines[0].split(',').map(h => h.trim());
  const missing = COLUMNS.filter(c => !header.includes(c));
  if (missing.length) return { rows: [], problems: [`header is missing: ${missing.join(', ')}`] };
  const rows = [];
  lines.slice(1).forEach((line, i) => {
    const cells = splitCsv(line);
    const rec = {};
    header.forEach((h, j) => { rec[h] = (cells[j] ?? '').trim(); });
    if (!/^\d{4}-\d{2}-\d{2}$/.test(rec.week_ending)) { problems.push(`row ${i + 2}: week_ending "${rec.week_ending}" is not YYYY-MM-DD`); return; }
    for (const c of COUNT_COLUMNS) {
      if (rec[c] === '') { rec[c] = null; continue; }
      const n = Number(rec[c]);
      if (!Number.isInteger(n) || n < 0) { problems.push(`row ${i + 2}: ${c} "${rec[c]}" is not a whole number`); return; }
      rec[c] = n;
    }
    rec.channel = rec.channel || 'unattributed';
    rows.push(rec);
  });
  return { rows, problems };
}

function splitCsv(line) {
  const out = []; let cur = ''; let q = false;
  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (q) { if (ch === '"' && line[i + 1] === '"') { cur += '"'; i++; } else if (ch === '"') { q = false; } else cur += ch; }
    else if (ch === '"') q = true;
    else if (ch === ',') { out.push(cur); cur = ''; }
    else cur += ch;
  }
  out.push(cur);
  return out;
}

/** Sum a column across a week's rows; null when EVERY row is missing it. */
function sumOrMissing(rows, col) {
  const present = rows.filter(r => r[col] != null);
  return present.length ? present.reduce((a, r) => a + r[col], 0) : null;
}

/** One line per week (newest first): the four pipeline counts and the two
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

/** First-time App Store downloads by channel, cumulative to `asOf`. */
export function downloadsByChannel(rows, asOf) {
  const out = new Map();
  for (const r of rows) {
    if (r.week_ending > asOf || r.appstore_first_time_downloads == null) continue;
    out.set(r.channel, (out.get(r.channel) || 0) + r.appstore_first_time_downloads);
  }
  return [...out.entries()].sort((a, b) => b[1] - a[1]).map(([channel, downloads]) => ({ channel, downloads }));
}

/** Cumulative first-time App Store downloads through `asOf`. null when no row
 *  through that date carries the number — missing, not zero. */
export function cumulativeDownloads(rows, asOf) {
  const counted = rows.filter(r => r.week_ending <= asOf && r.appstore_first_time_downloads != null);
  if (!counted.length) return null;
  return counted.reduce((a, r) => a + r.appstore_first_time_downloads, 0);
}

/** The checkpoint table. A checkpoint in the past is met or missed on the
 *  cumulative count through its date; one in the future shows the count so
 *  far and the gap, and says nothing about a forecast — the checkpoints
 *  steer, they do not forecast (launch plan §0). */
export function checkpointTable(rows, asOf) {
  return CHECKPOINTS.map(cp => {
    const through = cumulativeDownloads(rows, cp.on <= asOf ? cp.on : asOf);
    const status = through == null ? 'missing'
      : cp.on <= asOf ? (through >= cp.downloads ? 'met' : 'missed')
      : 'open';
    return { on: cp.on, target: cp.downloads, cumulative: through, gap: through == null ? null : Math.max(0, cp.downloads - through), status };
  });
}

/** The cell rule: missing is "—", zero is "0". */
export function cell(v) { return v == null ? '—' : String(v); }

/** Render the acquisition section as markdown lines. `webSignups` is the
 *  database's weekly web sign-up count (from `signups_by_door`), keyed by the
 *  ISO week's Monday; it is shown beside the store count and never added to it. */
export function renderAcquisition({ rows, problems, asOf, webSignupsByWeek = new Map(), storeLive = null }) {
  const L = [];
  L.push('## acquisition');
  L.push('');
  L.push('_Three numbers, kept apart and never summed: **first-time App Store downloads** (App Store Connect → App Analytics; the checkpoint metric), **TestFlight installs** (App Store Connect → TestFlight) and **web sign-ups** (the database, `signups_by_door`). A blank cell in the log is **missing** and prints as —; only a logged 0 prints 0._');
  L.push('');
  if (storeLive === false) L.push('_The App Store listing is not live: the store count is zero by definition until Apple approves, and a — here means the week was not logged, not that nothing happened._'), L.push('');
  if (problems.length) { L.push('**Log problems (rows left out):**'); for (const p of problems) L.push(`- ${p}`); L.push(''); }
  const cps = checkpointTable(rows, asOf);
  L.push('| checkpoint | target | cumulative first-time downloads | gap | status |');
  L.push('|---|---:|---:|---:|---|');
  for (const c of cps) L.push(`| ${c.on} | ${c.target.toLocaleString('en-US')} | ${cell(c.cumulative)} | ${cell(c.gap)} | ${c.status} |`);
  L.push('');
  L.push('_Every acquisition assumption behind these checkpoints is unverified (launch plan §0); the first two weeks of App Analytics set the real rate, and the October 15 review decides the channel mix, not the target._');
  L.push('');
  const wk = weekly(rows);
  L.push('| week ending | prospects contacted | organizers activated | groups playing | first-time App Store downloads | TestFlight installs | web sign-ups (db) | channels |');
  L.push('|---|---:|---:|---:|---:|---:|---:|---|');
  if (!wk.length) L.push('| — | — | — | — | — | — | — | no rows logged yet |');
  for (const w of wk) {
    const web = webSignupsByWeek.has(w.week_ending) ? webSignupsByWeek.get(w.week_ending) : null;
    L.push(`| ${w.week_ending} | ${cell(w.prospects_contacted)} | ${cell(w.organizers_activated)} | ${cell(w.groups_playing)} | ${cell(w.appstore_first_time_downloads)} | ${cell(w.testflight_installs)} | ${cell(web)} | ${w.channels.join(', ')} |`);
  }
  L.push('');
  const byCh = downloadsByChannel(rows, asOf);
  L.push('| channel | first-time App Store downloads to date |');
  L.push('|---|---:|');
  if (!byCh.length) L.push('| — | — |');
  for (const c of byCh) L.push(`| ${c.channel} | ${c.downloads} |`);
  L.push('');
  return L;
}

/** The week-ending (Sunday) for an ISO date, and the ISO week's Monday for a
 *  week-ending date — so the log's Sundays line up with the database's Mondays. */
export function mondayOf(weekEnding) {
  const d = new Date(weekEnding + 'T00:00:00Z');
  const dow = d.getUTCDay();                 // 0 = Sunday
  const back = dow === 0 ? 6 : dow - 1;      // Monday of the same ISO week
  d.setUTCDate(d.getUTCDate() - back);
  return d.toISOString().slice(0, 10);
}
