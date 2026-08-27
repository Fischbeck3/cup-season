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
const capBundle = JSON.parse(
  readFileSync(join(root, 'ios-wrapper', 'capacitor.config.json'), 'utf8')).appId;
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
  const BUILTINS = new Set(['location','localStorage','sessionStorage','history','navigator','matchMedia','open','scrollTo','scrollY','innerWidth','innerHeight','addEventListener','removeEventListener','dispatchEvent','requestAnimationFrame','setTimeout','setInterval','clearTimeout','clearInterval','getComputedStyle','fetch','alert','confirm','prompt','print','focus','close','postMessage','crypto','indexedDB','caches','screen','devicePixelRatio','onerror','onunhandledrejection','performance','CSS','Notification','PushManager','visualViewport','structuredClone','queueMicrotask','origin','name','parent','top','frames','opener','isSecureContext','trustedTypes','speechSynthesis','getSelection','pageYOffset','event','Capacitor']);
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

/* 9 · universal-links AASA is real, modern, and query-scoped -------------
   Three lessons in one check. The file shipped for weeks with a literal
   TEAMID placeholder and preflight passed 8/8 over it. It also used the
   legacy appID+paths form, where `?` is a SINGLE-CHARACTER WILDCARD and
   `paths` cannot see a query string at all - while every link the app cares
   about is query-carried (/?claim=, /?join=). And a component with no query
   matcher silently swallows all of cupseason.app, so tapping any link opens
   the app. Apple fetches this from the LIVE domain, so a mistake here is only
   ever discovered on a device, days later. */
{
  const aasaPath = join(root, '.well-known', 'apple-app-site-association');
  if (!existsSync(aasaPath)) {
    fail('aasa universal links', 'missing .well-known/apple-app-site-association');
  } else {
    const raw = readFileSync(aasaPath, 'utf8');
    let j = null, problems = [];
    try { j = JSON.parse(raw); } catch (e) { problems.push(`not valid JSON: ${e.message}`); }
    if (j) {
      const details = j?.applinks?.details;
      if (!Array.isArray(details) || !details.length) problems.push('applinks.details is empty');
      for (const d of details || []) {
        if (d.paths || d.appID) problems.push('legacy appID/paths form cannot match a query string — use appIDs + components');
        const ids = d.appIDs || [];
        if (!ids.length) problems.push('a details entry has no appIDs');
        for (const id of ids) {
          if (!/^[A-Z0-9]{10}\./.test(id)) problems.push(`appID "${id}" has no real 10-char Team ID prefix`);
          const bundle = id.split('.').slice(1).join('.');
          if (bundle !== capBundle) problems.push(`appID bundle "${bundle}" != capacitor.config appId "${capBundle}"`);
        }
        for (const c of d.components || []) {
          if (!c['?']) problems.push(`component ${JSON.stringify(c['/'] ?? '')} has no query matcher — it would swallow every link on the domain`);
        }
      }
    }
    if (!/apple-app-site-association/.test(stamp)) problems.push('not copied into dist/ by stamp-version.sh — Apple would 404 it');
    problems.length === 0
      ? pass('aasa universal links', `${(j.applinks.details[0].appIDs || []).join(', ')}`)
      : fail('aasa universal links', problems.join(' · '));
  }
}

