#!/usr/bin/env node
/* Cup Season · the pilot scorecard and, since W6, the weekly growth report.
   Runs tests/pilot/scorecard.sql READ-ONLY and prints a markdown report by
   cohort and group. Targets:
     node tools/pilot-scorecard.mjs            → the linked project (supabase db query --linked; SELECT only)
     node tools/pilot-scorecard.mjs --sandbox  → the local sandbox (psql, /tmp/cs-sim-sock:5478; CS_PG_BIN overrides the psql dir)
     node tools/pilot-scorecard.mjs --no-db    → the acquisition section alone, from the log (no database in reach)
   Flags: --csv <path> (the owner's acquisition log; default docs/pilot/acquisition-log.csv)
          --as-of YYYY-MM-DD (the report date; default today)
          --store-live true|false (the App Store listing's state; before approval the store count is zero by definition)
   The scorecard is the FOUNDER'S report, read the way the founder desk reads —
   through the project's postgres role — and is never a client surface. It
   never writes. If the pilot tables (20261106090000) are absent it says so,
   reports every golfer as one cohort named "all", and skips the sections
   marked `@pilot`. Three acquisition numbers are kept apart and never summed:
   first-time App Store downloads (App Store Connect, from the log), TestFlight
   installs (the log) and web sign-ups (the database). Missing stays missing. */
import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseAcquisitionCsv, renderAcquisition, mondayOf } from './lib/growth-report.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const sql = readFileSync(join(here, '..', 'tests', 'pilot', 'scorecard.sql'), 'utf8');
const argv = process.argv.slice(2);
const flag = (name, fallback = null) => { const i = argv.indexOf('--' + name); return i >= 0 && i + 1 < argv.length ? argv[i + 1] : fallback; };
const sandbox = argv.includes('--sandbox');
const noDb = argv.includes('--no-db');
const csvPath = flag('csv', join(here, '..', 'docs', 'pilot', 'acquisition-log.csv'));
const asOf = flag('as-of', new Date().toISOString().slice(0, 10));
const storeLiveFlag = flag('store-live', null);
const storeLive = storeLiveFlag == null ? null : /^t/i.test(storeLiveFlag);
const pgBin = process.env.CS_PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';

function query(text) {
  if (!/^\s*(with|select)\b/i.test(text)) throw new Error('the scorecard runs SELECT only');
  if (noDb) throw new Error('no database in this run (--no-db)');
  if (sandbox) {
    const out = execFileSync(join(pgBin, 'psql'),
      ['-h', '/tmp/cs-sim-sock', '-p', '5478', '-U', 'postgres', '-d', 'cupseason', '-X', '-q', '-A', '-F', '\t', '-c', text], { encoding: 'utf8' });
    const lines = out.trim().split('\n').filter(l => l && !/^\(\d+ rows?\)$/.test(l));
    const header = (lines.shift() || '').split('\t');
    return { header, rows: lines.map(l => l.split('\t')) };
  }
  const out = execFileSync('supabase', ['db', 'query', '--linked', '--output-format', 'text', text], { encoding: 'utf8' });
  const json = JSON.parse(out.slice(out.indexOf('{')));
  const rows = json.rows || [];
  return { header: rows.length ? Object.keys(rows[0]) : [], rows: rows.map(r => Object.values(r).map(v => v == null ? '' : String(v))) };
}

let cohortTable = false;
if (!noDb) {
  try {
    const r = query("select (to_regclass('public.pilot_cohort_members') is not null and to_regclass('public.pilot_sessions') is not null) as present;");
    cohortTable = /^t/i.test((r.rows[0] || [''])[0]);
  } catch (e) { console.error('could not reach the database:', String(e.message).split('\n')[0]); process.exit(2); }
}

const sections = sql.split(/^-- name: /m).slice(1).map(chunk => {
  const nl = chunk.indexOf('\n');
  const nameLine = chunk.slice(0, nl).trim();
  const pilotOnly = /@pilot\b/.test(nameLine);
  const name = nameLine.replace(/\s*@pilot\b/, '').trim();
  const cohortRows = cohortTable
    ? "select pcm.profile_id, pcm.cohort, pcm.group_key from public.pilot_cohort_members pcm"
    : "select p.id as profile_id, 'all' as cohort, null::text as group_key from public.profiles p";
  const body = chunk.slice(nl + 1).split(/^-- ── /m)[0]
    .replace(/:COHORT_ROWS/g, cohortRows)
    .replace(/:ASSISTED_SESSIONS/g, cohortTable ? "(select count(*) from public.pilot_sessions where kind = 'assisted')" : "0")
    .replace(/:SUPPORT_SESSIONS/g, cohortTable ? "(select count(*) from public.pilot_sessions where kind = 'support')" : "0");
  return { name, pilotOnly, body: body.trim().replace(/;\s*$/, '') };
});

