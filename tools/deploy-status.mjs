#!/usr/bin/env node
/* Cup Season — what do I owe a deploy?
 *
 * Three deploys, three different systems, and they are INDEPENDENT. Conflating
 * them cost 14 undeployed client versions early on, so this always reports all
 * three separately, even when only one is owed:
 *
 *   DATABASE        supabase db push                 (migrations)
 *   EDGE FUNCTIONS  supabase functions deploy <name>
 *   CLIENT          merge to main -> Netlify builds  (index.html / sw.js)
 *
 *   node tools/deploy-status.mjs           full report
 *   node tools/deploy-status.mjs --quiet   silent when clean (the Stop hook)
 *   node tools/deploy-status.mjs --json    machine-readable (ship.sh)
 *   node tools/deploy-status.mjs --hook    {"systemMessage"} for a Stop hook,
 *                                          and TOTAL silence when nothing is owed
 *
 * The Supabase CLI is NOT in every environment this runs in — a remote Claude
 * session has no `supabase` binary at all. Anything needing it degrades to
 * "unknown" and SAYS SO. It never reports clean because it could not look:
 * a false all-clear is worse than no answer.                                */

import { readdirSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { join } from 'node:path';

const root = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const quiet = process.argv.includes('--quiet');
const asJson = process.argv.includes('--json');
const asHook = process.argv.includes('--hook');

const run = (cmd, args, ms = 20000) => {
  try { return execFileSync(cmd, args, { cwd: root, encoding: 'utf8', timeout: ms, stdio: ['ignore', 'pipe', 'pipe'] }).trim(); }
  catch { return null; }
};
const haveCli = run('supabase', ['--version'], 8000) !== null;

/* ---- database ----------------------------------------------------------- */
function database() {
  const local = readdirSync(join(root, 'supabase', 'migrations'))
    .filter(f => /^\d{14}_.*\.sql$/.test(f))
    .map(f => ({ version: f.slice(0, 14), file: f }));

  if (!haveCli) return { state: 'unknown', reason: 'no supabase CLI in this environment', local: local.length };

  const out = run('supabase', ['migration', 'list']);
  if (out === null) return { state: 'unknown', reason: '`supabase migration list` failed (not linked, or no network)', local: local.length };

  /* pipe table: | Local | Remote | Time |. A row with a Local version and an
     empty Remote is a migration that exists here and not in prod. */
  const applied = new Set();
  let sawAnyRow = false;
  for (const line of out.split('\n')) {
    if (!line.includes('|')) continue;
    const cols = line.split('|').map(c => c.trim());
    const l = (cols[0] || '').match(/\d{14}/);
    const r = (cols[1] || '').match(/\d{14}/);
    if (l || r) sawAnyRow = true;
    if (r) applied.add(r[0]);
  }
  if (!sawAnyRow) return { state: 'unknown', reason: 'could not parse `supabase migration list` output', local: local.length };

  const pending = local.filter(m => !applied.has(m.version));
  return pending.length
    ? { state: 'owed', pending: pending.map(m => m.file), command: 'supabase db push' }
    : { state: 'clean', applied: applied.size };
}

/* ---- edge functions ------------------------------------------------------ */
function functions() {
  const dir = join(root, 'supabase', 'functions');
  if (!existsSync(dir)) return { state: 'clean', note: 'no functions in this repo' };
  const names = readdirSync(dir, { withFileTypes: true }).filter(d => d.isDirectory()).map(d => d.name);

  if (!haveCli) return { state: 'unknown', reason: 'no supabase CLI in this environment', functions: names.length };
  const out = run('supabase', ['functions', 'list']);
  if (out === null) return { state: 'unknown', reason: '`supabase functions list` failed', functions: names.length };

  /* deployed-at per function, parsed loosely: any ISO-ish timestamp on the row */
  const deployed = new Map();
  for (const line of out.split('\n')) {
    const name = names.find(n => new RegExp(`\\b${n}\\b`).test(line));
    if (!name) continue;
    const ts = line.match(/\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}(:\d{2})?/);
    if (ts) deployed.set(name, Date.parse(ts[0].replace(' ', 'T') + 'Z'));
  }
  if (!deployed.size) return { state: 'unknown', reason: 'could not parse `supabase functions list` output', functions: names.length };

  const stale = [];
  for (const n of names) {
    const at = deployed.get(n);
    if (at === undefined || Number.isNaN(at)) { stale.push({ name: n, why: 'never deployed, or no timestamp' }); continue; }
    const committed = run('git', ['log', '-1', '--format=%ct', '--', `supabase/functions/${n}`]);
    if (!committed) continue;
    if (Number(committed) * 1000 > at) stale.push({ name: n, why: `last commit is newer than the deploy` });
  }
  /* ADVISORY: clock skew between a git commit and a deploy timestamp can read
     either way near the boundary, so this suggests, it does not assert. */
  return stale.length
    ? { state: 'maybe', stale, advisory: true, command: (n) => `supabase functions deploy ${n}` }
    : { state: 'clean', deployed: deployed.size };
}

