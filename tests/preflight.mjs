#!/usr/bin/env node
/* Cup Season preflight — the static invariant suite.
   Every check here is a lesson the codebase already paid for (missing grants,
   silent bridge misses, stale allowlists, the 6-digit OTP trap). Run it before
   any push; it is the automated half of the Monday QA ritual.

     node tests/preflight.mjs        -> PASS/FAIL per check, exit 1 on any FAIL

   Read-only: parses index.html / sw.js / migrations / stamp-version.sh.
   No network, no DB — the live half lives in tests/db-checks.sql. */

import { readFileSync, readdirSync, writeFileSync, mkdtempSync, rmSync, existsSync } from 'node:fs';
import { execFileSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const root = new URL('..', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');
const html = readFileSync(join(root, 'index.html'), 'utf8');
const sw = readFileSync(join(root, 'sw.js'), 'utf8');
const stamp = readFileSync(join(root, 'stamp-version.sh'), 'utf8');
const migDir = join(root, 'supabase', 'migrations');
const migs = readdirSync(migDir).filter(f => f.endsWith('.sql'))
  .map(f => readFileSync(join(migDir, f), 'utf8')).join('\n');

let fails = 0, warns = 0;
const pass = (name, note = '') => console.log(`  PASS  ${name}${note ? ' — ' + note : ''}`);
const fail = (name, note) => { fails++; console.log(`X FAIL  ${name} — ${note}`); };
const warn = (name, note) => { warns++; console.log(`~ WARN  ${name} — ${note}`); };

/* 1 · version placeholders exactly where the build expects them ------------ */
{
  const hi = (html.match(/__CS_VERSION__/g) || []).length;
  const si = (sw.match(/__CS_VERSION__/g) || []).length;
  (hi === 3 && si === 1)
    ? pass('version placeholders', `index ${hi} · sw ${si}`)
    : fail('version placeholders', `expected index 3 / sw 1, got index ${hi} / sw ${si} — never hand-edit these`);
}

/* 2 · every client RPC has an execute grant in a migration ----------------- */
{
  const called = new Set([...html.matchAll(/\.rpc\(\s*['"]([a-z0-9_]+)['"]/g)].map(m => m[1]));
  const granted = new Set(
    [...migs.matchAll(/grant\s+(?:all|execute)\s+on\s+function\s+(?:"?public"?\.)?"?([a-z0-9_]+)"?/gi)].map(m => m[1].toLowerCase())
  );
  const missing = [...called].filter(f => !granted.has(f));
  missing.length === 0
    ? pass('rpc grant coverage', `${called.size} client RPCs all granted`)
    : fail('rpc grant coverage', `no grant found for: ${missing.join(', ')} (silent 403 in prod)`);
}

/* 3 · classic->module bridge coverage -------------------------------------- */
{
  const BUILTINS = new Set(['location','localStorage','sessionStorage','history','navigator','matchMedia','open','scrollTo','scrollY','innerWidth','innerHeight','addEventListener','removeEventListener','dispatchEvent','requestAnimationFrame','setTimeout','setInterval','clearTimeout','clearInterval','getComputedStyle','fetch','alert','confirm','prompt','print','focus','close','postMessage','crypto','indexedDB','caches','screen','devicePixelRatio','onerror','onunhandledrejection','performance','CSS','Notification','PushManager','visualViewport','structuredClone','queueMicrotask','origin','name','parent','top','frames','opener','isSecureContext','trustedTypes','speechSynthesis','getSelection','pageYOffset','event']);
  const used = new Set([...html.matchAll(/window\.([A-Za-z_$][\w$]*)/g)].map(m => m[1])
    .filter(n => !BUILTINS.has(n)));
  const assigned = new Set([...html.matchAll(/window\.([A-Za-z_$][\w$]*)\s*=[^=]/g)].map(m => m[1]));
  /* classic top-level function declarations ARE window properties; only
     module-scoped declarations need the explicit bridge (the real landmine) */
  for (const m of html.matchAll(/<script(\s+type="module")?\s*>([\s\S]*?)<\/script>/g)) {
    if (m[1]) continue;                                    // module: no auto-globals
    for (const d of m[2].matchAll(/^\s*(?:async\s+)?function\s+([A-Za-z_$][\w$]*)/gm)) assigned.add(d[1]);
    for (const v of m[2].matchAll(/^(?:let|var|const)\s+([A-Za-z_$][\w$]*)/gm)) assigned.add(v[1]);
  }
  const missing = [...used].filter(n => !assigned.has(n));
  missing.length === 0
    ? pass('window.* bridge coverage', `${used.size} bridged names all assigned`)
    : fail('window.* bridge coverage', `referenced but never assigned (silent demo-mode failure): ${missing.join(', ')}`);
}

/* 4 · sw SHELL list must be inside the dist allowlist ---------------------- */
{
  const shell = [...(sw.match(/const SHELL = \[([\s\S]*?)\]/) || ['',''])[1]
    .matchAll(/'([^']+)'/g)].map(m => m[1]).filter(p => p !== '/');
  const cpLine = (stamp.match(/^cp (?!-r)(.*)\\\n(.*)$/m) || [null, '', ''])
    .slice(1).join(' ') || (stamp.match(/^cp (?!-r).*$/gm) || []).join(' ');
  const missing = shell.filter(p => !cpLine.includes(p.replace(/^\//, '')));
  missing.length === 0
    ? pass('sw shell within dist allowlist', `${shell.length} assets`)
    : fail('sw shell within dist allowlist', `cached but not shipped (404 after deploy): ${missing.join(', ')}`);
}

/* 5 · OTP inputs never maxlength=6 (Supabase issues 8-digit codes) --------- */
{
  const bad = [...html.matchAll(/one-time-code[^>]*maxlength="?(\d+)"?|maxlength="?(\d+)"?[^>]*one-time-code/g)]
    .map(m => +(m[1] || m[2])).filter(n => n < 8);
  bad.length === 0
    ? pass('otp maxlength', 'no code input below 8')
    : fail('otp maxlength', `found maxlength ${bad.join(', ')} on a one-time-code input`);
}

/* 6 · script blocks parse (classic + module) ------------------------------- */
{
  const blocks = [...html.matchAll(/<script(\s+type="module")?\s*>([\s\S]*?)<\/script>/g)]
    .filter(m => m[2].trim().length > 100);
  const dir = mkdtempSync(join(tmpdir(), 'cs-preflight-'));
  let bad = 0;
  blocks.forEach((m, i) => {
    const isModule = !!m[1];
    const f = join(dir, `block-${i}.${isModule ? 'mjs' : 'js'}`);
    writeFileSync(f, m[2]);
    try { execFileSync('node', ['--check', f], { stdio: 'pipe' }); }
    catch (e) {
      bad++;
      const msg = String(e.stderr || e.message).split('\n').slice(0, 3).join(' | ');
      fail(`script block ${i + 1} parses (${isModule ? 'module' : 'classic'})`, msg);
    }
  });
  rmSync(dir, { recursive: true, force: true });
  if (!bad) pass('script blocks parse', `${blocks.length} blocks clean`);
}

/* 7 · unescaped-sink heuristic (WARN — human judges) ----------------------- */
{
  const sinks = [...html.matchAll(/^.*innerHTML[^=]*=[^=][^\n]*\$\{(?!esc\()[a-z]+\.(name|title|body|display_name|city|label)\b[^\n]*$/gmi)];
  sinks.length === 0
    ? pass('esc() sink heuristic', 'no bare user-field in an innerHTML template line')
    : warn('esc() sink heuristic', `${sinks.length} line(s) worth an eyeball: ${sinks.slice(0,3).map(s=>s[0].trim().slice(0,70)).join(' || ')}`);
}

/* 8 · dist allowlist files all exist --------------------------------------- */
{
  const names = ((stamp.match(/^cp (?!-r).*$/gm) || []).join(' ').match(/[\w.-]+\.(?:html|js|webmanifest|png)/g) || []);
  const missing = names.filter(n => !existsSync(join(root, n)));
  missing.length === 0
    ? pass('dist allowlist files exist', `${names.length} files`)
    : fail('dist allowlist files exist', `allowlisted but missing from repo: ${missing.join(', ')}`);
}

console.log(`\n${fails ? 'FAIL' : 'PASS'} — ${fails} failure(s), ${warns} warning(s)`);
process.exit(fails ? 1 : 0);
