#!/usr/bin/env node
/* Cup Season · the pilot scorecard and the weekly growth report. READ-ONLY.
   Runs tests/pilot/scorecard.sql and prints a markdown report (or --json).

   Targets (exactly one):
     node tools/pilot-scorecard.mjs              the linked project (supabase db query --linked; SELECT only)
     node tools/pilot-scorecard.mjs --sandbox    the local sandbox (psql over /tmp/cs-sim-sock:5478; --db NAME
                                                 picks the database, CS_PG_BIN the psql directory)
     node tools/pilot-scorecard.mjs --no-db      the acquisition inputs alone; every database section says so

   The reporting cutoff (W6 correction 3) — ONE date and ONE zone for every section:
     --as-of YYYY-MM-DD   the report date (default: today in --tz). A real calendar date, and never
                          later than today: a report is written from what had been observed by then.
     --tz ZONE            an IANA zone (default America/Phoenix). Weeks are that zone's Monday weeks,
                          and the cutoff is the first instant after --as-of in that zone.
   Acquisition inputs (docs/pilot/acquisition-log.md says what goes in each):
     --csv PATH           the weekly log            (default docs/pilot/acquisition-log.csv)
     --readings PATH      dated App Analytics readings (default docs/pilot/appstore-readings.csv)
     --store-live true|false   whether the App Store listing is live; exactly one of the two words
   Other:
     --json               machine-readable output (sections, the acquisition model)
     --synthetic          a FIXTURE run: allowed only with --sandbox or --no-db, labels the report
                          SYNTHETIC in its title, and permits a report date after today (fixtures are
                          dated in the launch window). Never a measurement.

   The report is the founder's, read through the project's postgres role; it is never a client
   surface and never writes. Invalid input exits 2 with one sentence; it never crashes. */
import { readFileSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { parseAcquisitionCsv, parseReadingsCsv, renderAcquisition, parseStoreLive, isRealDate } from './lib/growth-report.mjs';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..');

function die(msg) { console.error(`pilot-scorecard: ${msg}`); process.exit(2); }

// ── flags, strictly ─────────────────────────────────────────────────────────
const VALUE_FLAGS = new Set(['as-of', 'tz', 'csv', 'readings', 'store-live', 'db']);
const BOOL_FLAGS = new Set(['sandbox', 'no-db', 'json', 'synthetic']);
const opts = {};
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (!a.startsWith('--')) die(`unexpected argument "${a}"`);
  const name = a.slice(2);
  if (BOOL_FLAGS.has(name)) { opts[name] = true; continue; }
  if (!VALUE_FLAGS.has(name)) die(`unknown flag --${name}`);
  const v = argv[i + 1];
  if (v == null || v.startsWith('--')) die(`--${name} needs a value`);
  if (name in opts) die(`--${name} was given twice`);
  opts[name] = v; i++;
}
if (opts.sandbox && opts['no-db']) die('choose one target: --sandbox or --no-db');
if (opts.synthetic && !(opts.sandbox || opts['no-db'])) die('--synthetic is for fixture runs only: add --sandbox or --no-db (never the linked project)');
if (opts.db && !opts.sandbox) die('--db names a sandbox database; add --sandbox');
if (opts.db && !/^[a-z_][a-z0-9_]{0,62}$/.test(opts.db)) die(`--db "${opts.db}" is not a plain database name`);