/* ---- client -------------------------------------------------------------- */
function client() {
  const branch = run('git', ['rev-parse', '--abbrev-ref', 'HEAD']);
  if (!branch) return { state: 'unknown', reason: 'not a git checkout' };
  const dirty = (run('git', ['status', '--porcelain']) || '').split('\n').filter(Boolean).length;

  const unpushed = run('git', ['rev-list', '--count', `origin/${branch}..HEAD`]);
  const aheadOfMain = run('git', ['rev-list', '--count', 'origin/main..HEAD']);
  const touchesClient = run('git', ['diff', '--name-only', 'origin/main...HEAD', '--', 'index.html', 'sw.js', 'manifest.webmanifest', 'netlify.toml', 'stamp-version.sh', '.well-known']);

  const owed = [];
  if (dirty) owed.push(`${dirty} uncommitted change${dirty > 1 ? 's' : ''}`);
  if (unpushed && Number(unpushed) > 0) owed.push(`${unpushed} commit(s) not pushed to origin/${branch}`);
  if (branch !== 'main' && aheadOfMain && Number(aheadOfMain) > 0)
    owed.push(`${aheadOfMain} commit(s) on ${branch} not on main` +
      (touchesClient ? ' — including served files, so this is a real client deploy' : ' — no served files touched'));

  return owed.length
    ? { state: 'owed', branch, owed, servedFiles: touchesClient ? touchesClient.split('\n') : [],
        command: branch === 'main' ? 'git push' : 'merge to main (Netlify builds main)' }
    : { state: 'clean', branch };
}

/* ---- report -------------------------------------------------------------- */
const report = { database: database(), functions: functions(), client: client() };
const anyOwed = Object.values(report).some(r => r.state === 'owed' || r.state === 'maybe');
const anyUnknown = Object.values(report).some(r => r.state === 'unknown');

if (asJson) { console.log(JSON.stringify({ ...report, anyOwed, anyUnknown, haveCli }, null, 2)); process.exit(0); }

/* Stop hook: say nothing unless something is genuinely owed. A hook that
   speaks every turn gets tuned out, and then it is worse than no hook. The
   unknown case is deliberately silent here — in a remote session the CLI is
   always missing, and "I could not look" every single turn IS the noise. */
if (asHook) {
  if (!anyOwed) process.exit(0);
  const bits = [];
  if (report.database.state === 'owed')
    bits.push(`database: ${report.database.pending.length} migration(s) not pushed (${report.database.pending[0]}${report.database.pending.length > 1 ? ', …' : ''})`);
  if (report.functions.state === 'maybe')
    bits.push(`edge functions: ${report.functions.stale.map(s => s.name).join(', ')} may need a deploy`);
  if (report.client.state === 'owed')
    bits.push(`client: ${report.client.owed.join('; ')}`);
  console.log(JSON.stringify({
    systemMessage: `Deploys owed — ${bits.join(' · ')}.  Run ./tools/ship.sh`,
  }));
  process.exit(0);
}
if (quiet && !anyOwed && !anyUnknown) process.exit(0);

const M = { owed: 'X OWED  ', maybe: '~ MAYBE ', unknown: '? UNKNOWN', clean: '  clean ' };
const line = (label, r, body) => {
  console.log(`${M[r.state]} ${label}`);
  for (const b of body) console.log(`           ${b}`);
};

console.log('');
const d = report.database;
line('DATABASE', d,
  d.state === 'owed' ? [...d.pending, '', `  -> ${d.command}`]
  : d.state === 'unknown' ? [d.reason, `${d.local} migrations on disk — cannot tell which are applied`]
  : [`${d.applied} migrations applied, none pending`]);

const f = report.functions;
line('EDGE FUNCTIONS', f,
  f.state === 'maybe' ? [...f.stale.map(s => `${s.name} — ${s.why}`), '',
                         '  advisory only: commit vs deploy timestamps, not content',
                         ...f.stale.map(s => `  -> supabase functions deploy ${s.name}`)]
  : f.state === 'unknown' ? [f.reason]
  : [f.note || `${f.deployed} deployed, none look stale`]);

const c = report.client;
line('CLIENT', c,
  c.state === 'owed' ? [...c.owed, '', `  -> ${c.command}`]
  : c.state === 'unknown' ? [c.reason]
  : [`${c.branch} is level with origin and main`]);

console.log('');
if (anyUnknown && !haveCli)
  console.log('  The Supabase CLI is not in this environment, so the database and\n  function answers are unknown, not clean. Run this on the Mac.\n');
process.exit(0);
