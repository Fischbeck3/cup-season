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
/* the phone's bundle id, from the XcodeGen manifest (D99) — the AASA must
   name exactly this app or /?claim and /?join open Safari instead of the app */
const capBundle = (readFileSync(join(root, 'apps', 'ios', 'project.yml'), 'utf8')
  .match(/PRODUCT_BUNDLE_IDENTIFIER:\s*([\w.]+)/) || [])[1] || '(no PRODUCT_BUNDLE_IDENTIFIER in apps/ios/project.yml)';
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
          if (bundle !== capBundle) problems.push(`appID bundle "${bundle}" != apps/ios/project.yml bundle "${capBundle}"`);
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
  catch { problems.push('generated tokens.css/tokens.ts/Tokens.swift are stale — run tools/build-tokens.mjs'); }
  /* D99: the 14 markers reach the phone the same way the tokens do */
  try { execFileSync('node', [join(root, 'tools', 'build-markers.mjs'), '--check'], { stdio: 'pipe' }); }
  catch { problems.push('generated Markers.swift is stale — run tools/build-markers.mjs'); }
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

/* ---------------------------------------------------------------------------
 * 12-14 · the native surface (D98 Phase B).
 *
 * apps/mobile/ is a second client against the same backend, which means it can
 * make every mistake index.html already made. These three checks are the same
 * lessons pointed at the phone. They are skipped, not failed, when the app is
 * absent, so a clone without it still runs clean.
 * ------------------------------------------------------------------------ */
const appDir = join(root, 'apps', 'mobile');
const appSrc = [];
if (existsSync(appDir)) {
  /* These three checks are about CODE, not prose. Comments are stripped before
     matching, so a doc comment can quote the very thing being forbidden —
     which is the only way to explain why it is forbidden. Line comments are
     recognised only when `//` is not preceded by a colon, so the `https://` in
     a URL string survives. */
  const decomment = (src) => src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .split('\n').map(l => l.replace(/(^|[^:])\/\/.*$/, '$1')).join('\n');

  const walk = (dir) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.name === 'node_modules' || e.name.startsWith('.')) continue;
      const full = join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (/\.tsx?$/.test(e.name))
        appSrc.push([full.slice(appDir.length + 1), decomment(readFileSync(full, 'utf8'))]);
    }
  };
  walk(appDir);
}

/* 12 · the phone names no colour of its own -------------------------------
   The native mirror of check 10. index.html is held to tokens.json by that
   check; nothing held the phone to anything, and a second client that mixes
   its own charcoal is exactly the drift Phase A exists to prevent. Every
   colour on the phone comes from packages/tokens through src/theme.ts, which
   converts CSS-shaped tokens into RN values and is forbidden — by this check,
   with no exemption — from inventing one. */
