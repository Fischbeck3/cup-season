#!/usr/bin/env node
// Regenerates the SYNTHETIC examples in docs/pilot/examples/ — every number in
// them is invented. Never pointed at a linked project.
//
//   CS_PG_BIN=<psql dir> node tests/pilot/fixtures/render-examples.mjs
//
// 1. the full report on the W6 fixtures (needs the sandbox: tests/sim/sandbox/apply.sh),
//    loaded into a disposable copy `cs_w6_examples` that is dropped afterwards;
// 2. the acquisition half alone (--no-db) on five input scenarios.
import { spawnSync } from 'node:child_process';
import { writeFileSync, mkdtempSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { LOG_COLUMNS, READING_COLUMNS } from '../../../tools/lib/growth-report.mjs';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', '..');
const fx = join(root, 'tests', 'pilot', 'fixtures');
const out = join(root, 'docs', 'pilot', 'examples');
const PG = process.env.CS_PG_BIN || '/opt/homebrew/opt/postgresql@17/bin';
const runner = join(root, 'tools', 'pilot-scorecard.mjs');
const run = (args, env = {}) => {
  const r = spawnSync(process.execPath, [runner, ...args], { encoding: 'utf8', env: { ...process.env, CS_PG_BIN: PG, ...env } });
  if (r.status) throw new Error(r.stderr || `exit ${r.status}`);
  return r.stdout;
};

// ── 1 · the full report ──────────────────────────────────────────────────────
const CONN = ['-h', '/tmp/cs-sim-sock', '-p', '5478', '-U', 'postgres', '-X', '-q', '-v', 'ON_ERROR_STOP=1'];
const psql = (db, args) => spawnSync(join(PG, 'psql'), [...CONN, '-d', db, ...args], { encoding: 'utf8' });
if (existsSync(join(PG, 'psql')) && psql('cupseason', ['-Atc', 'select 1']).status === 0) {
  const DB = 'cs_w6_examples';
  let r = psql('postgres', ['-c', `drop database if exists ${DB}`, '-c', `create database ${DB} template cupseason`]);
  if (r.status) throw new Error(r.stderr);
  r = psql(DB, ['-f', join(fx, 'w6-fixtures.sql')]);
  if (r.status) throw new Error(r.stderr);
  try {
    writeFileSync(join(out, '2026-11-02-synthetic-report.md'), run(['--sandbox', '--db', DB, '--synthetic', '--as-of', '2026-11-02', '--store-live', 'true',
      '--csv', join(fx, 'w6-synthetic-log.csv'), '--readings', join(fx, 'w6-synthetic-readings.csv')]));
    console.log('wrote 2026-11-02-synthetic-report.md');
  } finally { psql('postgres', ['-c', `drop database if exists ${DB}`]); }
} else console.log('sandbox not running: skipped the full report (tests/sim/sandbox/apply.sh builds it)');

// ── 2 · the acquisition half on five scenarios ───────────────────────────────
const dir = mkdtempSync(join(tmpdir(), 'cs-w6-examples-'));
const file = (name, cols, rows) => { const p = join(dir, name); writeFileSync(p, [cols.join(','), ...rows].join('\n') + '\n'); return p; };
const scenarios = [
  { title: 'A · complete — a reading through the checkpoint date decides it', asOf: '2026-11-01', live: 'true',
    log: ['2026-10-04,by_hand,,,,40,,', '2026-10-11,by_hand,,,,85,,', '2026-10-18,by_hand,,,,205,,', '2026-10-25,by_hand,,,,160,,'],
    readings: ['2026-10-31,512,App Analytics (SYNTHETIC),'] },
  { title: 'B · partial — weekly subtotals with a missing week, and no reading: unverified, never missed', asOf: '2026-11-01', live: 'true',
    log: ['2026-10-04,by_hand,,,,100,,', '2026-10-25,by_hand,,,,250,,', '2026-11-01,by_hand,,,,200,,'], readings: [] },
  { title: 'C · failing — a reading through Oct 31 short of 500: missed', asOf: '2026-11-01', live: 'true',
    log: ['2026-10-04,by_hand,,,,40,,', '2026-10-11,by_hand,,,,85,,', '2026-10-18,by_hand,,,,205,,', '2026-10-25,by_hand,,,,130,,'],
    readings: ['2026-10-31,480,App Analytics (SYNTHETIC),'] },
  { title: 'D · missing — nothing logged and nothing read, reported on Dec 1', asOf: '2026-12-01', live: 'true', log: [], readings: [] },
  { title: 'E · contradictory — --store-live false beside a logged store count, and a duplicate row', asOf: '2026-10-05', live: 'false',
    log: ['2026-10-04,by_hand,,,,25,,', '2026-10-04,public_link,,,,10,,', '2026-10-04,public_link,,,,10,,'], readings: [] },
];
const L = ['# SYNTHETIC — the acquisition half on five input scenarios', '',
  '> **SYNTHETIC.** Every number below is invented to exercise the checkpoint rule. None was observed. Regenerate with `node tests/pilot/fixtures/render-examples.mjs`.', ''];
scenarios.forEach((s, i) => {
  const md = run(['--no-db', '--synthetic', '--as-of', s.asOf, '--store-live', s.live,
    '--csv', file(`log${i}.csv`, LOG_COLUMNS, s.log), '--readings', file(`readings${i}.csv`, READING_COLUMNS, s.readings)]);
  const acq = md.slice(md.indexOf('## acquisition'), md.indexOf('## Known measurement gaps')).replace(/^## acquisition\n/, '').replace(/^### /gm, '#### ');
  L.push(`## ${s.title}`, '', `_Report date ${s.asOf} · \`--store-live ${s.live}\`._`, '', acq.trim(), '');
});
writeFileSync(join(out, 'synthetic-acquisition-cases.md'), L.join('\n'));
console.log('wrote synthetic-acquisition-cases.md');