const tz = opts.tz ?? 'America/Phoenix';
if (!/^[A-Za-z]+(?:[/_+-][A-Za-z0-9]+)*$/.test(tz)) die(`--tz "${tz}" is not an IANA zone name`);
try { new Intl.DateTimeFormat('en-US', { timeZone: tz }); } catch { die(`--tz "${tz}" is not a zone this runtime knows`); }
const todayIn = new Intl.DateTimeFormat('en-CA', { timeZone: tz, year: 'numeric', month: '2-digit', day: '2-digit' }).format(new Date());
const asOf = opts['as-of'] ?? todayIn;
if (!isRealDate(asOf)) die(`--as-of "${asOf}" is not a real calendar date (YYYY-MM-DD)`);
if (asOf > todayIn && !opts.synthetic) die(`--as-of ${asOf} is after today (${todayIn} in ${tz}) — a report is written from what has been observed, not dated ahead`);
let storeLive = null;
if ('store-live' in opts) { try { storeLive = parseStoreLive(opts['store-live']); } catch (e) { die(e.message); } }
for (const k of ['csv', 'readings']) if (opts[k] && !existsSync(opts[k])) die(`--${k} ${opts[k]} does not exist`);
const csvPath = opts.csv ?? join(root, 'docs', 'pilot', 'acquisition-log.csv');
const readingsPath = opts.readings ?? join(root, 'docs', 'pilot', 'appstore-readings.csv');
const target = opts['no-db'] ? 'none' : opts.sandbox ? 'sandbox' : 'linked';
const pgBin = process.env.CS_PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
const db = opts.db || 'cupseason';

// ── the SQL, its fragments and its sections ─────────────────────────────────
const sql = readFileSync(join(root, 'tests', 'pilot', 'scorecard.sql'), 'utf8');
const fragments = {};
for (const m of sql.matchAll(/^-- fragment: (\w+)\n([\s\S]*?)^-- end fragment$/gm)) {
  fragments[m[1]] = m[2].split('\n').filter(l => !/^\s*--/.test(l)).join('\n').trim();
}
const lit = s => `'${s.replace(/'/g, "''")}'`;
const cutoffSql = `((DATE ${lit(asOf)} + 1)::timestamp at time zone ${lit(tz)})`;
const weeksSql = `select (date_trunc('week', (DATE ${lit(asOf)})::timestamp) - n * interval '1 week')::date as week,
         least((date_trunc('week', (DATE ${lit(asOf)})::timestamp) - n * interval '1 week')::date + 6, DATE ${lit(asOf)}) as through
    from generate_series(0, 7) n`;
function substitute(text, cohortTable) {
  const cohortRows = cohortTable
    ? 'select pcm.profile_id, pcm.cohort, pcm.group_key from public.pilot_cohort_members pcm where pcm.added_at < :CUTOFF'
    : "select e.profile_id, 'all'::text as cohort, null::text as group_key from (:ELIGIBLE) e";
  return text
    .replace(/:COHORT_ROWS\b/g, cohortRows)
    .replace(/:REAL_GAMES\b/g, fragments.REAL_GAMES)
    .replace(/:ELIGIBLE\b/g, fragments.ELIGIBLE)
    .replace(/:PARTICIPANTS\b/g, fragments.PARTICIPANTS)
    .replace(/:WEEKS\b/g, weeksSql)
    .replace(/:CUTOFF\b/g, cutoffSql)
    .replace(/:AS_OF\b/g, `DATE ${lit(asOf)}`)
    .replace(/:TZ\b/g, lit(tz));
}
const sections = sql.split(/^-- name: /m).slice(1).map(chunk => {
  const lines = chunk.split('\n');
  const nameLine = lines.shift().trim();
  const pilotOnly = /@pilot\b/.test(nameLine);
  const name = nameLine.replace(/\s*@pilot\b/, '').trim();
  let empty = null, note = null;
  while (lines.length && /^--/.test(lines[0])) {
    const l = lines.shift();
    const e = l.match(/^-- empty: (.*)$/); if (e) empty = e[1];
    const n = l.match(/^-- note: (.*)$/); if (n) note = n[1];
  }
  const body = lines.join('\n').split(/^-- ── |^-- ═══ /m)[0].trim().replace(/;\s*$/, '');
  return { name, pilotOnly, empty, note, body };
});