const lines = [];
lines.push(`# Pilot scorecard and weekly growth report · ${asOf} · ${noDb ? 'NO DATABASE (the log alone)' : sandbox ? 'SANDBOX (local, disposable)' : 'linked project (read-only)'}`);
lines.push('');
lines.push(noDb
  ? '_**No database was read in this run.** Every database section below says so; nothing here is a zero._'
  : cohortTable
  ? '_Cohorts come from `pilot_cohort_members`; assisted activity from `pilot_sessions`._'
  : '_**The pilot record (20261106090000) is not on this database.** Every golfer is reported as one cohort named `all`; founder assistance cannot be subtracted; the `@pilot` sections are skipped. Apply the migration and name the cohorts before reading these numbers as pilot evidence._');
lines.push('');
let failed = 0;
const webSignupsByWeek = new Map();   // the database's weekly web sign-ups, shown beside the store count and never summed into it
for (const s of sections) {
  if (noDb) { lines.push(`## ${s.name}\n\n_not read: no database in this run_\n`); continue; }
  if (s.pilotOnly && !cohortTable) { lines.push(`## ${s.name}\n\n_skipped: needs the pilot record (20261106090000)_\n`); continue; }
  let res;
  try { res = query(s.body); }
  catch (e) { failed++; lines.push(`## ${s.name}\n\n_query failed: ${String(e.message).split('\n').find(l => /ERROR/.test(l)) || String(e.message).split('\n')[0]}_\n`); continue; }
  lines.push(`## ${s.name}`); lines.push('');
  if (!res.rows.length) { lines.push('_no rows_'); lines.push(''); continue; }
  lines.push('| ' + res.header.join(' | ') + ' |');
  lines.push('|' + res.header.map(() => '---').join('|') + '|');
  for (const r of res.rows) lines.push('| ' + r.join(' | ') + ' |');
  lines.push('');
  if (s.name === 'signups_by_door') {
    const wi = res.header.indexOf('week'), ci = res.header.indexOf('web_signups');
    if (wi >= 0 && ci >= 0) for (const r of res.rows) webSignupsByWeek.set(r[wi], Number(r[ci]));
  }
}

// ── the acquisition section: the owner's log, read beside the database, never summed with it
const byMonday = new Map();
for (const [monday, n] of webSignupsByWeek) byMonday.set(monday, n);
const logText = existsSync(csvPath) ? readFileSync(csvPath, 'utf8') : '';
const parsed = existsSync(csvPath) ? parseAcquisitionCsv(logText) : { rows: [], problems: [`no acquisition log at ${csvPath} — the owner keeps it (docs/pilot/acquisition-log.md)`] };
const webForLog = new Map();
for (const r of parsed.rows) { const m = mondayOf(r.week_ending); if (byMonday.has(m)) webForLog.set(r.week_ending, byMonday.get(m)); }
lines.push(...renderAcquisition({ rows: parsed.rows, problems: parsed.problems, asOf, webSignupsByWeek: webForLog, storeLive }));
lines.push('## Known measurement gaps');
lines.push('');
lines.push('- Founder assistance is what `pilot_sessions` says and nothing else; an unlogged phone call is invisible.');
lines.push('- `clash_seen` is exposure. It says a clash was on screen, not that anyone valued it. `receipt_viewed` is the nearest interaction fact.');
lines.push('- "One round, quiet 3 weeks" is not churn. Golf is intermittent; read it against the season calendar and the weather.');
lines.push('- Client events are attempts and failures only; every success is read from the product tables. A device that never reached the network reports nothing.');
lines.push('- Counts under about 10 are printed as counts. No percentage here is statistically conclusive at pilot size.');
lines.push('- Leagues flagged `sandbox` and the founder\'s own profile are excluded from every cohort but `owner`.');
lines.push('- The store count is what the owner copied from App Store Connect into the log that week and nothing else; a week not logged is missing, not zero. TestFlight installs and web sign-ups are never added to it.');
lines.push('- `signups_by_door` reads the first client event\'s platform; an account whose first event never reached the network is `unknown`, and a phone sign-up is an account, not an install.');
console.log(lines.join('\n'));
process.exit(failed ? 1 : 0);