/* 10 · design tokens: one source, and the live client still agrees --------
   D98 Phase A1. packages/tokens/tokens.json is the source of truth; the RN
   and React clients build from it. index.html keeps its own inlined copy
   because it is a single-file PWA by design — so the ONLY thing standing
   between one palette and two is this check. A colour changed in the client
   and not the JSON (or the reverse) fails here rather than shipping as a
   surface that is subtly the wrong ember. */
{
  const doc = JSON.parse(readFileSync(join(root, 'packages', 'tokens', 'tokens.json'), 'utf8'));
  const want = new Map();
  for (const g of Object.values(doc.groups))
    for (const [name, spec] of Object.entries(g.tokens)) want.set(name, spec);

  /* read the client's own declarations out of its two theme surfaces */
  const cssBlock = (sel, from = 0) => {
    const i = html.indexOf(sel + '{', from);
    if (i < 0) return null;
    const s2 = i + sel.length + 1;
    return { body: html.slice(s2, html.indexOf('\n}', s2)), end: html.indexOf('\n}', s2) };
  };
  const decls = (body) => new Map(
    [...body.matchAll(/--([\w-]+)\s*:\s*([^;]+);/g)].map(m => [m[1], m[2].trim()]));
  const r1 = cssBlock(':root');
  const r2 = r1 && cssBlock(':root', r1.end);
  const lt = cssBlock('html[data-theme="light"]');
  const problems = [];
  if (!r1 || !r2 || !lt) problems.push('could not find the :root / light theme blocks in index.html');
  else {
    const gotDark = new Map([...decls(r1.body), ...decls(r2.body)]);
    const gotLight = decls(lt.body);
    for (const [name, spec] of want) {
      if (spec.dark !== undefined && gotDark.get(name) !== spec.dark)
        problems.push(`--${name} dark: client ${gotDark.get(name) ?? '(absent)'} != tokens.json ${spec.dark}`);
      if (spec.light !== undefined && gotLight.get(name) !== spec.light)
        problems.push(`--${name} light: client ${gotLight.get(name) ?? '(absent)'} != tokens.json ${spec.light}`);
    }
    for (const name of gotDark.keys()) if (!want.has(name)) problems.push(`--${name} is in index.html but not tokens.json`);
  }
  try { execFileSync('node', [join(root, 'tools', 'build-tokens.mjs'), '--check'], { stdio: 'pipe' }); }
  catch { problems.push('generated tokens.css/tokens.ts are stale — run tools/build-tokens.mjs'); }
  problems.length === 0
    ? pass('design tokens single-source', `${want.size} tokens agree with the client`)
    : fail('design tokens single-source', problems.slice(0, 4).join(' · ') + (problems.length > 4 ? ` (+${problems.length - 4} more)` : ''));
}

/* 11 · every client RPC exists in the database (or is pending deploy) -----
   D98 Phase A2. Check 2 proves a grant exists SOMEWHERE in the migrations.
   This is the other half: the function actually exists in prod, spelled the
   way the client spells it. A typo'd RPC name is a 404 that only ever shows
   up as a dead button, and the two halves miss different bugs. Functions
   present in a local migration but not in the snapshot are reported as a
   deploy-skew WARN — that is a `supabase db push` you owe, not an error. */
{
  const psv = readFileSync(join(root, 'packages', 'db', 'contract.psv'), 'utf8');
  const inProd = new Set(psv.split('\n').filter(l => l.trim() && !l.startsWith('#')).map(l => l.split('|')[0]));
  const inMigrations = new Set(
    [...migs.matchAll(/create\s+(?:or\s+replace\s+)?function\s+(?:"?public"?\.)?"?([a-z0-9_]+)"?/gi)].map(m => m[1].toLowerCase()));
  const called = new Set([...html.matchAll(/\.rpc\(\s*['"]([a-z0-9_]+)['"]/g)].map(m => m[1]));

  const ghosts = [...called].filter(f => !inProd.has(f) && !inMigrations.has(f));
  const pending = [...called].filter(f => !inProd.has(f) && inMigrations.has(f));
  let stale = false;
  try { execFileSync('node', [join(root, 'tools', 'build-db.mjs'), '--check'], { stdio: 'pipe' }); }
  catch { stale = true; }

  if (ghosts.length) fail('rpc exists in database', `client calls a function that is in neither prod nor a migration: ${ghosts.join(', ')}`);
  else if (stale) fail('rpc exists in database', 'packages/db/rpc.ts is stale — run tools/build-db.mjs');
  else pass('rpc exists in database', `${called.size} client RPCs, ${inProd.size} in the snapshot`);
  if (pending.length) warn('rpc pending deploy', `in a migration but not yet in prod — owe a db push: ${pending.join(', ')}`);
}

console.log(`\n${fails ? 'FAIL' : 'PASS'} — ${fails} failure(s), ${warns} warning(s)`);
process.exit(fails ? 1 : 0);
