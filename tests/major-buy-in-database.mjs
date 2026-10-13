// Cup Season — D412 · a Major's buy-in has the same $200 ceiling as every other money field,
// exercised against the FULL migration chain in a disposable local PostgreSQL cluster.
// Never accepts a database URL; there is no production option. Uses the same Supabase
// service stubs as tests/social-course-database.mjs.
//
//   node tests/major-buy-in-database.mjs
//
// 1 · CONTROL. Every migration before 20261224120000: a $500 Major is accepted, db-check 62
//     FAILS and tests/db/a-majors-buy-in-has-the-same-ceiling.sql FAILS — both can see the
//     defect they were written for.
// 2 · 20261224120000 applied twice: the second run is a notice, not a change.
// 3 · The $500 Major made before it is untouched (D412 refuses new values only; no backfill).
// 4 · The tests/db file passes, and db-check 62 passes.
// 5 · The whole db-checks suite on the migrated cluster: any FAIL is printed (pg_cron is a
//     stand-in here, so check 1 cannot pass), and 62 must not be one of them.
// 6 · MUTATION. The ceiling alone put back to 100000 → check 62 and the tests/db file FAIL, and
//     re-running the migration heals it. The body retyped from 20260831120000 (no [D393] reach
//     gate, the pre-stage-D membership read) → check 62 names all three losses, and the
//     migration's own self-check refuses to finish on it.