const NULL = '␀';
function query(text) {
  if (!/^\s*(with|select)\b/i.test(text)) throw new Error('the scorecard runs SELECT only');
  if (target === 'sandbox') {
    const out = execFileSync(join(pgBin, 'psql'),
      ['-h', '/tmp/cs-sim-sock', '-p', '5478', '-U', 'postgres', '-d', db, '-X', '-q', '-A', '-F', '\t', '-P', `null=${NULL}`, '-v', 'ON_ERROR_STOP=1', '-c', text],
      { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
    const lines = out.replace(/\n$/, '').split('\n').filter(l => l !== '' && !/^\(\d+ rows?\)$/.test(l));
    const header = (lines.shift() || '').split('\t');
    return { header, rows: lines.map(l => l.split('\t').map(v => (v === NULL ? null : v))) };
  }
  const out = execFileSync('supabase', ['db', 'query', '--linked', '--output-format', 'text', text], { encoding: 'utf8' });
  const json = JSON.parse(out.slice(out.indexOf('{')));
  const rows = json.rows || [];
  return { header: rows.length ? Object.keys(rows[0]) : [], rows: rows.map(r => Object.values(r).map(v => (v == null ? null : String(v)))) };
}

// ── run ─────────────────────────────────────────────────────────────────────
let cohortTable = false;
if (target !== 'none') {
  try {
    const r = query("select (to_regclass('public.pilot_cohort_members') is not null and to_regclass('public.pilot_sessions') is not null)::text as present");
    cohortTable = r.rows[0]?.[0] === 'true';
  } catch (e) { die(`could not reach the database: ${String(e.message).split('\n').find(l => /error|refused|could not/i.test(l)) || String(e.message).split('\n')[0]}`); }
}

const results = {};
let failed = 0;
for (const s of sections) {
  if (target === 'none') { results[s.name] = { skipped: 'not read: no database in this run' }; continue; }
  if (s.pilotOnly && !cohortTable) { results[s.name] = { skipped: 'skipped: needs the pilot record (20261106090000)' }; continue; }
  try { results[s.name] = query(substitute(s.body, cohortTable)); }
  catch (e) { failed++; results[s.name] = { error: String(e.message).split('\n').find(l => /ERROR/.test(l)) || String(e.message).split('\n')[0] }; }
}

// the web first-event proxy, keyed by the week's Monday, shown beside (never added to) the store count
const webFirstEventByMonday = new Map();
const sf = results.signups_first_event_platform;
if (sf && sf.rows) {
  const wi = sf.header.indexOf('week'), ci = sf.header.indexOf('first_event_web');
  for (const r of sf.rows) webFirstEventByMonday.set(r[wi], Number(r[ci]));
}
const readText = p => { try { return readFileSync(p, 'utf8'); } catch { return null; } };
const logText = existsSync(csvPath) ? readText(csvPath) : null;
const readingsText = existsSync(readingsPath) ? readText(readingsPath) : null;
const log = logText == null ? { rows: [], problems: [`no acquisition log at ${csvPath} — the owner keeps it (docs/pilot/acquisition-log.md)`], leftOutAfterAsOf: 0 }
                            : parseAcquisitionCsv(logText, { asOf });
const readings = readingsText == null ? { readings: [], problems: [`no App Analytics readings at ${readingsPath} — the owner records them (docs/pilot/acquisition-log.md)`], leftOutAfterAsOf: 0 }
                                      : parseReadingsCsv(readingsText, { asOf });
const acq = renderAcquisition({ log, readings, asOf, webFirstEventByMonday, storeLive });

if (opts.json) {
  console.log(JSON.stringify({ asOf, tz, today: todayIn, target, synthetic: !!opts.synthetic, cohortTable,
    sections: results, acquisition: acq.model }, null, 1));
  process.exit(failed ? 1 : 0);
}

const L = [];
const where = target === 'none' ? 'NO DATABASE (the acquisition inputs alone)' : target === 'sandbox' ? `SANDBOX (${db}, local, disposable)` : 'linked project (read-only)';
L.push(`# ${opts.synthetic ? 'SYNTHETIC — fixture data, not a measurement · ' : ''}Pilot scorecard and weekly growth report · ${asOf} · ${where}`);
L.push('');
if (opts.synthetic) { L.push('> **SYNTHETIC.** Every number below comes from fixture rows and fixture files written to exercise the report. None of it was observed. Do not read it as progress, and do not copy it into a real report.'); L.push(''); }
L.push(`_Reporting cutoff: everything before the end of **${asOf}** in **${tz}**; weeks are ${tz} Monday weeks, and the report date's own week is partial (its \`through\` column says to which day). Run on ${todayIn}._`);
L.push('');
L.push(target === 'none'
  ? '_**No database was read in this run.** Every database section says so; nothing here is a zero._'
  : cohortTable
  ? '_Cohorts come from `pilot_cohort_members` (added before the cutoff); assisted activity from `pilot_sessions`._'
  : '_**The pilot record (20261106090000) is not on this database.** Every eligible golfer is reported as one cohort named `all`; the `@pilot` sections are skipped._');
L.push('');
for (const s of sections) {
  const r = results[s.name];
  L.push(`## ${s.name}`); L.push('');
  if (s.note) { L.push(`_${s.note}_`); L.push(''); }
  if (r.skipped) { L.push(`_${r.skipped}_`); L.push(''); continue; }
  if (r.error) { L.push(`_query failed: ${r.error}_`); L.push(''); continue; }
  if (!r.rows.length) { L.push(`_${s.empty || 'no rows by the cutoff'}_`); L.push(''); continue; }
  if (r.header.some(h => /_now$/.test(h))) {
    L.push(`_Columns ending \`_now\` are the state when this report ran (${todayIn}), not at the cutoff — the schema keeps no history for them.${asOf < todayIn ? ' This report is backdated, so read them as current state.' : ''}_`);
    L.push('');
  }
  L.push('| ' + r.header.join(' | ') + ' |');
  L.push('|' + r.header.map(() => '---').join('|') + '|');
  for (const row of r.rows) L.push('| ' + row.map(v => (v == null ? '—' : v)).join(' | ') + ' |');
  L.push('');
}
L.push(...acq.lines);
L.push('## Known measurement gaps');
L.push('');
L.push('- Founder assistance is what `pilot_sessions` says and nothing else; an unlogged phone call is invisible. A session with no end time, or with no golfers and no resolvable group, makes the games it overlaps UNKNOWN — never unassisted.');
L.push('- `clash_seen` is exposure. It says a clash was on screen, not that anyone valued it. `receipt_viewed` is the nearest interaction fact.');
L.push('- "One round, quiet 3 weeks" is not churn. Golf is intermittent; read it against the season calendar and the weather.');
L.push('- Client events are attempts and failures only; every success is read from the product tables. A device that never reached the network reports nothing.');
L.push('- Counts under about 10 are printed as counts. No percentage here is statistically conclusive at pilot size.');
L.push('- The eligible population excludes the founder, deleted accounts, the App Review account and test-seed bots — defined once, applied to every account and round count. A real game is one outside sandbox leagues with at least one eligible golfer, the same rule in every game count; only the integrity checks watch every live round.');
L.push('- A guest seat is a seat with no membership and no account at play. Every seat carries a claim token by default, so a token alone never makes a guest.');
L.push('- The first-event platform is a proxy: the first event can follow sign-up by days and come from the other client. An account is not an install, and none is a first-time App Store download.');
L.push('- `attributed_to_a_link` is written by `log_growth_event` on `profile_created`; a blank means no attribution was observed (a direct arrival, a seeded account, or a signup before the writer shipped on 2026-08-29), not a broken writer.');
L.push('- The store count is what the owner recorded from App Store Connect and nothing else; a checkpoint is judged only on a dated App Analytics reading.');
console.log(L.join('\n'));
process.exit(failed ? 1 : 0);