if (!appSrc.length) pass('native palette purity', 'apps/mobile absent — skipped');
else {
  const HEX = /#[0-9a-f]{3,8}\b/i;
  const FUNC = /\brgba?\s*\(/i;
  const hits = [];
  for (const [rel, src] of appSrc) {
    /* src/theme.ts is the conversion boundary itself: it parses `rgba(...)`
       back out of a shadow token and reassembles it in RN's shape, so the
       functional form is a reconstruction there, not a choice. It is still
       held to the hex rule, which is the form an invented colour would
       actually take, and it is 150 readable lines. */
    const pats = rel === 'src/theme.ts' ? [HEX] : [HEX, FUNC];
    src.split('\n').forEach((line, i) => {
      for (const pat of pats) {
        const m = line.match(pat);
        if (m) { hits.push(`${rel}:${i + 1} ${m[0]}`); break; }
      }
    });
  }
  hits.length === 0
    ? pass('native palette purity', `${appSrc.length} files, every colour from packages/tokens`)
    : fail('native palette purity', `hardcoded colour on the phone: ${hits.slice(0, 3).join(' · ')}${hits.length > 3 ? ` (+${hits.length - 3})` : ''}`);
}

/* 13 · the phone cannot reinvent the OTP landmines ------------------------
   Three separate bugs, each already paid for: a magic link that Gmail's
   scanner consumed before the user clicked, a six-character code input for an
   eight-digit code, and an auth call made synchronously inside
   onAuthStateChange that deadlocked with no error output. The defence is not
   "remember these" — it is that the app calls packages/db/auth.ts, whose
   signatures make all three unrepresentable. So this check enforces the
   routing rather than sniffing for the symptoms. */
if (!appSrc.length) pass('native otp discipline', 'apps/mobile absent — skipped');
else {
  const bad = [];
  for (const [rel, src] of appSrc) {
    if (rel === 'src/supabase.ts') continue;   /* the one file that builds the client */
    for (const [pat, why] of [
      [/emailRedirectTo/, 'emailRedirectTo — Gmail eats single-use link tokens'],
      [/\.auth\.signInWithOtp|\.auth\.verifyOtp/, 'calls Supabase auth directly — use requestEmailCode / verifyEmailCode'],
      [/\.auth\.onAuthStateChange/, 'subscribes directly — use onAuth, which defers the handler'],
      [/maxLength\s*[=:]\s*\{?\s*6\b/, 'a 6-character code input — Supabase issues 8'],
    ]) if (pat.test(src)) bad.push(`${rel}: ${why}`);
  }
  bad.length === 0
    ? pass('native otp discipline', 'auth routed through packages/db')
    : fail('native otp discipline', bad.slice(0, 3).join(' · '));
}

/* 14 · every RPC the phone calls has its grant ----------------------------
   Check 2 does this for index.html and reads only index.html, so the phone
   was invisible to it. D37 made grants explicit: a new RPC without
   `grant execute … to authenticated` does not error at build, at typecheck or
   in review — it 403s silently in prod, on a device, in front of a person. */
if (!appSrc.length) pass('native rpc grants', 'apps/mobile absent — skipped');
else {
  const raw = [];
  const names = new Set();
  for (const [rel, src] of appSrc) {
    for (const m of src.matchAll(/\.rpc\(\s*['"]([a-z0-9_]+)['"]/g)) {
      if (rel !== 'src/supabase.ts') raw.push(`${rel}: .rpc('${m[1]}') — call it through call() from @cs/db`);
    }
    for (const m of src.matchAll(/\bcall\(\s*\w+\s*,\s*['"]([a-z0-9_]+)['"]/g)) names.add(m[1]);
  }
  const granted = new Set(
    [...migs.matchAll(/grant\s+(?:all|execute)\s+on\s+function\s+(?:"?public"?\.)?"?([a-z0-9_]+)"?/gi)].map(m => m[1].toLowerCase()));
  const missing = [...names].filter(f => !granted.has(f));

  if (raw.length) fail('native rpc grants', raw.slice(0, 3).join(' · '));
  else if (missing.length) fail('native rpc grants', `no grant found for: ${missing.join(', ')} (silent 403 on the phone)`);
  else pass('native rpc grants', `${names.size} phone RPCs, all granted, none raw`);
}

/* ---------------------------------------------------------------------------
 * 15-17 · the Swift phone (D99).
 *
 * The same three lessons as 12-14, pointed at apps/ios. Generated/ is the
 * conversion boundary (Tokens.swift, Markers.swift, Rpc.swift) and is exempt
 * by construction: it is held to its sources by checks 10 and 11.
 * ------------------------------------------------------------------------ */
const iosDir = join(root, 'apps', 'ios');
const iosSrc = [];
if (existsSync(iosDir)) {
  const decomment = (src) => src
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .split('\n').map(l => l.replace(/(^|[^:])\/\/.*$/, '$1')).join('\n');
  const walk = (dir) => {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.name.startsWith('.') || e.name.endsWith('.xcodeproj') || e.name === 'DerivedData' || e.name === 'build') continue;   // `build/` = local derived data (gitignored), carries SDK example sources
      const full = join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.name.endsWith('.swift')) iosSrc.push([full.slice(iosDir.length + 1), decomment(readFileSync(full, 'utf8'))]);
    }
  };
  walk(iosDir);
}
const isGenerated = (rel) => rel.includes('/Generated/');

/* 15 · the phone names no colour of its own ------------------------------
   A hex literal outside Generated/ is allowed ONLY if the same hex appears in
   index.html — that makes it a conversion of something the web already
   renders (the dusk ground, the gold button's ink), never an invention. */
if (!iosSrc.length) pass('swift palette purity', 'apps/ios absent — skipped');
else {
  const webHexes = new Set([...html.matchAll(/#([0-9a-f]{6})\b/gi)].map(m => m[1].toUpperCase()));
  const hits = [];
  for (const [rel, src] of iosSrc) {
    if (isGenerated(rel)) continue;
    src.split('\n').forEach((line, i) => {
      for (const m of line.matchAll(/0x([0-9A-Fa-f]{6})\b|#([0-9A-Fa-f]{6})\b/g)) {
        const hex = (m[1] || m[2]).toUpperCase();
        if (!webHexes.has(hex)) hits.push(`${rel}:${i + 1} ${hex}`);
      }
      if (/Color\(\s*(red|\.sRGB|hue)/.test(line)) hits.push(`${rel}:${i + 1} Color(red/hue…)`);
    });
  }
  hits.length === 0
    ? pass('swift palette purity', `${iosSrc.length} files; every colour is a token or a web-verbatim conversion`)
    : fail('swift palette purity', `invented colour on the phone: ${hits.slice(0, 3).join(' · ')}${hits.length > 3 ? ` (+${hits.length - 3})` : ''}`);
}

/* 16 · the phone cannot reinvent the OTP landmines ------------------------
   Auth calls live in SupabaseService.swift and the auth stream in
   SessionStore.swift; nothing else may touch them, and no redirect URL may
   exist anywhere. */
if (!iosSrc.length) pass('swift otp discipline', 'apps/ios absent — skipped');
else {
  const bad = [];
  for (const [rel, src] of iosSrc) {
    const isAuthHome = rel.endsWith('SupabaseService.swift') || rel.endsWith('SessionStore.swift');
    for (const [pat, why, exempt] of [
      [/redirectTo|emailRedirectTo/, 'a redirect URL — Gmail eats single-use link tokens', false],
      [/\.auth\.(signInWithOTP|verifyOTP|signIn\(|signOut|authStateChanges|session\b)/, 'calls auth directly — go through SupabaseService', true],
      [/\.rpc\(\s*"/, 'raw .rpc("…") — call it through SupabaseService.call(Rpc.…)', true],
      [/otpLength\s*=\s*6|prefix\(6\)/, 'a six-digit code — Supabase issues 8', false],
    ]) if (pat.test(src) && !(exempt && isAuthHome)) bad.push(`${rel}: ${why}`);
  }
  bad.length === 0
    ? pass('swift otp discipline', 'auth routed through SupabaseService')
    : fail('swift otp discipline', bad.slice(0, 3).join(' · '));
}

/* 17 · every RPC the phone calls has its grant ----------------------------
   Generated/Rpc.swift only emits granted functions, so `Rpc.x` cannot name an
   ungranted one. This catches the other door: a hand-declared RpcCall (the
   documented exception while a migration awaits its snapshot refresh). */
if (!iosSrc.length) pass('swift rpc grants', 'apps/ios absent — skipped');
else {
  const names = new Set();
  for (const [rel, src] of iosSrc) {
    if (isGenerated(rel)) continue;
    for (const m of src.matchAll(/\bRpc\.([a-z0-9_]+)\s*\(/g)) names.add(m[1]);
    for (const m of src.matchAll(/static\s+let\s+name\s*=\s*"([a-z0-9_]+)"/g)) names.add(m[1]);
  }
  const granted = new Set(
    [...migs.matchAll(/grant\s+(?:all|execute)\s+on\s+function\s+(?:"?public"?\.)?"?([a-z0-9_]+)"?/gi)].map(m => m[1].toLowerCase()));
  const missing = [...names].filter(f => !granted.has(f));
  missing.length === 0
    ? pass('swift rpc grants', `${names.size} phone RPCs, all granted`)
    : fail('swift rpc grants', `no grant found for: ${missing.join(', ')} (silent 403 on the phone)`);
}

/* 18 · free identifiers (the `staged` lint) --------------------------------
   `node --check` (check 6) parses every block and is BLIND to a name that was
   never declared — which is how `invited: staged.length` survived D97's
   deletion of `staged`, shipped on 2026-08-04 and told every Pro "Lock failed"
   about a league the server had just locked. Twenty-five days, one lock_ok in
   prod telemetry against eleven lock_fail. This is the second time a free
   identifier reached production (F-007 was the first), so it gets a check.

   Method: parse each <script> block with acorn, resolve scopes with
   eslint-scope, and report every unresolved reference that is not (a) a
   browser/global builtin, (b) declared at the top level of ANOTHER classic
   block — they share one global scope — (c) bridged onto `window.*`
   somewhere in the file, or (d) the operand of a `typeof` guard.
   Dev-only deps; WARN (never PASS) when they are absent so a fresh clone
   cannot mistake "not installed" for "clean". */
{
  let acorn = null, escope = null;
  try { acorn = await import('acorn'); escope = await import('eslint-scope'); } catch { /* not installed */ }

  if (!acorn || !escope) {
    warn('free identifiers', 'acorn / eslint-scope not installed — run `npm ci` (dev-only; nothing is bundled or served)');
  } else {
    const BROWSER = new Set(`
      window document navigator location history screen console localStorage sessionStorage indexedDB caches
      fetch Request Response Headers FormData URL URLSearchParams Blob File FileReader AbortController
      setTimeout clearTimeout setInterval clearInterval queueMicrotask requestAnimationFrame cancelAnimationFrame
      requestIdleCallback alert confirm prompt getComputedStyle matchMedia scrollTo scrollBy open close
      Notification ServiceWorker PushManager BroadcastChannel MessageChannel Worker WebSocket EventSource
      Image Audio Option Event CustomEvent MouseEvent KeyboardEvent TouchEvent PointerEvent DragEvent
      Element HTMLElement Node NodeList DOMParser XMLSerializer MutationObserver IntersectionObserver ResizeObserver
      Object Array String Number Boolean Symbol BigInt Math JSON Date RegExp Error TypeError RangeError SyntaxError
      Map Set WeakMap WeakSet Promise Proxy Reflect Intl Function ArrayBuffer DataView Uint8Array Int8Array
      Uint16Array Int16Array Uint32Array Int32Array Float32Array Float64Array TextEncoder TextDecoder
      parseInt parseFloat isNaN isFinite encodeURIComponent decodeURIComponent encodeURI decodeURI
      atob btoa structuredClone crypto performance globalThis undefined NaN Infinity self top parent frames
      CSS AbortSignal ReadableStream WritableStream Element SVGElement customElements HTMLCanvasElement Path2D
      createImageBitmap OffscreenCanvas ImageData ClipboardItem MediaQueryList visualViewport speechSynthesis
      IntersectionObserverEntry getSelection Range Selection FontFace WeakRef FinalizationRegistry
    `.trim().split(/\s+/).filter(Boolean));

    /* names the module block hands to the classic ones (CLAUDE.md: the
       classic <-> module boundary is bridged explicitly through window.*) */
    const bridged = new Set([...html.matchAll(/window\.([A-Za-z_$][\w$]*)\s*=/g)].map(m => m[1]));

    const parseBlock = (code, isModule) => acorn.parse(code, {
      ecmaVersion: 'latest', sourceType: isModule ? 'module' : 'script',
      allowAwaitOutsideFunction: true, allowReturnOutsideFunction: true, locations: true,
      ranges: true,   /* eslint-scope reads node.range — without it every analyze() throws */
    });

    const scan = (label, code, isModule, sharedGlobals, lineOffset = 0) => {
      const guarded = new Set([...code.matchAll(/typeof\s+([A-Za-z_$][\w$]*)/g)].map(m => m[1]));
      const ast = parseBlock(code, isModule);
      const sm = escope.analyze(ast, {
        ecmaVersion: 2024, sourceType: isModule ? 'module' : 'script', ignoreEval: true,
      });
      const out = [];
      for (const ref of sm.globalScope.through) {
        const name = ref.identifier.name;
        if (BROWSER.has(name) || bridged.has(name) || sharedGlobals.has(name)) continue;
        /* `typeof X !== 'undefined'` is the codebase's deliberate guard for a
           name another script block may not have defined yet — and the whole
           point of the guard is that the next line then USES the name. So a
           name guarded anywhere in this block is guarded for the block. */
        if (guarded.has(name)) continue;
        out.push({ name, line: lineOffset + ref.identifier.loc.start.line, label });
      }
      return out;
    };

    /* every top-level name of every CLASSIC block is a global the others see */
    const blocks = [...html.matchAll(/<script(\s+type="module")?\s*>([\s\S]*?)<\/script>/g)]
      .filter(m => m[2].trim().length > 100)
      .map(m => ({
        isModule: !!m[1], code: m[2],
        line: html.slice(0, m.index).split('\n').length,   // 1-based line of <script>
      }));
    const sharedGlobals = new Set();
    for (const b of blocks.filter(b => !b.isModule)) {
      const sm = escope.analyze(parseBlock(b.code, false), { ecmaVersion: 2024, sourceType: 'script', ignoreEval: true });
      for (const v of sm.globalScope.variables) sharedGlobals.add(v.name);
    }

    const found = blocks.flatMap(b => scan('index.html', b.code, b.isModule, sharedGlobals, b.line));

    /* self-test: the fixture carries the real bug and three non-bugs */
    let selfTest = 'ok';
    const fixture = join(root, 'tests', 'fixtures', 'no-undef-staged.js');
    if (existsSync(fixture)) {
      const hits = scan('fixture', readFileSync(fixture, 'utf8'), false, new Set(['STRUCT_MIN'])).map(h => h.name);
      if (!hits.includes('staged')) selfTest = 'BROKEN — the fixture\'s `staged` was not detected';
      else if (hits.length !== 1) selfTest = `noisy — fixture also flagged ${hits.filter(h => h !== 'staged').join(', ')}`;
    } else selfTest = 'no fixture';

    if (selfTest !== 'ok') fail('free identifiers', `the checker itself is not trustworthy: ${selfTest}`);
    else if (found.length) fail('free identifiers',
      `${found.length} name(s) referenced but never declared — ${found.slice(0, 6).map(f => `${f.name} @ index.html:${f.line}`).join(', ')}`);
    else pass('free identifiers', `${blocks.length} blocks, no undeclared name (self-test ok)`);
  }
}

console.log(`\n${fails ? 'FAIL' : 'PASS'} — ${fails} failure(s), ${warns} warning(s)`);
process.exit(fails ? 1 : 0);