import { readFileSync, readdirSync, mkdtempSync, mkdirSync, rmSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const bin = process.env.PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
const mig = join(root, 'supabase', 'migrations');
const PATCH = '20261224120000_a_majors_buy_in_has_the_same_ceiling.sql';
const TEST = join(root, 'tests', 'db', 'a-majors-buy-in-has-the-same-ceiling.sql');
const temp = mkdtempSync(join(tmpdir(), 'cs-major-pg-'));
const data = join(temp, 'data'), sock = join(temp, 's'); mkdirSync(sock);
const PORT = '55462';

const run = (cmd, args, input) => spawnSync(join(bin, cmd), args, { input, encoding: 'utf8', maxBuffer: 64 << 20 });
function must(p, what) { if (p.status) { console.error(what + '\n' + (p.stderr || p.stdout).slice(-4000)); cleanup(); process.exit(1); } return p; }
function cleanup() { run('pg_ctl', ['-D', data, '-m', 'immediate', '-w', 'stop']); rmSync(temp, { recursive: true, force: true }); }
const stub = text => text.replace(
  /^\s*create extension if not exists (?:"supabase_vault"|pg_cron|pg_net).*?;[^\n]*$/gim, '-- local stub');

must(run('initdb', ['-D', data, '-U', 'sim', '-A', 'trust', '-E', 'UTF8', '--no-locale']), 'initdb');
must(run('pg_ctl', ['-D', data, '-l', join(temp, 'log'), '-o',
  `-F -k ${sock} -p ${PORT} -c listen_addresses='' -c shared_preload_libraries=pg_stat_statements -c wal_level=logical -c timezone=UTC`, '-w', 'start']), 'start');

const base = ['-h', sock, '-p', PORT, '-X', '-q', '-v', 'ON_ERROR_STOP=1'];
must(run('psql', [...base, '-U', 'sim', '-d', 'postgres', '-c', 'create database cupseason']), 'createdb');
must(run('psql', [...base, '-U', 'sim', '-d', 'cupseason', '-f', join(root, 'tests/fixtures/release-bootstrap.sql')]), 'bootstrap');
const chain = [...base, '-U', 'postgres', '-d', 'cupseason', '--single-transaction'];
const files = readdirSync(mig).filter(n => n.endsWith('.sql')).sort();
const patchText = readFileSync(join(mig, PATCH), 'utf8');
let applied = 0;
for (const f of files) {
  if (f === PATCH) continue;
  must(run('psql', chain, stub(readFileSync(join(mig, f), 'utf8'))), 'migration ' + f);
  applied++;
}
must(run('psql', chain, readFileSync(join(root, 'tests/fixtures/release-post-bootstrap.sql'), 'utf8')), 'post-bootstrap');

const PSQL = [...base, '-U', 'postgres', '-d', 'cupseason', '-At'];
function sql(text) { return must(run('psql', PSQL, text), text.slice(0, 300)).stdout.trim(); }
const tryRun = (args, text) => run('psql', args, text);
let passed = 0;
const ok = (cond, msg) => { if (!cond) throw new Error('ASSERT: ' + msg); passed++; console.log('PASS ', msg); };

// db-check 62, sliced out of the suite exactly as it is pushed: from its own `select '62 · `
// to the next check's `union all` (or the end of the CTE), so a check 63 is never swept in
const checks = readFileSync(join(root, 'tests', 'db-checks.sql'), 'utf8');
const from = checks.indexOf('-- 62 · D412');
const own = checks.indexOf("select '62 · ", from);
const cte = checks.lastIndexOf('\n)\nselect * from checks');
const next = checks.indexOf('\nunion all', own);
const to = next > own && next < cte ? next : cte;
const check62 = checks.slice(own, to).replace(/(?:\n[ \t]*(?:--[^\n]*)?)+$/, '');
const SIG = 'public.create_major(text,date,integer,numeric,text,uuid,text,uuid)';
const HOST = '00000000-0000-4000-8000-0000000d41f0';  // fictional fixture golfer, never production data

try {
  ok(applied === files.length - 1 && files.includes(PATCH), `${applied} migrations before ${PATCH.slice(0, 14)}, none skipped`);
  ok(from > 0 && own > from && to > own, 'db-checks.sql carries check 62');
  ok(sql(`select count(*) from (${check62}) c`) === '1', 'the check-62 slice is one check, never its neighbours');

  // ---- 1 · control: the defect reproduces, and both proofs can see it -------------------
  sql(`insert into auth.users(id, email) values ('${HOST}', 'major.control@fixture.test');
       update profiles set display_name = 'Fixture Control', handle = 'fixture_control', marker = 'saguaro', is_founder = false
        where id = '${HOST}';`);
  const control = sql(`set sim.uid = '${HOST}'; set role authenticated;
       select create_major('Fixture Control Jug', current_date + 7, 4, 500);`);
  ok(/^[0-9a-f-]{36}$/.test(control), 'before D412 a $500 Major is accepted (the defect reproduces)');
  ok(/\|FAIL — .*still takes a buy-in above \$200/.test(sql(check62)), 'before D412 check 62 FAILS');
  const before = tryRun(PSQL, readFileSync(TEST, 'utf8'));
  ok(before.status !== 0 && /FAIL a \$201 buy-in is refused/.test(before.stderr),
     'before D412 the tests/db file FAILS on the $201 buy-in');

  // ---- 2 · the migration, twice ------------------------------------------------------------
  const first = must(run('psql', chain, patchText), 'first ' + PATCH);
  const second = must(run('psql', chain, patchText), 'second ' + PATCH);
  ok(!/already holds/.test(first.stderr) && /\[D412\] create_major already holds the \$200 ceiling/.test(second.stderr),
     'the migration patches once; a second run is a notice, not a change');
  ok(sql(`select count(*) from pg_proc where pronamespace = 'public'::regnamespace and proname = 'create_major'`) === '1',
     'no overload appeared: create_major is still one function');
  ok(sql(`select has_function_privilege('authenticated', '${SIG}', 'EXECUTE')::text || ',' ||
                 has_function_privilege('anon', '${SIG}', 'EXECUTE')::text`) === 'true,false',
     'create_major: authenticated yes, anon never');

  // ---- 3 · nothing that already exists is rewritten -----------------------------------------
  ok(sql(`select buy_in from events where id = '${control}'`) === '500', 'the $500 Major made before D412 still reads 500');

  // ---- 4 · the proofs pass -------------------------------------------------------------------
  const after = must(run('psql', PSQL, readFileSync(TEST, 'utf8')), 'tests/db after D412');
  ok(/a-majors-buy-in-has-the-same-ceiling: all assertions passed/.test(after.stdout), 'the tests/db file passes after D412');
  for (const line of after.stderr.split('\n').filter(l => /NOTICE: {2}ok {3}/.test(l))) console.log('      ', line.replace(/^.*ok {3}/, 'ok  '));
  const v62 = sql(check62);
  ok(/^62 · .*\|PASS — /.test(v62), 'db-check 62 passes: ' + v62.slice(0, 140));

  // ---- 5 · the whole suite, on the migrated cluster ------------------------------------------
  const suite = sql(checks).split('\n');
  const fails = suite.filter(l => /\|FAIL/.test(l));
  for (const l of fails) console.log('      suite:', l.slice(0, 200));
  ok(!fails.some(l => /^62 · /.test(l)), `the whole suite runs (${suite.length} checks, ${fails.length} FAIL), and 62 is not among the failures`);

  // ---- 6 · mutation ------------------------------------------------------------------------
  // (a) the ceiling alone put back: the gates stay, the number moves
  sql(`do $m$ declare v text := pg_get_functiondef('${SIG}'::regprocedure); begin
         execute replace(v, $x$v_buy > 200 then raise exception 'buy-in out of range'; end if;  -- [D412] the $200 ceiling (D192, D402)$x$,
                            $x$v_buy > 100000 then raise exception 'buy-in out of range'; end if;$x$);
       end $m$;`);
  const m1 = sql(check62);
  ok(/\|FAIL — create_major still takes a buy-in above \$200/.test(m1) && !/D393|stage-D/.test(m1.split('|')[1]),
     'mutation (ceiling reverted): check 62 FAILS on the ceiling alone');
  const m1t = tryRun(PSQL, readFileSync(TEST, 'utf8'));
  ok(m1t.status !== 0 && /FAIL a \$201 buy-in is refused/.test(m1t.stderr), 'mutation (ceiling reverted): the tests/db file FAILS');
  must(run('psql', chain, patchText), 'healing ' + PATCH);
  ok(/^62 · .*\|PASS — /.test(sql(check62)), 'the migration heals a reverted ceiling, and check 62 passes again');

  // (b) the body retyped from its last whole copy (20260831120000): every later patch is lost
  const old = readFileSync(join(mig, '20260831120000_board_voice_natural_case.sql'), 'utf8');
  const m = old.match(/CREATE OR REPLACE FUNCTION public\.create_major\([\s\S]*?\nend \$function\$;/);
  ok(!!m && m[0].includes('v_buy > 100000'), 'the retyped body is the 20260831120000 copy');
  sql(m[0]);
  const m2 = sql(check62);
  ok(/still takes a buy-in above \$200/.test(m2) && /lost its \[D393\] reach gate/.test(m2) && /lost its stage-D write gate/.test(m2),
     'mutation (body retyped): check 62 names the ceiling, the [D393] gate and the stage-D gate');
  const refuse = tryRun(chain, patchText);
  ok(refuse.status !== 0 && /\[D412\] self-check: create_major lost its \[D393\] reach gate/.test(refuse.stderr),
     'mutation (body retyped): the migration\'s self-check refuses to finish on a drifted body');

  console.log(`\nALL PASS (${passed})`);
} catch (e) {
  console.error(e.stack || e.message);
  cleanup();
  process.exit(1);
}
cleanup();
