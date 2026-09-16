#!/usr/bin/env node
/* Cup Season · the pilot scorecard.
   Runs tests/pilot/scorecard.sql READ-ONLY and prints a markdown report by
   cohort and group. Two targets:
     node tools/pilot-scorecard.mjs            → the linked project (supabase db query --linked; SELECT only)
     node tools/pilot-scorecard.mjs --sandbox  → the local sandbox (psql, /tmp/cs-sim-sock:5478)
   The scorecard is the FOUNDER'S report, read the way the founder desk reads —
   through the project's postgres role — and is never a client surface. It
   never writes. If the pilot tables (20261106090000) are absent it says so and
   reports every golfer as one cohort named "all". */
import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const here = dirname(fileURLToPath(import.meta.url));
const sql = readFileSync(join(here, '..', 'tests', 'pilot', 'scorecard.sql'), 'utf8');
const sandbox = process.argv.includes('--sandbox');

function query(text) {
  if (!/^\s*(with|select)\b/i.test(text)) throw new Error('the scorecard runs SELECT only');
  if (sandbox) {
    const out = execFileSync('/opt/homebrew/opt/postgresql@17/bin/psql',
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
try {
  const r = query("select (to_regclass('public.pilot_cohort_members') is not null and to_regclass('public.pilot_sessions') is not null) as present;");
  cohortTable = /^t/i.test((r.rows[0] || [''])[0]);
} catch (e) { console.error('could not reach the database:', String(e.message).split('\n')[0]); process.exit(2); }

const sections = sql.split(/^-- name: /m).slice(1).map(chunk => {
  const nl = chunk.indexOf('\n');
  const name = chunk.slice(0, nl).trim();
  const cohortRows = cohortTable
    ? "select pcm.profile_id, pcm.cohort, pcm.group_key from public.pilot_cohort_members pcm"
    : "select p.id as profile_id, 'all' as cohort, null::text as group_key from public.profiles p";
  const body = chunk.slice(nl + 1).split(/^-- ── /m)[0]
    .replace(/:COHORT_ROWS/g, cohortRows)
    .replace(/:ASSISTED_SESSIONS/g, cohortTable ? "(select count(*) from public.pilot_sessions where kind = 'assisted')" : "0")
    .replace(/:SUPPORT_SESSIONS/g, cohortTable ? "(select count(*) from public.pilot_sessions where kind = 'support')" : "0");
  return { name, body: body.trim().replace(/;\s*$/, '') };
});

const lines = [];
lines.push(`# Pilot scorecard · ${new Date().toISOString().slice(0, 10)} · ${sandbox ? 'SANDBOX (local, disposable)' : 'linked project (read-only)'}`);
lines.push('');
lines.push(cohortTable
  ? '_Cohorts come from `pilot_cohort_members`; assisted activity from `pilot_sessions`._'
  : '_**The pilot record (20261106090000) is not on this database.** Every golfer is reported as one cohort named `all`; founder assistance cannot be subtracted. Apply the migration and name the cohorts before reading these numbers as pilot evidence._');
lines.push('');
let failed = 0;
for (const s of sections) {
  let res;
  try { res = query(s.body); }
  catch (e) { failed++; lines.push(`## ${s.name}\n\n_query failed: ${String(e.message).split('\n').find(l => /ERROR/.test(l)) || String(e.message).split('\n')[0]}_\n`); continue; }
  lines.push(`## ${s.name}`); lines.push('');
  if (!res.rows.length) { lines.push('_no rows_'); lines.push(''); continue; }
  lines.push('| ' + res.header.join(' | ') + ' |');
  lines.push('|' + res.header.map(() => '---').join('|') + '|');
  for (const r of res.rows) lines.push('| ' + r.join(' | ') + ' |');
  lines.push('');
}
lines.push('## Known measurement gaps');
lines.push('');
lines.push('- Founder assistance is what `pilot_sessions` says and nothing else; an unlogged phone call is invisible.');
lines.push('- `clash_seen` is exposure. It says a clash was on screen, not that anyone valued it. `receipt_viewed` is the nearest interaction fact.');
lines.push('- "One round, quiet 3 weeks" is not churn. Golf is intermittent; read it against the season calendar and the weather.');
lines.push('- Client events are attempts and failures only; every success is read from the product tables. A device that never reached the network reports nothing.');
lines.push('- Counts under about 10 are printed as counts. No percentage here is statistically conclusive at pilot size.');
lines.push('- Leagues flagged `sandbox` and the founder\'s own profile are excluded from every cohort but `owner`.');
console.log(lines.join('\n'));
process.exit(failed ? 1 : 0);
