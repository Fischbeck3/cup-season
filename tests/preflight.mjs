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

/* 7 · HTML template helpers may not interpolate a bare parameter (FAIL) -----
   REWRITTEN 2026-09-01. The heuristic that stood here required `innerHTML` AND
   a `${x.name}`-shaped interpolation ON THE SAME LINE. Almost nothing in this
   client is written that way — rendering goes through template-literal helpers
   whose return value is assigned to innerHTML somewhere else entirely — so the
   inspection window was very nearly empty, and it printed PASS for weeks while
   a stored XSS sat in the same file (the ship audit's S1: openLeagueSwitcher's
   `row()` interpolated an event NAME, author-controlled through create_event,
   straight into a <b>). A guard that cannot fail is worse than no guard: it
   spends the reader's trust without earning it.

   This checks the SHAPE of that bug instead. A helper that returns an HTML
   template literal cannot know anything about its arguments — they arrive from
   a caller, and the next caller may be passing user-authored text. So every
   PARAMETER interpolated bare (`${p}`, not `${esc(p)}` / `${Number(p)}` / a
   ternary) is a finding. It is deliberately narrow — four helpers in 20k lines
   — which is what makes it a FAIL rather than a warning.

   An exception must be named here, with its reason, and reviewed. */
{
  const ALLOWED = {
    /* helper name → parameters that are HTML BY DESIGN (caller-composed
       fragments), with the reason they cannot be escaped. */
    rowHtml: { extra: 'the major/round line is a composed fragment the callers build, not text' },
  };

  const helpers = [];
  const decl = /(?:const|let)\s+([A-Za-z_$][\w$]*)\s*=\s*\(([^)]*)\)\s*=>\s*`/g;
  let m;
  while ((m = decl.exec(html))) {
    const [name, params] = [m[1], m[2]];
    if (!params.trim()) continue;
    /* walk to the closing backtick, honouring nested ${ } */
    let i = m.index + m[0].length, depth = 0;
    for (; i < html.length; i++) {
      const c = html[i];
      if (c === '\\') { i++; continue; }
      if (c === '`' && depth === 0) break;
      if (c === '$' && html[i + 1] === '{') { depth++; i++; continue; }
      if (c === '}' && depth > 0) depth--;
    }
    const body = html.slice(m.index + m[0].length, i);
    if (!body.includes('<')) continue;   /* not an HTML template */
    const line = html.slice(0, m.index).split('\n').length;
    const bare = params.split(',')
      .map(p => p.trim().split('=')[0].trim())
      .filter(p => /^[A-Za-z_$][\w$]*$/.test(p))
      .filter(p => new RegExp('\\$\\{\\s*' + p + '\\s*\\}').test(body))
      .filter(p => !(ALLOWED[name] && ALLOWED[name][p]));
    if (bare.length) helpers.push({ name, line, bare });
  }

  /* self-test: the check must be able to fail, or it is the old one again. */
  const canary = 'const __canary = (x) => `<b>${x}</b>`;';
  const canaryCaught = /\$\{\s*x\s*\}/.test(canary) && canary.includes('<');

  if (!canaryCaught) {
    fail('html helper params escaped', 'self-test did not fire — the scan is inert');
  } else if (helpers.length) {
    helpers.forEach(h => fail('html helper params escaped',
      `${h.name}() at line ${h.line} interpolates ${h.bare.map(b => '${' + b + '}').join(', ')} raw — wrap in esc(), or name it in ALLOWED with a reason`));
  } else {
    pass('html helper params escaped', 'every HTML template helper escapes its parameters (1 reviewed exception)');
  }
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
  /* D270 merged the client's two :root blocks into one — the second, 2,287
     lines down the file, carried only `--grad` and `--glow`, and both are
     deleted. So a second block is now OPTIONAL and no longer required; if a
     future refresh splits them again, both are still read. */
  const r1 = cssBlock(':root');
  const r2 = r1 && cssBlock(':root', r1.end);
  const lt = cssBlock('html[data-theme="light"]');
  const problems = [];
  if (!r1 || !lt) problems.push('could not find the :root / light theme blocks in index.html');
  else {
    const gotDark = new Map([...decls(r1.body), ...(r2 ? decls(r2.body) : [])]);
    const gotLight = decls(lt.body);
    /* `alpha` and `track` are stored as bare NUMBERS (0.56; 0.09, a ratio of
       the rendered point size). A CSS declaration is always a string, so the
       comparison is string-to-string or every one of the fourteen fails. */
    for (const [name, spec] of want) {
      if (spec.dark !== undefined && gotDark.get(name) !== String(spec.dark))
        problems.push(`--${name} dark: client ${gotDark.get(name) ?? '(absent)'} != tokens.json ${spec.dark}`);
      if (spec.light !== undefined && gotLight.get(name) !== String(spec.light))
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
  /* build-db --check verifies BOTH generated artifacts (rpc.ts and the Swift
     Rpc.swift, which lives under apps/ios/). This used to swallow its output
     and report a hardcoded "rpc.ts is stale", so when the SWIFT artifact was
     the stale one — the likelier miss, because it sits outside packages/db and
     a `git add packages/db` leaves it behind — the message sent you to the
     wrong file. It did exactly that on 09e08da. Name what is actually stale. */
  let stale = false, staleWhich = '';
  try { execFileSync('node', [join(root, 'tools', 'build-db.mjs'), '--check'], { stdio: 'pipe' }); }
  catch (e) {
    stale = true;
    staleWhich = String(e.stdout || '').split('\n')
      .filter(l => l.includes('STALE'))
      .map(l => l.replace(/^\s*X STALE\s+/, '').split(' \u2014')[0].trim())
      .join(', ');
  }

  if (ghosts.length) fail('rpc exists in database', `client calls a function that is in neither prod nor a migration: ${ghosts.join(', ')}`);
  else if (stale) fail('rpc exists in database', `${staleWhich || 'a generated artifact'} is stale — run tools/build-db.mjs (it writes rpc.ts AND apps/ios/.../Rpc.swift)`);
  else pass('rpc exists in database', `${called.size} client RPCs, ${inProd.size} in the snapshot`);
  /* A pending function is a `supabase db push` the wave OWES, and every wave of
     the UX overhaul leaves one. What decides whether that is a warning is
     CLAUDE.md's own deploy-skew rule: a client ahead of the database must
     still render an honest screen. So the two cases are told apart rather
     than lumped together — an UNGUARDED call to a function prod does not have
     is a 404 a user can meet and stays a WARN; a call wrapped in its own
     try/catch (the declared-fallback shape) is reported, by name, as the push
     that is owed. Both are printed; only the dangerous one warns. */
  const guarded = f => [...html.matchAll(new RegExp(`\\.rpc\\(\\s*['"]${f}['"]`, 'g'))]
    .every(m => /\btry\s*\{/.test(html.slice(Math.max(0, m.index - 500), m.index))
             && /\bcatch\b/.test(html.slice(m.index, m.index + 900)));
  const risky = pending.filter(f => !guarded(f));
  const owed = pending.filter(guarded);
  if (risky.length) warn('rpc pending deploy', `called with no fallback and not yet in prod — owe a db push: ${risky.join(', ')}`);
  else if (owed.length) pass('rpc pending deploy', `owe a db push (each call is fallback-guarded): ${owed.join(', ')}`);
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

/* 19 · every join passes the covenant (Q-14 / D116) -----------------------
   Whether a golfer saw the terms they were agreeing to used to depend on
   which of five doors they came through: three called covenantGate first,
   two seated them straight away — including the invite-link boot path, the
   one that matters most. A comment cannot hold that; this can. */
{
  const joins = [...html.matchAll(/rpc\(\s*'join_league'/g)].length;
  const gates = [...html.matchAll(/covenantGate\s*\(/g)].length - 1;   // minus the declaration
  joins === 0
    ? warn('join paths carry consent', 'no join_league call found — did the RPC get renamed?')
    : gates >= joins
      ? pass('join paths carry consent', `${joins} join path(s), ${gates} covenant gate(s)`)
      : fail('join paths carry consent', `${joins} join_league call(s) but only ${gates} covenantGate() — a golfer can be seated without seeing the terms`);
}

/* 20 · the two clients share one stage vocabulary (D120) ------------------
   The blind audit found the same league described five different ways in one
   session, partly because the web and the phone each invented their own
   status strings. Six words, one meaning each, and neither client may drift:
   this compares index.html's STAGE_LABEL to CupSeasonKit's Stage.label. */
{
  const webTable = (html.match(/const STAGE_LABEL = \{([\s\S]*?)\};/) || [])[1] || '';
  const web = Object.fromEntries([...webTable.matchAll(/(\w+)\s*:\s*'([^']+)'/g)].map(m => [m[1], m[2]]));
  const copyPath = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'League', 'LeagueCopy.swift');
  if (!existsSync(copyPath)) pass('stage vocabulary shared', 'apps/ios absent — skipped');
  else {
    const swiftSrc = readFileSync(copyPath, 'utf8');
    const swiftBlock = (swiftSrc.match(/public var label: String \{([\s\S]*?)\n {4}\}/) || [])[1] || '';
    const swift = Object.fromEntries([...swiftBlock.matchAll(/case \.(\w+):\s*return "([^"]+)"/g)].map(m => [m[1], m[2]]));
    const keys = [...new Set([...Object.keys(web), ...Object.keys(swift)])];
    const drift = keys.filter(k => web[k] !== swift[k])
      .map(k => `${k}: web ${JSON.stringify(web[k] ?? null)} vs phone ${JSON.stringify(swift[k] ?? null)}`);
    if (!keys.length) fail('stage vocabulary shared', 'neither table found — did STAGE_LABEL or Stage.label get renamed?');
    else drift.length === 0
      ? pass('stage vocabulary shared', `${keys.length} stages agree across both clients`)
      : fail('stage vocabulary shared', drift.join(' · '));
  }
}

// ---- 21 · PostgREST embeds name their FK -----------------------------------
// D171: `game_results` and `live_scores` both carry columns to live_rounds AND
// live_round_players, so PostgREST sees a junction path beside the direct one
// and refuses the embed with HTTP 300 / PGRST201. The web hit this and fixed it
// (M-085); the phone was ported WITHOUT the hint, so every server-side round
// discovery on iOS returned 300 and the invited golfer never found the round.
// It was invisible for weeks because the starter resumes from a local snapshot.
{
  const offenders = [];
  for (const [label, file] of [
    ['web', join(root, 'index.html')],
    ['phone', join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Live', 'LiveRepository.swift')],
  ]) {
    if (!existsSync(file)) continue;
    for (const m of readFileSync(file, 'utf8').matchAll(/live_round_players(!?)([A-Za-z_]*)\s*\(/g)) {
      if (m[1] !== '!' || !m[2]) offenders.push(`${label}: live_round_players( without !fk`);
    }
  }
  offenders.length === 0
    ? pass('postgrest embeds name their FK', 'live_round_players embeds are disambiguated')
    : fail('postgrest embeds name their FK', [...new Set(offenders)].join(' · ') +
        ' — PostgREST returns 300 PGRST201; use live_round_players!live_round_players_live_round_id_fkey(...)');
}

/* 22 · nobody stamps their own platform (D234) -----------------------------
   `platform` was hand-written in four Swift call sites and nowhere else, and
   the web wrote it in none, so no row in `client_events` could be split by
   client — the phone's rows and the web's were the same rows, and every rate
   in the design set was unmeasurable. The stamp now lives in exactly one place
   on each client: `CSTelemetry.event` (via `stamped`) and `qaEvent`. A caller
   that types its own is not a style choice — it is a second producer for a
   fact that has one, so it fails the push.

   Scope: `.swift` under apps/ios (build/checkout trees excluded, since the
   SPM checkouts carry asset catalogues with a `"platform"` key), and
   index.html outside `qaEvent`'s own body. `p_platform` (the
   register_device_token argument) is a different word and is not matched. */
{
  const offenders = [];

  const iosRoot = join(root, 'apps', 'ios');
  const SKIP = new Set(['build', '.build', 'DerivedData', 'CupSeason.xcodeproj', 'Screenshots']);
  const swift = [];
  const walk = dir => {
    let entries;
    try { entries = readdirSync(dir, { withFileTypes: true }); } catch { return; }
    for (const e of entries) {
      if (e.name.startsWith('.') && e.name !== '.build') continue;
      if (SKIP.has(e.name)) continue;
      const full = join(dir, e.name);
      if (e.isDirectory()) walk(full);
      else if (e.name.endsWith('.swift')) swift.push(full);
    }
  };
  if (existsSync(iosRoot)) walk(iosRoot);

  /* Two files may name the client, and they are the rule itself: the stamp,
     and the suite that pins it. Named one by one rather than by directory —
     exempting every test file would let a fixture quietly grow a second
     producer for the same fact. */
  const STAMPS = ['CupSeasonKit/Telemetry.swift', 'CupSeasonKitTests/TelemetryTests.swift'];
  for (const f of swift) {
    if (STAMPS.some(x => f.endsWith(x))) continue;
    const src = readFileSync(f, 'utf8');
    if (/(?<![\w_])"platform"\s*:/.test(src))
      offenders.push(`${f.slice(root.length)} writes its own "platform" (the stamp is CSTelemetry.event)`);
  }

  /* the web's single stamp is inside qaEvent; anywhere else in index.html is a
     second producer for the same fact */
  const qa = html.match(/function qaEvent\(event, props\)\{[\s\S]*?\n\}/);
  const qaStart = qa ? qa.index : -1;
  const qaEnd = qa ? qa.index + qa[0].length : -1;
  if (!qa) offenders.push('index.html: qaEvent not found — did the web\u2019s one stamp get renamed?');
  else if (!/platform:\s*CS_PLATFORM/.test(qa[0]))
    offenders.push('index.html: qaEvent no longer stamps platform — every web row would go unlabelled');
  for (const m of html.matchAll(/(?<![\w_$])platform\s*:/g)) {
    if (m.index >= qaStart && m.index < qaEnd) continue;
    offenders.push(`index.html: a "platform" key at offset ${m.index} outside qaEvent`);
  }

  offenders.length === 0
    ? pass('nobody stamps their own platform', `${swift.length} Swift file(s) + index.html — one stamp per client`)
    : fail('nobody stamps their own platform', offenders.join(' · '));
}

/* 23 · the declared fallback exists (IOS-029b, D231) ------------------------
   Wave 1b deleted `HomeMode`, `HomeLead`, `HomeHeroCopy` and `HomeLeagueRow`,
   so "render as today" is not a fallback any more — there is no today left to
   render. `HomeFallbackItems` IS the fallback: a client whose database is
   behind it composes items from `native_home` + `home_feed`, in a static
   tier-less order, with no lead card. The owner applies migrations by hand,
   so a client-ahead deploy is a real Tuesday and not a hypothetical.

   Three things fail the push: the producer missing from the Kit, Home not
   calling it, and Home calling `home_dispatch` without a fallback branch. */
{
  if (!iosSrc.length) pass('the declared fallback exists', 'apps/ios absent — skipped');
  else {
    const problems = [];
    const producer = iosSrc.find(([rel]) => rel.endsWith('CupSeasonKit/Home/HomeFallbackItems.swift'));
    if (!producer) problems.push('HomeFallbackItems.swift is gone from the Kit — Home has no renderer on a client-ahead deploy');
    else if (!/enum\s+HomeFallbackItems\b/.test(producer[1]))
      problems.push('HomeFallbackItems.swift no longer declares HomeFallbackItems');
    else if (!/fallbackOrder/.test(producer[1]))
      problems.push('the fallback no longer sorts by the static tier order (CLOSING → CHANGED → COMING → CIRCLE)');

    const home = iosSrc.find(([rel]) => rel.endsWith('CupSeason/Home/HomeView.swift'));
    if (!home) problems.push('HomeView.swift is gone');
    else {
      if (!/HomeFallbackItems\.make\(/.test(home[1]))
        problems.push('HomeView never calls HomeFallbackItems.make — the fallback would ship dead');
      if (!/HomeRank\.arrange\(/.test(home[1]) && !/vm\.ranked\(/.test(home[1]))
        problems.push('HomeView never arranges the dispatch — the veto and the fence would not be re-applied');
    }
    problems.length === 0
      ? pass('the declared fallback exists', 'HomeFallbackItems is in the Home target and Home calls it')
      : fail('the declared fallback exists', problems.join(' · '));
  }
}

/* 24 · every nav destination lands somewhere real (D222, IOS-028) -----------
   The five slots became real destinations this wave, and a `switchView` to a
   name with no pane deactivates every pane and drops the golfer on a BLANK
   SCREEN with a clean console. That is not hypothetical: `csItemDoor`'s live
   route pointed at a `view-live` that has never existed, and it took a human
   reading the file to find it — no test could, because the browser suite only
   runs in a browser and the gate that stops a push is this file.

   So: every `data-v` on a `.navitem` or a `.tab`, resolved through the router's
   own alias table (`csViewFor`, read out of the source rather than restated
   here), must name a `<section id="view-…">` that exists — or `board`, which is
   a full-screen dialog rather than a pane and is named as the one exception. */
{
  const nav = [...html.matchAll(/<button[^>]*class="(?:navitem|tab)[^"]*"[^>]*data-v="([a-z-]+)"/g)].map(m => m[1]);
  const navAlt = [...html.matchAll(/<button[^>]*data-v="([a-z-]+)"[^>]*class="(?:navitem|tab)[^"]*"/g)].map(m => m[1]);
  const items = [...new Set(nav.concat(navAlt))];
  const views = new Set([...html.matchAll(/id="view-([a-z-]+)"/g)].map(m => m[1]));

  /* the alias table, read from the router itself — a rename made there and not
     here would otherwise pass this check while breaking the page */
  const fn = html.match(/function csViewFor\(v\)\{([\s\S]*?)\n\}/);
  const alias = {};
  if (fn) for (const m of fn[1].matchAll(/if\(v==='([a-z-]+)'\)\s*return\s*'([a-z-]+)'/g)) alias[m[1]] = m[2];

  const problems = [];
  if (!items.length) problems.push('no nav items found — the selector or the markup moved');
  if (!fn) problems.push('csViewFor is gone — the router has no alias table to read');
  for (const v of items) {
    const target = alias[v] || v;
    if (target === 'board') continue;                 // a dialog, not a pane
    if (!views.has(target)) problems.push(`${v} → view-${target}, which does not exist`);
  }
  /* and the aliases themselves, so an old link cannot blank the page either */
  for (const [from, to] of Object.entries(alias)) {
    if (to !== 'board' && !views.has(to)) problems.push(`alias ${from} → view-${to}, which does not exist`);
  }
  /* self-test: the check has to be able to see a broken one */
  {
    const broken = html.replace('data-v="compete"', 'data-v="notaview"');
    const bItems = [...new Set([...broken.matchAll(/<button[^>]*class="(?:navitem|tab)[^"]*"[^>]*data-v="([a-z-]+)"/g)].map(m => m[1]))];
    if (!bItems.some(v => !views.has(alias[v] || v) && (alias[v] || v) !== 'board'))
      problems.push('self-test failed: the check cannot see a nav item pointing at a missing view');
  }
  problems.length === 0
    ? pass('every nav destination resolves', `${items.length} nav item(s) + ${Object.keys(alias).length} alias(es) → live panes`)
    : fail('every nav destination resolves', problems.join(' · '));
}


/* 25 · report and block survive the redesign (L-38, Guideline 1.2) ----------
   L-38 is in the immutable wall — "Report, block (mute), hide/unhide, suspend,
   delete account exist on every surface where content is, and SURVIVE ANY
   REDESIGN" — and this build is exactly the kind of change that loses it: the
   Tour Card SHEET carried mute and the two-step report, and wave 5 promoted it
   to a page. A page without them drops report and block from the surface a
   golfer most often reaches a person on, and App Review rejects for it.

   So the check is a list, and the list is the acceptance test
   (`COMPONENT_SYSTEM.md` P-17, `INFORMATION_ARCHITECTURE.md` §18.1 test 4):
   every surface that renders another golfer's content reaches the safety
   block, on BOTH clients, and the block itself still holds all three verbs.

   It does NOT look for a control named "Block". This product has no block
   mechanic; L-38's own wording is "block (mute)" and
   `docs/ios/app-review-notes.md` already tells App Review that Mute is the
   block here. A menu item over a mechanic that does not exist is what L-32 and
   L-44 forbid, so what is checked is the verb that actually runs. */
{
  const problems = [];

  /* --- the phone --- */
  const swift = new Map(iosSrc);
  const safety = swift.get('CupSeason/People/SafetyMenu.swift');
  if (!safety) problems.push('CupSeason/People/SafetyMenu.swift is gone — P-17 has no producer');
  else {
    /* the block itself holds all three verbs and the report is still two-step */
    if (!/set_mute|setMute/.test(safety)) problems.push('SafetyMenu no longer mutes (L-38 block)');
    if (!/report/i.test(safety)) problems.push('SafetyMenu no longer reports (L-38)');
    if (!/hideThis/.test(safety)) problems.push('SafetyMenu lost "Hide this" (L-38 hide)');
    if (!/reasons/.test(safety) || !/Pick a reason|Send this report/.test(safety))
      problems.push('the report lost its two steps — one tap is an accident');
  }

  /* every surface that renders another golfer's content, by name. Adding a
     person surface without adding it here is the omission this list exists to
     make loud; adding it here without mounting P-17 fails the push. */
  const mounts = [
    ['CupSeason/Golfers/PersonPage.swift',    /CSSafetyMenu\(/],
    ['CupSeason/Golfers/HeadToHeadPage.swift', /CSSafetyMenu\(/],
    /* the peek sheet keeps its OWN copy, unchanged — the promotion did not
       take mute or the two-step report off it */
    ['CupSeason/You/TourCardSheet.swift',     /setMute|toggleMute/],
    ['CupSeason/You/TourCardSheet.swift',     /Sure\? Report/],
  ];
  for (const [rel, pat] of mounts) {
    const src = swift.get(rel);
    if (!src) { problems.push(`${rel} is missing — a person surface cannot be checked`); continue; }
    if (!pat.test(src)) problems.push(`${rel} renders another golfer and cannot reach report/mute (L-38)`);
  }

  /* --- the web, or Guideline 1.2 is only half-answered --- */
  if (!/function csSafetyMenuHtml\(/.test(html)) problems.push('the web has no P-17 producer (csSafetyMenuHtml)');
  if (!/p_kind:\s*'profile'/.test(html)) problems.push('the web safety block no longer reports a golfer');
  if (!/rpc\('set_mute'/.test(html)) problems.push('the web safety block no longer mutes');
  for (const fn of ['openPerson', 'openHeadToHead']) {
    const a = html.indexOf('async function ' + fn + '(');
    const b = html.indexOf('window.' + fn + ' = ' + fn + ';');
    if (a < 0 || b < a) { problems.push(`the web's ${fn} is gone — a person surface cannot be checked`); continue; }
    if (!/csSafetyMenuHtml\(/.test(html.slice(a, b)))
      problems.push(`the web's ${fn} renders a golfer with no P-17 (L-38)`);
  }

  /* self-test: the check has to be able to see a surface that lost it */
  {
    const stripped = (swift.get('CupSeason/Golfers/PersonPage.swift') || '').replace(/CSSafetyMenu\(/g, 'EmptyView(');
    if (/CSSafetyMenu\(/.test(stripped)) problems.push('self-test failed: the phone half cannot see a stripped surface');
    const webStripped = html.replace(/csSafetyMenuHtml\(/g, 'noop(');
    if (/function csSafetyMenuHtml\(/.test(webStripped) || /csSafetyMenuHtml\(/.test(webStripped))
      problems.push('self-test failed: the web half cannot see a stripped surface');
  }

  problems.length === 0
    ? pass('report and block survive the redesign', `${mounts.length} phone surface(s) + 2 web page(s) reach P-17`)
    : fail('report and block survive the redesign', problems.slice(0, 4).join(' · '));
}

/* 26 · the anon surface is EXACTLY twelve (L-45, D241, D253) --------------
   Wave 6 adds two share KINDS and two landing pages, and the single thing
   that would make that a bad trade is a thirteenth signed-out endpoint. Two
   Phase-2 proposals answered the same question with exactly that; D250
   declines one in writing, and this is the check that makes the decline
   mechanical rather than a sentence in a log nobody greps.

   It reads the `grant execute … to anon` list OUT OF THE MIGRATION TREE and
   compares it against the twelve NAMED IN CLAUDE.md — parsed from the file,
   not restated here, so a name added to the prose and not to a migration (or
   the reverse) fails the push. `tests/db-checks.sql` check 2 asserts the same
   set against the LIVE database; this one catches it before the push, which
   is the only moment it is still cheap.

   `redeem_share` is the wave's own tripwire: it is the thirteenth
   AUTHENTICATED function, and if it ever appears in the anon list this check
   is what says so. */
{
  const problems = [];
  const claude = readFileSync(join(root, 'CLAUDE.md'), 'utf8');

  /* the twelve, from CLAUDE.md's own paragraph — the seven listed by name
     plus the five named in the parenthetical (the D86 guest trio, door_flags,
     log_growth_event) */
  const paraStart = claude.indexOf('to `anon` only for the twelve public endpoints');
  const paraEnd = claude.indexOf('A new\n  RPC that "silently 403s in prod"', paraStart);
  const para = paraStart < 0 ? '' : claude.slice(paraStart, paraEnd < 0 ? paraStart + 2000 : paraEnd);
  if (!para) problems.push('CLAUDE.md no longer names the twelve anon endpoints — the list has no source');
  const declared = new Set([...para.matchAll(/`([a-z0-9_]+)`/g)].map(m => m[1])
    .filter(n => /_/.test(n) || n === 'anon' ? n !== 'anon' : false));
  if (para && declared.size !== 12) {
    problems.push(`CLAUDE.md names ${declared.size} anon endpoints, not twelve: ${[...declared].sort().join(', ')}`);
  }

  /* What the migration tree actually grants. The tree is replayed in FILE
     ORDER, statement by statement, exactly as `db push` applies it — because
     the answer depends on the order: D37's own migration
     (20260718172300:74) carries `revoke execute on all functions in schema
     public from anon`, which wipes every grant made before it, and nine
     functions from the pre-D37 era (join_league, form_squads, cup_points …)
     would otherwise still read as anon-callable here. A blanket revoke is a
     statement about the whole set, so it has to clear the whole set. */
  const STMT = /\b(grant|revoke)\s+(?:all(?:\s+privileges)?|execute)\s+on\s+(all\s+functions\s+in\s+schema\s+"?public"?|function\s+(?:"?public"?\.)?"?([a-z0-9_]+)"?\s*\([^)]*\))\s*(?:from|to)\s+([^;]+);/gi;
  const files = readdirSync(migDir).filter(f => f.endsWith('.sql')).sort();
  const anonGranted = new Set();
  for (const f of files) {
    const src = readFileSync(join(migDir, f), 'utf8');
    for (const m of src.matchAll(STMT)) {
      const verb = m[1].toLowerCase(), target = m[2].toLowerCase(), fn = (m[3] || '').toLowerCase();
      const roles = m[4].toLowerCase();
      if (!/\banon\b|\bpublic\b/.test(roles)) continue;
      if (target.startsWith('all functions')) {
        /* only a REVOKE is meaningful here; a blanket grant to anon has never
           been written in this repo and would fail check 2's sibling anyway */
        if (verb === 'revoke') anonGranted.clear();
        continue;
      }
      if (verb === 'grant') { if (/\banon\b/.test(roles)) anonGranted.add(fn); }
      else anonGranted.delete(fn);
    }
  }

  const extra = [...anonGranted].filter(f => !declared.has(f)).sort();
  const missing = [...declared].filter(f => !anonGranted.has(f)).sort();
  if (extra.length) problems.push(`granted to anon but not one of the twelve: ${extra.join(', ')}`);
  if (missing.length) problems.push(`named in CLAUDE.md but never granted to anon: ${missing.join(', ')}`);

  /* the wave's own tripwire, stated by name so it cannot be lost in a diff */
  if (anonGranted.has('redeem_share')) {
    problems.push('redeem_share is granted to anon — the person and plan links write, and the write is never anonymous (D241)');
  }

  /* self-test: the check must be able to SEE a thirteenth. Synthesised, not
     written to disk — a check that cannot fail is not a check. */
  {
    const probe = "grant execute on function public.a_thirteenth_endpoint(uuid) to anon, authenticated;";
    const seen = new Set(anonGranted);
    for (const m of probe.matchAll(new RegExp(STMT.source, 'gi'))) {
      if (/\banon\b/.test(m[4].toLowerCase())) seen.add((m[3] || '').toLowerCase());
    }
    if (!seen.has('a_thirteenth_endpoint') || seen.size !== anonGranted.size + 1) {
      problems.push('self-test failed: the parser cannot see a thirteenth anon grant');
    }
  }

  problems.length === 0
    ? pass('the anon surface is exactly twelve', `${anonGranted.size} function(s), and CLAUDE.md names the same ${declared.size}`)
    : fail('the anon surface is exactly twelve', problems.slice(0, 3).join(' · '));
}

/* 27 · one vocabulary, one lint per law (D249, IOS-036) -------------------
   TERMINOLOGY.md §4 is the ship list: twenty-nine patterns, each guarding a
   ruling that has already drifted back once because it was only a sentence.
   D131 was "copy-only, ~90 strings"; four of its retired phrasings were
   written back into this programme's own proposed copy before anybody noticed.
   So each law gets a grep, and a hit fails the push.

   The scope is §4's: `apps/ios/CupSeason/**`, the Kit's Sources, `index.html`,
   the store listing, and the board/push/ledger generators in SQL. Comments,
   `Tests/` and the generated files are out. And the rule that makes it usable
   at all — "a string is exempt because it is an IDENTIFIER, never because of
   where it lives" — is why this reads `tools/extract-strings.mjs` rather than
   grepping: `.select("id,differential,…")` is a column list, `class="pvi …"`
   is a class name, and a lint that cries wolf on those gets switched off. */
{
  const T = await import('../tools/extract-strings.mjs');
  const listingPath = join(root, 'docs', 'ios', 'app-store-listing.md');
  const listing = existsSync(listingPath) ? readFileSync(listingPath, 'utf8') : '';

  /* Exempt BY CALL SITE. Each entry is the exact sentence and the reason it is
     the other sense of the word — the profile sense of "your card", the auth
     sense of "session", the season award that owns "Iron Man". A new exemption
     is an argument with §4, which is the point of writing them out. */
  const EXEMPT = new Map([
    ['A reference on your card — we never resell or verify it. Leave it blank if you’d rather not.', 'GHIN, the profile sense (§4 row 7)'],
    ["A reference on your card — we never resell or verify it. Leave it blank if you'd rather not.", 'GHIN, the profile sense (§4 row 7)'],
    ['Adding a GHIN number? It lives on your card, under You.', 'the profile sense — the card is the person (§4 row 7)'],
    ['Restoring your session', 'the auth session (§4 row 10)'],
    ['The code was accepted but no session came back.', 'the auth session (§4 row 10)'],
    ['no session in storage — showing the door', 'the auth session (§4 row 10)'],
    ['session ✓', 'the auth session (§4 row 10)'],
    ['Iron Man', 'the season award, which keeps the name (§2.1)'],
    /* §4.32 · "playing number" HAD a receipt-shaped exemption (TERMINOLOGY line
       84 + note 1). R-M retires the term itself: the figure is a PLAYING HCP,
       on the receipt and everywhere else, so the exemptions are gone and the
       law now bites on every surface. Check 42 is the other half — it holds
       the five band labels still while this one moves the gloss. */
  ]);
  const exemptPrefix = [
    ['Iron Man ', 'the season award row (§2.1)'],
    ['Points King takes', 'the awards footnote, where the award is named (§2.1)'],
  ];
  const isExempt = t => EXEMPT.has(t.trim()) || exemptPrefix.some(([p]) => t.trim().startsWith(p));

  /* §4's table. `sql` marks the two rows whose scope includes the generators
     (A-1: the ledger's reason strings and the stage strings are written in
     SQL and rendered by both clients). */
  const LAWS = [
    [1, 'the counting cap is a sentence', [/counting\s+cap/i]],
    [2, 'the minimum, never a floor', [/participation\s+floor/i, /month\s+floor/i, /floor\s+penalty/i]],
    [3, 'the allowance is a number, not a term', [/handicap\s+allowance/i, /%\s?hcp\b/i]],
    [4, 'no dial names as row keys', [/\b(PRESET|STRUCTURE|VERIFICATION)\b/]],
    /* §2.3's lock row retires four phrasings and `SQUADS LOCKED` is the fourth
       — the same family, in the same ruling, and the one the kickoff hero
       carried. */
    /* F-5 · widened the way check 7 was: a ruling with one grep behind it lets
       every other inflection ship. `lock them in` walked past `lock it in` on
       the wizard's own eyebrow, and `HAS LOCKED A CUP SEED` walked past
       `SEEDS LOCKED` on the season page. */
    [5, 'the season starts; nothing locks', [/lock the bylaws/i, /lock (it|them) in/i, /\bseeds? locked\b/i, /rosters locked/i, /squads locked/i, /\bhas locked\b/i, /\bmore locks\b/i], { sql: true }],
    [6, 'the rules, never the bylaws', [/bylaws/i]],
    [7, 'a round posts to your rounds', [/\bon your card\b/i, /hit your card/i, /pinned to your card/i]],
    [8, 'one money noun', [/post a stake/i, /the other stakes/i, /pot sheet/i, /prize pool/i]],
    [9, 'the clash, never the duel', [/\bduels?\b/i]],
    [10, 'a week, never a session', [/\bsessions?\b/i]],
    [11, 'no Clubhouse', [/clubhouse/i]],
    [12, 'one lens (L-14)', [/\bdifferentials?\b/i, /\bPvI\b/, /vs index/i, /\bIDX\b/]],
    [13, 'the schedule, never the tee sheet', [/tee\s+sheets?\b/i], { sql: true }],
    [14, 'the draw, never a draft', [/\bdrafts?\b/i, /draft night/i, /the hat shuffles/i]],
    [15, 'vouched by the group', [/attest/i]],
    [16, 'never a printed seat count', [/seats?\s+open/i, /\b\d+\s+seats?\b/i, /\bSEATS\b/]],
    [17, 'the six stage words only', [/LIVE NOW/, /CAPTAINS READY/, /The Pro has the list/i, /captains draft/i], { sql: true, listing: true }],
    [18, 'the live round says the word', [/RIDING/, /DIED CARRIED/, /BRAGGING POINTS/, /\b3U\b/, /EST .*IDX/, /\bSTK\b/, /\bSELF\b/, /\bSI \d/]],
    [19, 'the ledger says the consequence', [/MONTH FORFEITED/i, /floors? waived/i, /month forfeited/i, /\/mo — posted/i, /^Floor $/], { sql: true }],
    [20, 'the Pro, never the commissioner', [/commissioner/i]],
    [21, 'trophies, never hardware', [/stage it/i, /display case/i, /\bhardware\b/i]],
    /* F-5 · the same widening. "league mate" was the only inflection grepped;
       "leaguemates", "your league mates" and the possessive all walked past. */
    [22, 'in your seasons, never a league mate', [/league\s?-?mates?/i, /mates? in your league/i], { sql: true }],
    [23, 'Iron Man is the award, not the streak', [/iron\s?man/i]],
    [24, 'milestones and results', [/moments, reveals/i]],
    /* F-3 · this guarded the wrong direction. `OWNER_RULINGS.md` R-D rules the
       head YOUR MOMENTS, and the check failed the push on the owner's own
       word because `TERMINOLOGY.md` A-4 had proposed MATCHES & WEEKENDS
       instead. The ruling ships; the lint holds the ruling. */
    [25, 'the ruled section heads (R-D)', [/MATCHES\s*&(amp;)?\s*WEEKENDS/i]],
    [26, 'one verb opens the composer', [/^post (a )?round$/i]],
    /* 27–29 are producer greps and payload greps, not string greps */
    [28, 'no gross target off another golfer’s number', [/needs \d+ off (his|her|their)/i, /\bhe needs \d/i, /\bshe needs \d/i]],
    [29, 'no invented split', [/winner takes \d+%/i, /\d+% of the pot/i]],
    /* 30–33 · the four rulings the Repair phase found had drifted back with no
       lint behind them. D249's thesis, proved four more times. */
    [30, 'a golfer’s card, never a Tour Card', [/\bTour Cards?\b/i]],
    [31, 'not on a squad yet, never the pool', [/\bthe pool\b/i, /\bin the pool\b/i]],
    /* R-M · the term is retired, not scoped: the noun is "playing HCP". */
    [32, 'the playing figure is an HCP, never a number', [/playing number/i]],
    [33, 'league is never a thing you start or join', [/\b(start|join|create)\s+(a|your|the)\s+leagues?\b/i]],
    /* 34 · R-J. The fourth intent reads "Go head to head". `I want to beat one
       guy` was the only one of four that began "I want to", it read as cringe,
       and it was the one sentence not addressed to every golfer in a mixed
       league. It is retired on both clients, and this is what keeps it retired
       — D249's whole thesis is that a ruling with no grep behind it comes back. */
    [34, 'the fourth intent is Go head to head (R-J)', [/beat one guy/i, /\bbeat one\b/i]],
  ];

  const hits = [];
  const record = (law, where, text) => hits.push(`§4.${law[0]} ${law[1]} — ${where}: ${JSON.stringify(text.slice(0, 70))}`);
  /* A web template is one literal carrying a whole pane; the Swift side is one
     sentence at a time. Split a blob on its own tags and newlines so a hit
     names the SENTENCE, and so the profile-sense exemptions (which are exact
     sentences) can still match inside one. */
  const fragments = text => (/[<\n]/.test(text)
    ? text.split(/<[^>]*>|\n/).map(x => x.trim()).filter(Boolean)
    : [text]);
  const scan = (law, where, text) => {
    for (const frag of fragments(text)) {
      if (isExempt(frag)) continue;
      if (law[2].some(re => re.test(frag))) { record(law, where, frag); return; }
    }
  };

  /* the phone */
  const swift = T.swiftSources(join(root, 'apps', 'ios'));
  for (const f of swift) {
    const rel = f.slice(root.length).replace(/^\//, '');
    for (const s of T.swiftProse(readFileSync(f, 'utf8'))) {
      for (const law of LAWS) scan(law, `${rel}:${s.line}`, s.text);
    }
  }
  /* the desk */
  for (const s of T.webProse(html)) {
    for (const law of LAWS) scan(law, `index.html:${s.line}`, s.text);
  }
  /* the store listing — §4 row 17 names it by name */
  {
    /* the STORE SUBSET (§4 row 17): the fields that are pasted into App Store
       Connect — §1-§5 and §8. The file's own change notes are documentation
       about the copy, not the copy. */
    const lines = listing.split('\n');
    let shipping = false;
    for (const [i, line] of lines.entries()) {
      const h = line.match(/^## (\d+)\./);
      if (h) shipping = ['1', '2', '3', '4', '5', '8'].includes(h[1]);
      if (!shipping) continue;
      for (const law of LAWS.filter(l => l[3]?.listing)) scan(law, `docs/ios/app-store-listing.md:${i + 1}`, line);
    }
  }
  /* the database. Only the LIVE definition of each function is scanned — an
     older migration cannot be edited (L-05), so the sentence that ships is the
     last `create or replace`. Only the generators (a function that writes a
     board post, a nudge or a ledger reason) and never a `raise exception`,
     which is an error message rather than the ledger's own voice. */
  const liveDefs = new Map();
  for (const f of readdirSync(migDir).filter(x => x.endsWith('.sql')).sort()) {
    const src = readFileSync(join(migDir, f), 'utf8');
    const re = /create\s+or\s+replace\s+function\s+(?:public\.)?"?([a-z0-9_]+)"?\s*\(([\s\S]*?)\n[^\n]*(?:\$function\$|\$\$|\$fn\$)\s*;/gi;
    let m;
    while ((m = re.exec(src))) liveDefs.set(m[1].toLowerCase(), { file: f, body: m[0] });
  }
  const sqlLaws = LAWS.filter(l => l[3]?.sql);
  for (const [name, { file, body }] of liveDefs) {
    if (!/insert\s+into\s+(posts|push_nudges|season_adjustments)\b/i.test(body)) continue;
    const lines = body.split('\n');
    for (const s of T.sqlStrings(body)) {
      if (/raise\s+(exception|notice|warning)/i.test(lines[s.line - 1] || '')) continue;
      for (const law of sqlLaws) scan(law, `${file} ${name}()`, s.text);
    }
  }

  /* §4.27 · TWO PRODUCERS FOR ONE FACT — code greps, not string greps. The
     check §4 calls the one that matters: a string lint holds a word steady, a
     producer lint holds a FACT steady. */
  const bandWords = /Torched it|Beat your number|Played to it|A little loose|Posted anyway/;
  const BAND_HOMES = ['Board/CSBands.swift'];
  for (const f of swift) {
    if (BAND_HOMES.some(h => f.endsWith(h))) continue;
    for (const s of T.swiftProse(readFileSync(f, 'utf8'))) {
      if (bandWords.test(s.text)) hits.push(`§4.27 a second band table — ${f.slice(root.length).replace(/^\//, '')}:${s.line}: ${JSON.stringify(s.text.slice(0, 40))}`);
    }
  }
  {
    const web = html.match(/function bandName\(vs\)\{[\s\S]*?\n\}/);
    if (!web) hits.push('§4.27 index.html has no bandName() — did the web’s band producer move?');
    /* the five reads live in the two functions that ARE the producer — the
       band's name and the points sentence that has to agree with it, the same
       pair `CSBands.swift` holds on the phone. Anywhere else is a copy. */
    const lineOfOffset = off => html.slice(0, off).split('\n').length;
    const homes = [];
    for (const m of [web, html.match(/function pointsFor\(vs\)\{[\s\S]*?\n\}/)]) {
      if (m) homes.push([lineOfOffset(m.index), lineOfOffset(m.index + m[0].length)]);
    }
    for (const s of T.webProse(html)) {
      if (!bandWords.test(s.text)) continue;
      if (homes.some(([a, b]) => s.line >= a && s.line <= b)) continue;
      hits.push(`§4.27 a second band table — index.html:${s.line}: ${JSON.stringify(s.text.slice(0, 40))}`);
    }
    const weekFormulas = [...html.matchAll(/Math\.ceil\([^)]*\/\s*7\s*\)/g)];
    const weekHome = html.indexOf('function csWeek(');
    const weekEnd = weekHome < 0 ? -1 : html.indexOf('\n}', weekHome);
    for (const m of weekFormulas) {
      if (weekHome >= 0 && m.index >= weekHome && m.index < weekEnd) continue;
      hits.push(`§4.27 a second week formula — index.html offset ${m.index}: ${m[0]}`);
    }
    const bandFns = (html.match(/function bandName\s*\(/g) || []).length;
    if (bandFns !== 1) hits.push(`§4.27 index.html declares bandName() ${bandFns} times`);
  }
  {
    const csb = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Board', 'CSBands.swift');
    const n = existsSync(csb) ? (readFileSync(csb, 'utf8').match(/static func bandName\(/g) || []).length : 0;
    if (n !== 1) hits.push(`§4.27 CSBands declares bandName ${n} times`);
    const dates = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'League', 'LeagueDates.swift');
    for (const f of swift) {
      if (f === dates) continue;
      const src = readFileSync(f, 'utf8');
      if (/\(\s*days\s*\/\s*7\s*\)\.rounded\(\.up\)|ceil\(Double\([^)]*\)\s*\/\s*7/.test(src)) {
        hits.push(`§4.27 a second week formula — ${f.slice(root.length).replace(/^\//, '')}`);
      }
    }
  }

  /* the self-test: a check that cannot fail is not a check. Two offenders,
     one per client, synthesised rather than written to disk. */
  {
    const probes = [
      ['Lock the bylaws & form the squads', 5],
      ['3 SEATS OPEN', 16],
      ['Draft night', 14],
      ['I want to beat one guy', 34],
    ];
    for (const [text, n] of probes) {
      const law = LAWS.find(l => l[0] === n);
      if (!law || !law[2].some(re => re.test(text))) {
        hits.push(`self-test failed: §4.${n} no longer catches ${JSON.stringify(text)}`);
      }
    }
    if (isExempt('Lock the bylaws & form the squads')) hits.push('self-test failed: the exemption list swallows a real offender');
  }

  hits.length === 0
    ? pass('one vocabulary, one lint per law', `${LAWS.length + 1} laws · ${swift.length} Swift file(s) + index.html + ${liveDefs.size} live SQL definitions`)
    : fail('one vocabulary, one lint per law', `${hits.length} hit(s) — ` + hits.slice(0, process.env.CS_LINT_ALL ? 99 : 6).join('\n           '));
}

/* 28 · one band table, three renderers (R13, D249) -------------------------
   `band_name(p_pvi)` is the server's producer, `CSBands.bandName` is the
   phone's and `bandName()` is the web's. Three renderings of one rule is
   fine; three TABLES is what D249 forbids, and the −1.0 edge has already
   drifted once (Q-20) — the phone said "Played to it" over a round the engine
   scored 6. So the fixture is DERIVED FROM THE SQL here, on every push, and
   asserted against both clients and against the checked-in file the Swift
   suite reads. */
{
  const sqlPath = join(migDir, '20260930090000_one_band_name.sql');
  const fixPath = join(root, 'tests', 'fixtures', 'bands.json');
  const problems = [];

  const bandsFromSql = () => {
    if (!existsSync(sqlPath)) return null;
    const src = readFileSync(sqlPath, 'utf8');
    const body = (src.match(/create or replace function public\.band_name[\s\S]*?\$\$;/) || [])[0];
    if (!body) return null;
    const rules = [...body.matchAll(/when p_pvi (>=|>|<=|<)\s*(-?[\d.]+)\s*then '([^']+)'/g)]
      .map(m => ({ op: m[1], n: Number(m[2]), band: m[3] }));
    return rules.length ? rules : null;
  };
  const nameFor = (rules, pvi) => {
    for (const r of rules) {
      if (r.op === '>=' && pvi >= r.n) return r.band;
      if (r.op === '>' && pvi > r.n) return r.band;
      if (r.op === '<=' && pvi <= r.n) return r.band;
      if (r.op === '<' && pvi < r.n) return r.band;
    }
    return (readFileSync(sqlPath, 'utf8').match(/else '([^']+)'\s*\n?\s*end;/) || [])[1] || null;
  };

  const rules = bandsFromSql();
  if (!rules) problems.push('band_name is not in 20260930090000_one_band_name.sql — R13 lost its producer');

  let fixture = null;
  try { fixture = JSON.parse(readFileSync(fixPath, 'utf8')); } catch { problems.push('tests/fixtures/bands.json is missing or unreadable'); }

  /* the phone's table, read out of the source rather than restated here */
  const csbPath = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Board', 'CSBands.swift');
  const swiftRules = existsSync(csbPath)
    ? [...((readFileSync(csbPath, 'utf8').match(/static func bandName\(_ vs: Double\) -> String \{[\s\S]*?\n  \}/) || [''])[0])
        .matchAll(/if vs (>=|>|<=|<) (-?[\d.]+) \{ return "([^"]+)" \}/g)].map(m => ({ op: m[1], n: Number(m[2]), band: m[3] }))
    : [];
  /* the web's */
  const webBlock = (html.match(/function bandName\(vs\)\{[\s\S]*?\n\}/) || [''])[0];
  const webRules = [...webBlock.matchAll(/if\(vs\s*(>=|>|<=|<)\s*(-?[\d.]+)\)\s*return '([^']+)'/g)]
    .map(m => ({ op: m[1], n: Number(m[2]), band: m[3] }));

  if (rules && fixture) {
    for (const c of fixture.cases || []) {
      const sql = nameFor(rules, c.pvi);
      if (sql !== c.band) problems.push(`pvi ${c.pvi}: the SQL says ${JSON.stringify(sql)}, the fixture says ${JSON.stringify(c.band)}`);
      const phone = swiftRules.length ? nameFor(swiftRules, c.pvi) : null;
      if (swiftRules.length && phone !== c.band) problems.push(`pvi ${c.pvi}: CSBands says ${JSON.stringify(phone)}, the fixture says ${JSON.stringify(c.band)}`);
      const web = webRules.length ? nameFor(webRules, c.pvi) : null;
      if (webRules.length && web !== c.band) problems.push(`pvi ${c.pvi}: the web says ${JSON.stringify(web)}, the fixture says ${JSON.stringify(c.band)}`);
    }
    if (!swiftRules.length) problems.push('CSBands.bandName could not be read — did the phone’s producer move?');
    if (!webRules.length) problems.push('index.html bandName() could not be read — did the web’s producer move?');
    if ((fixture.cases || []).length < 10) problems.push('the fixture has fewer than ten cases — it stopped covering the edges');
  }

  /* the self-test: shift one boundary and the comparison must notice */
  if (rules) {
    const bent = rules.map(r => (r.n === -1 ? { ...r, op: '>=' } : r));
    if (nameFor(bent, -1) === nameFor(rules, -1)) {
      problems.push('self-test failed: the parser cannot see the −1.0 edge move');
    }
  }

  problems.length === 0
    ? pass('one band table, three renderers', `${(fixture?.cases || []).length} case(s) · SQL, CSBands and bandName() agree`)
    : fail('one band table, three renderers', problems.slice(0, 4).join(' · '));
}


/* 34 · no RPC overload PostgREST cannot resolve (C-01, C-02, D249) ----------
   `create or replace function` with a NEW argument list OVERLOADS rather than
   replaces. PostgREST resolves an RPC by the JSON body's KEY NAMES: a
   candidate matches when the sent keys are a subset of its parameters and
   every non-defaulted parameter is present. So when two functions share a
   name and one's REQUIRED set is a subset of the other's parameters, a body
   that satisfies the smaller one satisfies both, and Postgres refuses —
   `PGRST203`, "could not choose the best candidate function". That is a total
   outage for the call, not a skew.

   This repo has paid for it three times. `score_round` (spec/decision-log.md
   :5181) was caught in review and the old signature dropped. `lock_league`
   (20260924103000) and `declare_round` (20260924093000) shipped the same bug
   in the overhaul and were caught by the correctness review — after which this
   check exists so the fourth one fails the push instead.

   It reads the SHIPPED surface — the contract snapshot — plus every signature
   the unpushed migrations create or drop, so it sees what prod will look like
   AFTER the owner's next `supabase db push`. */
{
  const problems = [];
  /* what prod has today, from the snapshot */
  const sigs = new Map();          // name → [{args:[{name,defaulted}], from}]
  const parseArgs = a => (a || '').trim() === '' ? [] : splitTop(a).map(one => {
    const t = one.trim();
    const defaulted = /\bDEFAULT\b/i.test(t);
    const m = t.match(/^(?:VARIADIC\s+|OUT\s+|INOUT\s+)?([A-Za-z_][A-Za-z0-9_]*)\s+/);
    return { name: m ? m[1] : null, defaulted };
  });
  /* split on commas that are not inside brackets or quotes */
  function splitTop(a) {
    const out = []; let depth = 0, cur = '';
    for (const ch of a) {
      if (ch === '(' || ch === '[') depth++;
      else if (ch === ')' || ch === ']') depth--;
      if (ch === ',' && depth === 0) { out.push(cur); cur = ''; continue; }
      cur += ch;
    }
    if (cur.trim()) out.push(cur);
    return out;
  }
  const key = (name, args) => `${name}(${args.map(x => x.name || '?').join(',')})`;
  const add = (name, args, from) => {
    const list = sigs.get(name) || [];
    if (!list.some(x => key(name, x.args) === key(name, args))) list.push({ args, from });
    sigs.set(name, list);
  };
  const drop = (name, arity) => {
    const list = sigs.get(name); if (!list) return;
    sigs.set(name, list.filter(x => x.args.length !== arity));
  };

  for (const line of readFileSync(join(root, 'packages', 'db', 'contract.psv'), 'utf8').split('\n')) {
    if (!line || line.startsWith('#')) continue;
    const [name, args] = line.split('|');
    if (!name) continue;
    add(name.trim(), parseArgs(args), 'contract.psv');
  }

  /* every migration newer than the snapshot, in order */
  const migs = readdirSync(migDir).filter(f => f.endsWith('.sql')).sort();
  for (const f of migs) {
    const src = readFileSync(join(migDir, f), 'utf8');
    /* drops first inside a file are written before the create by convention,
       but order does not matter here: a create of the same key replaces it */
    for (const m of src.matchAll(/drop\s+function\s+(?:if\s+exists\s+)?public\.([A-Za-z_][A-Za-z0-9_]*)\s*\(([^;]*?)\)\s*;/gi)) {
      const inner = m[2].trim();
      drop(m[1], inner === '' ? 0 : splitTop(inner).length);
    }
    for (const m of src.matchAll(/create\s+or\s+replace\s+function\s+public\.([A-Za-z_][A-Za-z0-9_]*)\s*\(([\s\S]*?)\)\s*\n?\s*returns/gi)) {
      add(m[1], parseArgs(m[2]), f);
    }
  }

  for (const [name, list] of sigs) {
    if (list.length < 2) continue;
    for (const a of list) for (const b of list) {
      if (a === b) continue;
      const aRequired = a.args.filter(x => !x.defaulted).map(x => x.name);
      const bNames = new Set(b.args.map(x => x.name));
      /* a body carrying exactly a's parameters satisfies b as well */
      const aAll = a.args.map(x => x.name);
      if (aAll.every(n => n && bNames.has(n)) && aRequired.every(n => n && bNames.has(n))
          && b.args.filter(x => !x.defaulted).every(n => aAll.includes(n.name))) {
        problems.push(`${key(name, a.args)} [${a.from}] is ambiguous against ${key(name, b.args)} [${b.from}] — PostgREST cannot choose (PGRST203)`);
      }
    }
  }

  /* the self-test: the comparator must SEE the two shapes that shipped. Both
     are stated as the migrations wrote them, so a rewrite of the comparator
     that stops noticing them fails here rather than in production. */
  const ambiguous = (a, b) => {
    const aAll = a.map(x => x.name), bNames = new Set(b.map(x => x.name));
    return aAll.every(n => bNames.has(n)) && b.filter(x => !x.defaulted).every(x => aAll.includes(x.name));
  };
  const lock19 = 'p_league,p_name,p_preset'.split(',').map(n => ({ name: n, defaulted: n !== 'p_league' }));
  const lock20 = [...lock19, { name: 'p_pay_note', defaulted: true }];
  if (!ambiguous(lock19, lock20)) problems.push('self-test failed: the comparator no longer sees lock_league(19) ⊂ lock_league(20)');
  const dr6 = 'p_play_on,p_course,p_note,p_tagged,p_tee,p_course_id'.split(',').map((n, i) => ({ name: n, defaulted: i > 2 }));
  const dr8 = [...dr6, { name: 'p_name', defaulted: true }, { name: 'p_game', defaulted: true }];
  if (!ambiguous(dr6, dr8)) problems.push('self-test failed: the comparator no longer sees declare_round(6) ⊂ declare_round(8)');
  /* …and it must NOT cry wolf on a genuinely distinct pair */
  if (ambiguous([{ name: 'p_a', defaulted: false }], [{ name: 'p_b', defaulted: false }])) {
    problems.push('self-test failed: the comparator flags two functions with no shared parameter');
  }

  problems.length === 0
    ? pass('no unresolvable RPC overload', `${sigs.size} function name(s) after the pending push · score_round, lock_league and declare_round are the three this would have caught`)
    : fail('no unresolvable RPC overload', [...new Set(problems)].slice(0, 4).join(' · '));
}

/* 35 · one epilogue milestone table, two clients (R-08) --------------------
   `PostEpilogue.achievements` and index.html's `EPI_ACH` are one table on two
   clients. The sweep edited one and mis-pasted the other: the web's
   `streak_12` carried `streak_4`'s line, so a twelve-week streak was told it
   had played every week for a month. Byte-for-byte, key by key. */
{
  const problems = [];
  const swiftPath = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Post', 'PostEpilogue.swift');
  const swiftSrc = existsSync(swiftPath) ? readFileSync(swiftPath, 'utf8') : '';
  const swiftBlock = (swiftSrc.match(/achievements: \[String: \(icon: String, txt: String, sub: String\)\] = \[([\s\S]*?)\n  \]/) || [])[1] || '';
  const swiftRows = new Map([...swiftBlock.matchAll(/"([a-z0-9_]+)":\s*\("([^"]*)",\s*"([^"]*)",\s*"([^"]*)"\)/g)]
    .map(m => [m[1], { icon: m[2], txt: m[3], sub: m[4] }]));
  const webBlock = (html.match(/const EPI_ACH = \{([\s\S]*?)\n\};/) || [])[1] || '';
  const webRows = new Map([...webBlock.matchAll(/([a-z0-9_]+):\s*\{\s*icon:'([^']*)',\s*txt:'([^']*)',\s*sub:'([^']*)'\s*\}/g)]
    .map(m => [m[1], { icon: m[2], txt: m[3], sub: m[4] }]));

  if (swiftRows.size === 0) problems.push('PostEpilogue.achievements could not be read — did the phone’s table move?');
  if (webRows.size === 0) problems.push('index.html EPI_ACH could not be read — did the web’s table move?');
  if (swiftRows.size && webRows.size) {
    for (const k of new Set([...swiftRows.keys(), ...webRows.keys()])) {
      const a = swiftRows.get(k), b = webRows.get(k);
      if (!a) { problems.push(`${k} is on the web and not on the phone`); continue; }
      if (!b) { problems.push(`${k} is on the phone and not on the web`); continue; }
      for (const f of ['icon', 'txt', 'sub']) {
        if (a[f] !== b[f]) problems.push(`${k}.${f}: phone ${JSON.stringify(a[f])} vs web ${JSON.stringify(b[f])}`);
      }
    }
    /* and no two STREAKS share a sub — the mis-paste's own signature was a
       twelve-week streak wearing the four-week line. (sub_90 and sub_100
       deliberately share "In your trophy case"; a streak may not.) */
    const subs = new Map();
    for (const [k, v] of swiftRows) {
      if (!k.startsWith('streak_')) continue;
      if (subs.has(v.sub)) problems.push(`${k} and ${subs.get(v.sub)} say the same thing: ${JSON.stringify(v.sub)}`);
      subs.set(v.sub, k);
    }
  }
  problems.length === 0
    ? pass('one epilogue table, two clients', `${swiftRows.size} milestone(s) agree, and no two say the same thing`)
    : fail('one epilogue table, two clients', problems.slice(0, 4).join(' · '));
}


/* 36 · the 11px floor, and a debt that may only shrink (LV-17, L-29) --------
   L-29: "nothing below 11pt". `CSFont.label`'s own comment names index.html as
   the file that went to 8.5, and the redesign added six more sub-11px rules to
   its brand-new desktop chrome — a standings movement caption at 9.5px
   carrying a real fact among them. Those six are at the floor now.

   The eighty-six that predate the overhaul are a DEBT, not a licence: this
   check pins the count, so a new rule below the floor fails the push and every
   one paid off ratchets the number down. It is the only shape that makes a
   pre-existing violation safe to leave in place. */
{
  const BELOW_11 = 83;                    // 2026-09-05, after LV-17 paid six back and D258 paid the climb's three
  const found = (html.match(/font-size:\s*(?:[0-9]|10)(?:\.[0-9]+)?px/g) || []);
  if (found.length > BELOW_11) {
    fail('the 11px floor holds', `${found.length} rule(s) below 11px — the debt is ${BELOW_11} and may only shrink (L-29). New: ${found.length - BELOW_11}`);
  } else if (found.length < BELOW_11) {
    pass('the 11px floor holds', `${found.length} rule(s) below 11px — ${BELOW_11 - found.length} paid off; lower BELOW_11 to ${found.length} to keep the ratchet`);
  } else {
    pass('the 11px floor holds', `${found.length} grandfathered rule(s), and no new one`);
  }
}

/* 37 · one worth-of-a-round producer, three renderers (R-K, D256) -----------
   R-K put "what is this round worth" on two new surfaces — the plan sheet and
   Home's dispatch — beside the climb, which has been doing the multiplication
   since QB-12. The ruling's own words: *"One producer, not two… the plan sheet
   and the dispatch item read the same producer or the fact drifts."*

   The shape is check 28's, and it is this repo's settled answer to a rule that
   must exist in SQL and in two clients: the SERVER owns the sum
   (`public.round_worth`), each client carries ONE verbatim port, and a second
   copy of the arithmetic on either client fails the push. The ports are pinned
   against the server's own table by `RoundWorthTests` and `tests/db-checks.sql`;
   this check pins the SINGULARITY. */
{
  const hits = [];
  const kit = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit');
  const home = join(kit, 'League', 'RoundWorth.swift');

  if (!existsSync(home)) {
    hits.push('CupSeasonKit/League/RoundWorth.swift is gone — where did the sum go?');
  } else {
    const src = readFileSync(home, 'utf8');
    const n = (src.match(/static func gain\(/g) || []).length;
    if (n !== 1) hits.push(`RoundWorth declares gain ${n} times`);
  }

  /* the multiplication itself, anywhere but its home. `topBand - worst` in any
     spelling is the bump; a bare `cupPoints(3)` outside the producer is the
     add. Both are the sum, and both belong in exactly one file. */
  const swift37 = (await import('../tools/extract-strings.mjs')).swiftSources(join(root, 'apps', 'ios'));
  const BUMP = /(top|topBand|cupPoints\(3\)|CSBands\.cupPoints\(3\))\s*-\s*(worst|min)/;
  for (const f of swift37) {
    if (f === home) continue;
    if (/\/Tests\//.test(f)) continue;
    const src = readFileSync(f, 'utf8');
    if (BUMP.test(src)) hits.push(`a second worth sum — ${f.slice(root.length).replace(/^\//, '')}`);
  }

  /* the web's one port */
  const declared = (html.match(/function csRoundWorth\s*\(/g) || []).length;
  if (declared !== 1) hits.push(`index.html declares csRoundWorth() ${declared} times`);
  {
    const at = html.indexOf('function csRoundWorth(');
    const end = at < 0 ? -1 : html.indexOf('\n}', at);
    for (const m of [...html.matchAll(/pointsFor\(3\)\[0\]\s*-\s*/g)]) {
      if (at >= 0 && m.index > at && m.index < end) continue;
      hits.push(`a second worth sum — index.html offset ${m.index}`);
    }
  }

  /* and the authority it is a port OF */
  const worthSql = readdirSync(migDir).filter(x => x.endsWith('.sql'))
    .some(f => /create\s+or\s+replace\s+function\s+public\.round_worth\s*\(/i.test(readFileSync(join(migDir, f), 'utf8')));
  if (!worthSql) hits.push('no migration declares public.round_worth() — the clients are porting nothing');

  /* the self-test: a check that cannot fail is not a check */
  if (!BUMP.test('let g = topBand - worst')) hits.push('self-test failed: the bump grep no longer matches the bump');

  hits.length === 0
    ? pass('one worth-of-a-round producer, three renderers', 'RoundWorth.gain · csRoundWorth · public.round_worth')
    : fail('one worth-of-a-round producer, three renderers', hits.join('\n           '));
}


/* 38 · the type floors on the phone, and a sheet that survives AX3 ----------
   L-29: "nothing renders below 11pt at the default size; every layout tolerates
   AX sizes." Check 36 holds that line on the web. This is its phone half, and
   it holds three things the accessibility wave found broken by looking:

   (a) **A `CSFont` role may not be declared below 11pt**, and a role may not be
       scaled below 11 either — `.minimumScaleFactor(0.7)` on an 11pt label is
       7.7pt, which is the same sin at one remove. Four labels and five small
       mono lines were doing exactly that.

   (b) **Every PostScript name `CSFont` asks for must exist in a bundled face.**
       `monoRegular` was `"IBMPlexMono"`, which is neither the Regular face's
       PostScript name (`IBMPlexMono-Regular`) nor its family (`IBM Plex Mono`),
       so `Font.custom` resolved nothing and three of the mono roles — label,
       mono, monoSmall — had been silently rendering in the system sans. Nothing
       crashes, nothing logs, and the record voice is simply not there.

   (c) **A sheet may not be pinned to a fixed height.** 340 points hold three
       sentences at the reading sizes and one and a half at AX3, where the
       length sheet drew its rows on top of each other. Fixed heights go through
       `.csFittedSheet`, which hands the whole page over at the accessibility
       sizes. */
{
  const hits = [];
  const iosRoot = join(root, 'apps', 'ios');
  const swiftAll = (await import('../tools/extract-strings.mjs')).swiftSources(iosRoot);
  const rel = f => f.slice(root.length).replace(/^\//, '');
  const FLOOR = 11;

  /* (a) the roles, and the scale factors applied to them */
  const typo = join(iosRoot, 'Packages', 'CSDesign', 'Sources', 'CSDesign', 'Typography.swift');
  const roles = new Map();                                   // CSFont.<role> -> declared points
  if (!existsSync(typo)) {
    hits.push('CSDesign/Typography.swift is gone — where did the three voices go?');
  } else {
    const src = readFileSync(typo, 'utf8');
    for (const m of src.matchAll(/static let (\w+) = Font\.custom\((\w+), size: ([\d.]+)/g)) {
      roles.set(m[1], Number(m[3]));
      if (Number(m[3]) < FLOOR) hits.push(`CSFont.${m[1]} is declared at ${m[3]}pt — the floor is ${FLOOR} (L-29)`);
    }
    /* (b) the faces those roles name, against the bundled files' own name table */
    const fontDir = join(iosRoot, 'CupSeason', 'Resources', 'Fonts');
    const bundled = new Set();
    if (existsSync(fontDir)) {
      for (const f of readdirSync(fontDir).filter(x => /\.(ttf|otf)$/i.test(x))) {
        const buf = readFileSync(join(fontDir, f));
        const numTables = buf.readUInt16BE(4);
        let nameOff = 0;
        for (let i = 0; i < numTables; i++) {
          const o = 12 + 16 * i;
          if (buf.toString('latin1', o, o + 4) === 'name') nameOff = buf.readUInt32BE(o + 8);
        }
        if (!nameOff) continue;
        const count = buf.readUInt16BE(nameOff + 2), strOff = nameOff + buf.readUInt16BE(nameOff + 4);
        for (let i = 0; i < count; i++) {
          const r = nameOff + 6 + 12 * i;
          const pid = buf.readUInt16BE(r), nid = buf.readUInt16BE(r + 6);
          const len = buf.readUInt16BE(r + 8), off = buf.readUInt16BE(r + 10);
          if (nid !== 1 && nid !== 6) continue;                 // family, PostScript
          const raw = buf.subarray(strOff + off, strOff + off + len);
          bundled.add((pid === 3 ? raw.toString('utf16le').split('').map((_, k, a) =>
            k % 1 === 0 ? a[k] : '').join('') : raw.toString('latin1')));
          bundled.add(raw.toString(pid === 3 ? 'utf16le' : 'latin1'));
          if (pid === 3) {                                      // big-endian UTF-16
            let out = '';
            for (let k = 0; k + 1 < raw.length; k += 2) out += String.fromCharCode(raw.readUInt16BE(k));
            bundled.add(out);
          }
        }
      }
    }
    /* Charter is a system face on iOS and is not bundled; the mono faces are
       ours, and since D268 so is the BOARD face — IBM Plex Sans Condensed,
       which carries 46% of the type in the new system. The brief that ordered
       it predicted `IBMPlexSansCondensed-SemiBold`; the file's own name table
       says `IBMPlexSansCond-SmBld`. That is one letter-group of difference
       between the brand's voice and SF Pro, with no crash and no log — D258
       exactly — so `board*` is held here beside `mono*`. */
    for (const m of src.matchAll(/static let ((?:mono|board)\w+) = "([^"]+)"/g)) {
      if (!bundled.has(m[2])) {
        hits.push(`CSFont.${m[1]} names "${m[2]}", which no bundled face carries — Font.custom falls back to the system sans, silently`);
      }
    }
    if (bundled.size === 0) hits.push('no bundled font names could be read — the face check is not running');
    /* A face is only bundled when it is in the folder AND in both UIAppFonts
       arrays. project.yml writes the plist Xcode compiles; CupSeason/Info.plist
       is the one a human reads. One without the other is D258's other half. */
    const decl = [
      ['apps/ios/project.yml', join(iosRoot, 'project.yml')],
      ['apps/ios/CupSeason/Info.plist', join(iosRoot, 'CupSeason', 'Info.plist')],
    ];
    if (existsSync(fontDir)) {
      const files = readdirSync(fontDir).filter(x => /\.(ttf|otf)$/i.test(x));
      for (const [label, path] of decl) {
        if (!existsSync(path)) { hits.push(`${label} is missing — nothing declares UIAppFonts`); continue; }
        const body = readFileSync(path, 'utf8');
        for (const f of files) if (!body.includes(f)) hits.push(`${f} sits in Resources/Fonts but ${label} never names it — it does not ship`);
      }
    }
  }

  /* a role scaled below the floor is below the floor */
  const SCALE = /\.font\(CSFont\.(\w+)\)[^\n]*?\.minimumScaleFactor\(([\d.]+)\)/g;
  for (const f of swiftAll) {
    if (/\/Tests\//.test(f)) continue;
    const src = readFileSync(f, 'utf8');
    for (const m of src.matchAll(SCALE)) {
      const base = roles.get(m[1]);
      if (base === undefined) continue;                        // .body/.footnote etc: the system's own floor
      const floorAt = base * Number(m[2]);
      if (floorAt < FLOOR - 0.005) {
        hits.push(`${rel(f)}: CSFont.${m[1]} (${base}pt) × ${m[2]} = ${floorAt.toFixed(2)}pt — below the ${FLOOR}pt floor (L-29)`);
      }
    }
  }

  /* (c) no sheet pinned to a height outside the AX-aware helper */
  const HELPER = join(iosRoot, 'Packages', 'CSDesign', 'Sources', 'CSDesign', 'Surfaces.swift');
  for (const f of swiftAll) {
    if (f === HELPER || /\/Tests\//.test(f)) continue;
    const src = readFileSync(f, 'utf8');
    for (const m of src.matchAll(/presentationDetents\(\[[^\]]*\.height\(/g)) {
      hits.push(`${rel(f)}: a sheet pinned to .height(...) — use .csFittedSheet(_:), which hands the page over at the accessibility sizes`);
    }
  }
  if (!/func csFittedSheet\(/.test(existsSync(HELPER) ? readFileSync(HELPER, 'utf8') : '')) {
    hits.push('CSDesign has no csFittedSheet(_:) — the AX-aware detent is gone');
  }

  /* the self-test: a check that cannot fail is not a check */
  if (!SCALE.test('.font(CSFont.label).minimumScaleFactor(0.7)')) {
    hits.push('self-test failed: the scale-factor grep no longer matches a scaled role');
  }
  SCALE.lastIndex = 0;
  if (!/presentationDetents\(\[[^\]]*\.height\(/.test('.presentationDetents([.height(320)])')) {
    hits.push('self-test failed: the pinned-height grep no longer matches a pinned height');
  }

  hits.length === 0
    ? pass('the phone holds the 11pt floor', `${roles.size} type role(s), every face resolves, no sheet pinned to a height`)
    : fail('the phone holds the 11pt floor', hits.slice(0, 6).join('\n           '));
}

/* 39 · one easing, and reduced motion rests on the frame (L-30) -------------
   *"One easing everywhere — the roll `cubic-bezier(.16,.84,.36,1)`; nothing
   bounces; reduced motion rests on the frame."* Both halves had holes.

   The roll was one of six curves on the phone — `easeOut` on the root view,
   `easeInOut` on two breathing dots, `easeIn` on the split-flap — and roughly
   thirty `withAnimation` call sites animated straight through a golfer's
   reduce-motion setting because the guard was a habit rather than a mechanism.
   `CSMotion.run` / `.csAnimation` ARE the mechanism now, so this check is the
   lint per law (D249): a raw curve, or a raw `withAnimation`, fails the push.

   On the web the backstop is a single reduced-motion rule that rests every
   animation and transition on its end frame, plus the ban on overshoot — a
   cubic-bezier with a control point outside 0…1 is a bounce, and golf does not
   bounce. */
{
  const hits = [];
  const iosRoot = join(root, 'apps', 'ios');
  const swiftAll = (await import('../tools/extract-strings.mjs')).swiftSources(iosRoot);
  const rel = f => f.slice(root.length).replace(/^\//, '');
  const HOME = join(iosRoot, 'Packages', 'CSDesign', 'Sources', 'CSDesign', 'Surfaces.swift');

  /* the roll, and nothing else */
  const OTHER = /\.(easeIn|easeOut|easeInOut|linear|spring|bouncy|snappy|smooth)\b\s*[(,)]/;
  const CURVE = /timingCurve\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)/g;
  for (const f of swiftAll) {
    if (/\/Tests\//.test(f)) continue;
    const src = readFileSync(f, 'utf8');
    src.split('\n').forEach((line, i) => {
      if (!/[Aa]nimation|withAnimation|\.animation\(/.test(line)) return;
      if (OTHER.test(line)) hits.push(`${rel(f)}:${i + 1} — a second easing: ${line.trim().slice(0, 72)}`);
    });
    for (const m of src.matchAll(CURVE)) {
      const got = [m[1], m[2], m[3], m[4]].map(Number);
      /* TWO curves, and the second one is a ruling rather than a slip. The
         ROLL is how a thing ARRIVES — fast start, long soft settle, 320ms. The
         SNAP is how a control ANSWERS A FINGER, and a press that rolls for
         320ms reads as lag. `CSMotion.snap` (D269 / BUILD_BRIEF §3.2) is the
         only other legal curve in the product and it lives in `Surfaces.swift`
         beside the roll; every `ButtonStyle` animates on it and nothing else
         does. A third curve still fails here. */
      if (got.join(',') !== '0.16,0.84,0.36,1' && got.join(',') !== '0.2,0,0,1') {
        hits.push(`${rel(f)} — timingCurve(${got.join(', ')}) is neither the roll nor the snap`);
      }
    }
    /* reduced motion rests on the frame: the guard is CSMotion, not a habit */
    if (f !== HOME) {
      src.split('\n').forEach((line, i) => {
        if (/\bwithAnimation\s*\(/.test(line)) {
          hits.push(`${rel(f)}:${i + 1} — a raw withAnimation: use CSMotion.run, which rests on the frame under reduce motion`);
        }
        if (/(?<!cs)\.animation\(/.test(line) && !/TimelineView/.test(line)
            && !/reduce/i.test(line) && !/csAnimation/.test(line)) {
          hits.push(`${rel(f)}:${i + 1} — a raw .animation(): use .csAnimation(_:value:) or guard it on reduceMotion`);
        }
      });
    }
  }
  for (const need of ['static func run', 'func csAnimation', 'static func breath']) {
    if (!existsSync(HOME) || !readFileSync(HOME, 'utf8').includes(need)) {
      hits.push(`CSDesign is missing CSMotion's ${need} — L-30 has no mechanism`);
    }
  }

  /* the web: one backstop, and nothing bounces */
  if (!/@media\s*\(prefers-reduced-motion:\s*reduce\)\s*\{[^}]*animation-duration:\s*\.?0*1?ms\s*!important/s.test(html)
      && !/prefers-reduced-motion[^{]*\{\s*\*[^}]*animation-duration/s.test(html)) {
    hits.push('index.html has no global reduced-motion backstop — every new @keyframes needs its own opt-out and one will be missed');
  }
  for (const m of html.matchAll(/cubic-bezier\(\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*,\s*([-\d.]+)\s*\)/g)) {
    const n = [m[1], m[2], m[3], m[4]].map(Number);
    if (n[1] > 1 || n[3] > 1 || n[1] < 0 || n[3] < 0) {
      hits.push(`index.html — cubic-bezier(${n.join(',')}) overshoots: golf does not bounce (L-30)`);
    }
  }

  /* the self-test */
  if (!OTHER.test('.animation(.easeOut(duration: 0.2), value: x)')) {
    hits.push('self-test failed: the second-easing grep no longer matches easeOut');
  }
  if (!/\bwithAnimation\s*\(/.test('withAnimation(CSMotion.roll) { x = 1 }')) {
    hits.push('self-test failed: the withAnimation grep no longer matches');
  }

  hits.length === 0
    ? pass('one easing, and reduced motion rests on the frame', 'CSMotion on the phone · a backstop and no overshoot on the web')
    : fail('one easing, and reduced motion rests on the frame', hits.slice(0, 6).join('\n           '));
}


/* 40 · the two clients' nav labels agree, slot by slot (D222 / R-A, R-D) -----
   THE FOURTH CHECK THE EVIDENCE SWEEP ASKED FOR AND NOBODY BUILT. Check 24
   walks the web's router and check 25 guards the ruled section heads, but
   nothing compared the two clients' nav LABELS against each other — which is
   why the web drifted twice inside one overhaul (the section head, and the
   centre destination reading "Record" where the phone read "Play").

   `NavSlot.label` is the phone's producer and the only place the five words
   live. The web declares them twice — once in the desk's sidebar and once in
   the bar below 960px — because they are two shapes of one router (R-C), and
   two hand-typed copies of five words is exactly the shape that drifts.

   THE ROUTER IDS ARE NOT THE LABELS, and the mapping is declared here with its
   reason: `data-v` values predate D222 and index.html's own comment says so —
   *"`data-v="record"` is the router id and is not a surface"*. Renaming them is
   a router change with eleven pane ids behind it; agreeing on the WORD is what
   the golfer sees. */
{
  const hits = [];
  const SLOT_TO_V = { home: 'home', compete: 'compete', play: 'record', golfers: 'golfers', you: 'stats' };

  const navPath = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Nav', 'NavSlot.swift');
  const navSrc = existsSync(navPath) ? readFileSync(navPath, 'utf8') : '';
  const labelBlock = (navSrc.match(/public var label: String \{\s*switch self \{([\s\S]*?)\n    \}/) || [])[1] || '';
  const phone = new Map([...labelBlock.matchAll(/case \.([a-z]+):\s*"([^"]+)"/g)].map(m => [m[1], m[2]]));
  if (phone.size === 0) hits.push('NavSlot.label could not be read — did the phone’s producer move?');

  /* the label a button wears: everything that is not a tag, collapsed */
  const wordOf = (buttonHtml) => buttonHtml
    .replace(/<svg[\s\S]*?<\/svg>/g, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&[a-z]+;|&#\d+;/gi, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  /* every <button …data-v="x"…>…</button> inside one region */
  const buttons = (region, cls) => {
    const out = new Map();
    for (const m of region.matchAll(/<button\b[^>]*>[\s\S]*?<\/button>/g)) {
      const tag = (m[0].match(/<button\b[^>]*>/) || [''])[0];
      if (!new RegExp(`class="${cls}[^"]*"`).test(tag)) continue;
      if (/class="[^"]*\bsub\b[^"]*"/.test(tag)) continue;     // the More disclosure’s children
      const v = (tag.match(/data-v="([^"]+)"/) || [])[1];
      if (!v) continue;
      out.set(v, wordOf(m[0]));
    }
    return out;
  };

  const tabStart = html.indexOf('<nav class="tabbar"');
  const tabRegion = tabStart < 0 ? '' : html.slice(tabStart, html.indexOf('</nav>', tabStart));
  const asideStart = html.indexOf('class="navitem active"');
  const asideRegion = asideStart < 0 ? '' : html.slice(html.lastIndexOf('<aside', asideStart), html.indexOf('</aside>', asideStart));

  const bar = buttons(tabRegion, 'tab');
  const side = buttons(asideRegion, 'navitem');
  if (bar.size === 0) hits.push('index.html: the tab bar’s five buttons could not be read');
  if (side.size === 0) hits.push('index.html: the sidebar’s five buttons could not be read');

  if (phone.size && bar.size && side.size) {
    for (const [slot, want] of phone) {
      const v = SLOT_TO_V[slot];
      if (!v) { hits.push(`NavSlot.${slot} has no web destination declared in this check`); continue; }
      for (const [where, got] of [['the tab bar', bar.get(v)], ['the sidebar', side.get(v)]]) {
        if (got === undefined) hits.push(`${where} has no data-v="${v}" — the phone’s ${slot} slot has no twin`);
        else if (got !== want) hits.push(`${where} says ${JSON.stringify(got)} where the phone says ${JSON.stringify(want)} (slot ${slot})`);
      }
    }
    /* and neither client has a SIXTH place: five slots, five buttons, both shapes */
    for (const [where, got] of [['the tab bar', bar], ['the sidebar', side]]) {
      const extra = [...got.keys()].filter(v => !Object.values(SLOT_TO_V).includes(v));
      if (extra.length) hits.push(`${where} carries a destination the phone has no slot for: ${extra.join(', ')}`);
      if (got.size !== 5) hits.push(`${where} has ${got.size} destination(s), and D222 ruled five`);
    }
  }

  /* the self-test: a check that cannot fail is not a check */
  if (wordOf('<button class="tab" data-v="record"><svg viewBox="0 0 24 24"><path d="M12 6v12"/></svg>Record</button>') !== 'Record') {
    hits.push('self-test failed: the label extractor no longer reads a button’s word');
  }

  hits.length === 0
    ? pass('the two clients agree on the five words', `${phone.size} slot(s) × the sidebar and the bar`)
    : fail('the two clients agree on the five words', hits.slice(0, 6).join('\n           '));
}

/* 41 · one Home-state fixture set, and it cannot exist in production (D259) --
   The re-audit could not reach twelve of seventeen Home states, which is the
   largest verification hole the product has. The hatch that closes it is only
   worth having if BOTH clients open the same states, so the payloads are one
   JSON file: the phone gets a generated Swift twin, the web fetches the file
   itself. This check holds the three things that make that safe —
   the twin is not stale, the phone's copy is `#if DEBUG` so no Release build
   contains it, and `tests/` is not in the dist allowlist, so the web's hatch
   404s on cupseason.app by construction rather than by a flag somebody can
   flip. */
{
  const hits = [];
  const fxPath = join(root, 'tests', 'fixtures', 'home-states.json');
  const swiftPath = join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources', 'CupSeasonKit', 'Generated', 'HomeStateFixtures.swift');
  let doc = null;
  if (!existsSync(fxPath)) hits.push('tests/fixtures/home-states.json is gone — the hatch has no states');
  else {
    try { doc = JSON.parse(readFileSync(fxPath, 'utf8')); }
    catch (e) { hits.push(`home-states.json does not parse: ${e.message}`); }
  }

  /* the phone's twin is fresh, and it is DEBUG-only */
  if (doc) {
    const { render } = await import('../tools/build-home-states.mjs');
    const want = render(doc);
    const got = existsSync(swiftPath) ? readFileSync(swiftPath, 'utf8') : '';
    if (got !== want) hits.push('HomeStateFixtures.swift is STALE — run `node tools/build-home-states.mjs`');
    if (!/^#if DEBUG$/m.test(got)) hits.push('HomeStateFixtures.swift is not wrapped in #if DEBUG — a Release build would carry the fixtures');
  }

  /* every fixture is a screen: a door the fence will not drop, and a headline */
  const PHONE_ROUTES = new Set(['composer', 'people', 'declare', 'live', 'receipt', 'plan', 'season', 'pot', 'invite']);
  if (doc) {
    const webRoutes = new Set([...((html.match(/function csItemDoor\(it\)\{[\s\S]*?\n\}/) || [''])[0])
      .matchAll(/case '([a-z]+)':/g)].map(m => m[1]));
    for (const st of doc.states || []) {
      for (const k of ['id', 'matrix', 'title', 'note', 'payload']) {
        if (!st[k]) hits.push(`fixture ${st.id || '?'} has no ${k}`);
      }
      const items = st.payload?.items || [];
      if (!items.length) hits.push(`fixture ${st.id} has no items — it renders nothing to photograph`);
      for (const it of items) {
        const kind = it.route?.kind;
        if (!kind) { hits.push(`${st.id}/${it.key}: no route — G1's fence drops it and the screenshot is a lie`); continue; }
        if (!PHONE_ROUTES.has(kind)) hits.push(`${st.id}/${it.key}: route "${kind}" is not one the phone can resolve`);
        if (webRoutes.size && !webRoutes.has(kind)) hits.push(`${st.id}/${it.key}: route "${kind}" is not one the web can resolve`);
        if (!String(it.headline || '').trim()) hits.push(`${st.id}/${it.key}: no headline`);
      }
    }
    if ((doc.states || []).length < 13) hits.push(`${(doc.states || []).length} state(s) — the wave's own floor is 13`);
  }

  /* the production seal: the web fetches a path the deploy does not publish */
  if (!/fetch\('tests\/fixtures\/home-states\.json'/.test(html)) {
    hits.push('index.html no longer reads tests/fixtures/home-states.json — the two clients are on different fixtures');
  }
  if (/tests\//.test(stamp)) hits.push('stamp-version.sh publishes tests/ — the Home-state hatch would exist in production');
  if (/home-states/.test(sw)) hits.push('sw.js precaches the fixtures — they would be served from a cache in production');

  /* the self-test */
  if (PHONE_ROUTES.has('event')) hits.push('self-test failed: the route vocabulary now claims a case HomeDispatch.Route does not have');

  hits.length === 0
    ? pass('one Home-state fixture set, and none of it ships', `${(doc?.states || []).length} state(s) · generated for the phone, fetched by the web, absent from dist`)
    : fail('one Home-state fixture set, and none of it ships', hits.slice(0, 6).join('\n           '));
}


/* 42 · the gloss and the five bands, kept out of each other (R-M, D260) ------
   R-M retired `your number` as the COMPARISON noun and, in the same breath,
   ruled the five band labels stay exactly as spec §2.2 has them. That leaves
   two sets one word apart, and the ruling asks for a lint that keeps each out
   of the other — because "Beat your number" is a SUBSTRING of the sentence it
   replaces, so a half-applied rename reads perfectly and is wrong.

   THE TWO RULES:
     A · the COMPARISON FRAME never says "number". "beat your number by 2.1",
         "1.4 over your number", "played to your number", "Avg vs your number",
         "95% of your number" — all retired. The one exemption is a string that
         IS a band label, verbatim, because "Beat your number" is still the
         chip's own name.
     B · the BAND SET is exactly the five, in all three producers, and no band
         ever says "playing HCP". Check 28 holds the three producers to each
         OTHER; this holds them to spec §2.2 so the set cannot move as a group.

   The INDEX sense is deliberately untouched. "your number builds itself from
   three posted rounds" is about the index, R-M retired the word only for the
   comparison, and a lint that swept both would be enforcing a ruling nobody
   made. The frames below are what tells the two apart. */
{
  const T = await import('../tools/extract-strings.mjs');
  const hits = [];

  /* spec §2.2's five, verbatim. If the owner ever renames one, this line moves
     with the ruling — and nothing else in the repo has to be trusted to. */
  const BANDS = ['Torched it', 'Beat your number', 'Played to it', 'A little loose', 'Posted anyway'];
  const bandForms = new Set();
  for (const b of BANDS) {
    for (const v of [b, b.toUpperCase(), b.toLowerCase(),
                     b.replace(/your/i, 'their'), b.toUpperCase().replace(/YOUR/, 'THEIR'),
                     b.toLowerCase().replace(/your/, 'their')]) bandForms.add(v);
  }

  /* A · the comparison frames. Each is a POSSESSIVE + "number" behind a word
     that can only be the arithmetic; the index sense ("builds your number",
     "your number goes live") matches none of them. */
  /* NW-4 · THE POSSESSIVE DOES NOT HAVE TO SIT ON THE NOUN. Every frame
     required `your` to be directly followed by `number`, so ONE intervening
     adjective walked straight past: `against your own number` and `your
     playing number` were invisible to this check, and there were fifteen of
     them live on both clients and in `head_to_head()` — the comparison itself,
     the exact arithmetic R-M renamed, including the sentence that explains the
     scoring model to a golfer joining a league. `(?:\w+\s+){0,2}` tolerates
     one or two words between the determiner and the noun.

     It cannot catch the OPPONENT'S-SCORE sense — `the number to beat` — which
     the ruling keeps: that phrase has no possessive at all, and the self-test
     below pins every live instance of it. */
  const POSS = '(your|their|her|his|its|my)\\s+(?:\\w+\\s+){0,2}';
  const FRAMES = [
    new RegExp(`\\b(beat|beats|beating|torched|torches|torching)\\s+${POSS}numbers?\\b`, 'i'),
    new RegExp(`\\b(over|under|vs\\.?|versus|against|on|to)\\s+${POSS}numbers?\\b`, 'i'),
    new RegExp(`\\bplayed\\s+to\\s+${POSS}numbers?\\b`, 'i'),
    new RegExp(`\\b\\d+\\s?%\\s+of\\s+${POSS}numbers?\\b`, 'i'),
    /\bplaying\s+number\b/i,
    /\b(everyone|anybody|anyone|somebody|someone|nobody)(?:'|\u2019)s\s+(?:\w+\s+){0,2}numbers?\b/i,
  ];
  const offends = t => {
    const trimmed = t.trim();
    if (bandForms.has(trimmed)) return false;           // the chip keeps its name
    return FRAMES.some(re => re.test(trimmed));
  };
  /* one sentence at a time, the way check 27 splits a web template */
  const fragments = text => (/[<\n]/.test(text)
    ? text.split(/<[^>]*>|\n/).map(x => x.trim()).filter(Boolean)
    : [text]);
  const scanText = (where, text) => {
    for (const frag of fragments(text)) {
      if (offends(frag)) { hits.push(`${where}: ${JSON.stringify(frag.slice(0, 72))}`); return; }
    }
  };

  const swift42 = T.swiftSources(join(root, 'apps', 'ios'));
  for (const f of swift42) {
    const rel = f.slice(root.length).replace(/^\//, '');
    for (const s of T.swiftProse(readFileSync(f, 'utf8'))) scanText(`${rel}:${s.line}`, s.text);
  }
  for (const s of T.webProse(html)) scanText(`index.html:${s.line}`, s.text);

  /* the database — the LIVE definition of each generator, check 27's own rule:
     an applied migration cannot be edited, so the sentence that ships is the
     last `create or replace`. */
  {
    const liveDefs = new Map();
    for (const f of readdirSync(migDir).filter(x => x.endsWith('.sql')).sort()) {
      const src = readFileSync(join(migDir, f), 'utf8');
      const re = /create\s+or\s+replace\s+function\s+(?:public\.)?"?([a-z0-9_]+)"?\s*\(([\s\S]*?)\n[^\n]*(?:\$function\$|\$\$|\$fn\$)\s*;/gi;
      let m;
      while ((m = re.exec(src))) liveDefs.set(m[1].toLowerCase(), { file: f, body: m[0] });
    }
    /* NW-1 · EVERY LIVE DEFINITION, NOT JUST THE GENERATORS. This skipped any
       function that does not `insert into posts|push_nudges|season_adjustments`
       — so a function that RETURNS prose was never scanned, and
       `head_to_head()` shipped four retired words (`playing number` twice,
       `your own number`, `a Ryder duel`) that both clients render verbatim.
       Both clients' fallbacks had been renamed, so the page read correctly
       today and would have started disagreeing with itself word for word the
       moment the owner pushed. */
    for (const [name, { file, body }] of liveDefs) {
      const lines = body.split('\n');
      for (const s of T.sqlStrings(body)) {
        if (/raise\s+(exception|notice|warning)/i.test(lines[s.line - 1] || '')) continue;
        scanText(`${file} ${name}()`, s.text);
      }
    }
  }

  /* B · the five, verbatim, in all three producers — and never wearing the
     gloss's noun. */
  {
    const csb = readFileSync(join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources',
                                  'CupSeasonKit', 'Board', 'CSBands.swift'), 'utf8');
    const phoneBand = csb.match(/static func bandName\([\s\S]*?\n  \}/);
    const webBand = html.match(/function bandName\(vs\)\{[\s\S]*?\n\}/);
    const sqlBand = [...migs.matchAll(/create or replace function public\.band_name[\s\S]*?\$\$;/g)].pop();
    const homes = [['CSBands.bandName', phoneBand?.[0]], ['index.html bandName()', webBand?.[0]],
                   ['public.band_name', sqlBand?.[0]]];
    for (const [who, src] of homes) {
      if (!src) { hits.push(`${who} not found — the band producer moved and this check went blind`); continue; }
      for (const b of BANDS) if (!src.includes(b)) hits.push(`${who} no longer says ${JSON.stringify(b)} — spec §2.2's five are a closed set (R-M)`);
      if (/playing\s+HCP/i.test(src)) hits.push(`${who} says "playing HCP" — the gloss has leaked into the band set (R-M)`);
    }
  }

  /* C · and the gloss producers DO say it, so a half-reverted rename fails. */
  {
    const csb = readFileSync(join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources',
                                  'CupSeasonKit', 'Board', 'CSBands.swift'), 'utf8');
    const pairs = [
      ['CSBands.vsPhrase', csb.match(/static func vsPhrase\([\s\S]*?\n  \}/)?.[0]],
      ['CSBands.pointsFor', csb.match(/static func pointsFor\([\s\S]*?\n  \}/)?.[0]],
      ['index.html vsPhrase()', html.match(/function vsPhrase\(vs\)\{[\s\S]*?\n\}/)?.[0]],
      ['index.html pointsFor()', html.match(/function pointsFor\(vs\)\{[\s\S]*?\n\}/)?.[0]],
    ];
    for (const [who, src] of pairs) {
      if (!src) { hits.push(`${who} not found — the gloss producer moved and this check went blind`); continue; }
      if (!/playing HCP/.test(src)) hits.push(`${who} does not say "playing HCP" — R-M's noun has been reverted`);
    }
    /* The desk's Tour Card builds its three career labels by INTERPOLATION
       inside a template literal (`vs ${whose} number`), which the prose scan
       above cannot see — so wave D renamed both clients' producers and left
       these three saying the old noun for a day. Wave E fixed them and pinned
       them here, by name, so the same blind spot cannot swallow them twice. */
    const career = html.match(/const eyebrow\s+= lens[\s\S]*?const stats =/);
    if (!career) hits.push("index.html openTourCard's career labels moved — this check went blind");
    else {
      if (!/playing HCP/.test(career[0])) hits.push('index.html openTourCard: the career labels no longer say "playing HCP" (R-M)');
      if (/\bnumbers?\b/.test(career[0])) hits.push('index.html openTourCard: a career label says "number" again (R-M)');
    }
  }

  /* the self-test: a check that cannot fail is not a check. */
  {
    const probes = [
      'beat your number by 2.4', '1.3 over your number', 'played to your number',
      'Avg vs their number', 'Scored at 95% of your number', 'Playing number',
    ];
    for (const t of probes) if (!offends(t)) hits.push(`self-test failed: §42 no longer catches ${JSON.stringify(t)}`);
    const probes2 = ['scored against your own number', 'the better round against your playing number',
                     'beat your own number', "against everyone's own number"];
    for (const t of probes2) if (!offends(t)) hits.push(`self-test failed: §42 no longer catches ${JSON.stringify(t)} (NW-4)`);
    /* the OPPONENT'S-SCORE sense, which the ruling keeps — every live instance,
       by name, so the widened frames can never start eating it. */
    const keep = ['Beat your number', 'BEAT THEIR NUMBER', 'Your number builds itself from three posted rounds.',
                  'That builds your number and nothing else.', 'Building your number',
                  'The number to beat', 'the number to beat is 31', 'THE NUMBER TO BEAT'];
    for (const t of keep) if (offends(t)) hits.push(`self-test failed: §42 caught ${JSON.stringify(t)}, which the ruling KEEPS`);
  }

  hits.length === 0
    ? pass('the gloss says playing HCP, the five bands do not', `${swift42.length} Swift file(s) + index.html + the live SQL generators · ${BANDS.length} band(s) held to spec §2.2`)
    : fail('the gloss says playing HCP, the five bands do not', `${hits.length} hit(s) — ` + hits.slice(0, process.env.CS_LINT_ALL ? 99 : 6).join('\n           '));
}

/* 43 · the bag says one sentence on both clients (R-O, D262) ----------------
   The bag has ONE line that carries the whole feature —

     "Since the new driver went in: four rounds, two beat your playing HCP."

   — and it is minted twice, once in Swift (`BagCopy.sinceLine`) and once in
   JavaScript (`csBagSince`), because a Swift producer cannot run in a browser.
   That is exactly the shape D259 caught drifting: the phone had a producer,
   the web hand-typed the words, and nothing compared them. So the FRAGMENTS
   are compared here, and the fourteen with them, because a cap that disagrees
   between two clients is a bag one of them will not let you fill.

   It also holds the acronym: R-M's noun is `playing HCP` and two producers
   have already shipped `playing hcp` by lower-casing a whole sentence. Neither
   of these may. */
{
  const swift = readFileSync(join(root, 'apps', 'ios', 'Packages', 'CupSeasonKit', 'Sources',
                                  'CupSeasonKit', 'Bag', 'Bag.swift'), 'utf8');
  const hits = [];
  const phone = swift.match(/static func sinceLine\([\s\S]*?\n  \}/)?.[0];
  const desk = html.match(/function csBagSince\(s, isMe\)\{[\s\S]*?\n\}/)?.[0];
  /* every fragment the sentence is built from, in both languages */
  const FRAGMENTS = ['Since the new ', ' went in: ', ' round', ' beat your playing HCP', 'none of them beat your playing HCP'];
  for (const [who, src] of [['BagCopy.sinceLine', phone], ['index.html csBagSince()', desk]]) {
    if (!src) { hits.push(`${who} not found — the bag's one sentence moved and this check went blind`); continue; }
    for (const f of FRAGMENTS) if (!src.includes(f)) hits.push(`${who} no longer says ${JSON.stringify(f)} — the two clients would say the bag's line differently`);
    if (/playing hcp/.test(src)) hits.push(`${who} lower-cases the acronym — it is "playing HCP" (R-M)`);
  }
  /* fourteen, in both clients. The server refuses the fifteenth; these are
     what the screens say before it gets there. */
  const phoneCap = swift.match(/public static let cap = (\d+)/)?.[1];
  const deskCap = html.match(/const CS_BAG_CAP = (\d+)/)?.[1];
  if (phoneCap !== '14') hits.push(`BagCopy.cap is ${phoneCap ?? 'missing'} — R-O says fourteen`);
  if (deskCap !== '14') hits.push(`CS_BAG_CAP is ${deskCap ?? 'missing'} — R-O says fourteen`);
  if (phoneCap !== deskCap) hits.push('the two clients disagree about how many clubs a bag holds');
  /* the refusal, as a lint: no equipment catalogue crept in behind the free
     text (R-O's written refusal, D250 sense) */
  const bagMig = readdirSync(migDir).filter(f => /whats_in_the_bag/.test(f))
    .map(f => readFileSync(join(migDir, f), 'utf8')).join('\n');
  if (bagMig && /create table[^;]*\b(club_models|club_brands|equipment)\b/i.test(bagMig)) {
    hits.push('the bag grew an equipment catalogue — R-O refuses one in writing');
  }
  /* the self-test: a check that cannot fail is not a check */
  {
    const broken = 'let line = "Since the new " + w + " went in: " + n + " rounds, two beat your playing hcp."';
    if (!/playing hcp/.test(broken)) hits.push('self-test failed: §43 no longer notices a lower-cased acronym');
    if (FRAGMENTS.every(f => 'a line that says nothing of the sort'.includes(f))) hits.push('self-test failed: §43 fragments match anything');
  }
  hits.length === 0
    ? pass('the bag says one sentence on both clients', `${FRAGMENTS.length} fragment(s) × 2 producer(s) · cap ${phoneCap} on both`)
    : fail('the bag says one sentence on both clients', `${hits.length} hit(s) — ` + hits.slice(0, 6).join('\n           '));
}

/* 44 · the visual-system lint, and it lands with a baseline (D274) --------
   `LINT-01…29` extend this file over both clients. They fall on roughly 2,300
   sites that were written before the system existed, and `ship.sh` refuses to
   ship anything if preflight fails — so a check that lands at zero tolerance
   blocks every push for the rest of a multi-session build.

   So each check lands with an entry in `tests/preflight-baselines.json`
   holding TODAY's count, and fails only when the count RISES. The moment a
   baseline reaches 0 it is zero-tolerance for ever after, and this helper says
   so on the line. Lower a baseline in the same commit that lowers the count;
   the line tells you the number to write.

   Wave 0a lands the mechanism and LINT-04, the one that belongs to the tokens.
   The other twenty-eight land with the component vocabulary they police. */
const BASELINES = (() => {
  const p = join(root, 'tests', 'preflight-baselines.json');
  try { return JSON.parse(readFileSync(p, 'utf8')).checks ?? {}; } catch { return {}; }
})();

/** A lint with a ratchet. Fails on a RISE; names the new floor on a fall. */
const lint = (id, name, hits, note = '') => {
  const base = BASELINES[id];
  const n = hits.length;
  if (base === undefined) {
    return n === 0 ? pass(`${id} · ${name}`, note)
                   : fail(`${id} · ${name}`, `${n} hit(s) and no baseline in tests/preflight-baselines.json — add "${id}": ${n} and lower it as you go\n           ` + hits.slice(0, 5).join('\n           '));
  }
  if (n > base) {
    return fail(`${id} · ${name}`, `${n} hit(s), up from a baseline of ${base} — ${n - base} NEW\n           ` + hits.slice(0, 6).join('\n           '));
  }
  if (n < base) return pass(`${id} · ${name}`, `${n} left of ${base} — lower the baseline to ${n} in this commit${note ? ' · ' + note : ''}`);
  return pass(`${id} · ${name}`, base === 0 ? `zero, and held there${note ? ' · ' + note : ''}` : `${n} at baseline, and none new${note ? ' · ' + note : ''}`);
};

/* LINT-04 · every radius is a token. The audit counted 91 hand-typed radii in
   11 distinct values against 5 the system owns — which is what makes a corner
   read as "some rounding" rather than as a panel, a control, a sheet or an
   object. The five are r 16 · rc 10 · rs 24 · p 3 · rx 28; a pill is a
   Capsule() on the phone and 99/999px on the web, and neither is a radius. */
{
  const LEGAL = new Set(['16', '10', '24', '3', '28']);
  const PILL = new Set(['99', '999', '9999']);
  const hits = [];
  const iosRoot = join(root, 'apps', 'ios');
  const swiftAll = (await import('../tools/extract-strings.mjs')).swiftSources(iosRoot);
  for (const f of swiftAll) {
    if (/\/Tests\/|\/Generated\//.test(f)) continue;
    const rel = f.slice(root.length).replace(/^\//, '');
    readFileSync(f, 'utf8').split('\n').forEach((line, i) => {
      for (const m of line.matchAll(/cornerRadius: *([0-9]+(?:\.[0-9]+)?)/g)) {
        const v = m[1].replace(/\.0$/, '');
        if (!LEGAL.has(v) && !PILL.has(v)) hits.push(`${rel}:${i + 1} cornerRadius: ${m[1]}`);
      }
    });
  }
  html.split('\n').forEach((line, i) => {
    for (const m of line.matchAll(/border-radius: *([0-9]+(?:\.[0-9]+)?)px/g)) {
      const v = m[1].replace(/\.0$/, '');
      if (!LEGAL.has(v) && !PILL.has(v)) hits.push(`index.html:${i + 1} border-radius:${m[1]}px`);
    }
  });
  /* the self-test: a check that cannot fail is not a check */
  if (!/cornerRadius: *([0-9]+)/.test('RoundedRectangle(cornerRadius: 7)')) {
    hits.push('self-test failed: LINT-04 no longer notices a hand-typed radius');
  }
  lint('LINT-05', 'every radius is one of the five', hits, 'r 16 · rc 10 · rs 24 · p 3 · rx 28');
}

/* 45 · the visual-system lint, the component half (D274, IOS-045) ---------
   Wave 0a landed the ratchet and the radius check. These are the checks that
   police the VOCABULARY, and they land with the vocabulary rather than before
   it — a check for "use CSFigure" written before CSFigure exists is a check
   that can only be satisfied by deleting it.

   THE IDS NOW MATCH `UI_SYSTEM` §17, AND ONE OF THEM MOVED TO GET THERE.
   Wave 0a shipped the radius check as `LINT-04`; §17's `LINT-04` is the colour
   literal and `LINT-05` is the radius. With exactly one check in the file the
   rename is free, and the alternative was a table and a codebase disagreeing
   about a name for the rest of a twelve-wave build — which is the specific
   failure this wave exists to prevent. The baseline key moved with it.

   Each check reports every hit it finds and fails only when the COUNT RISES.
   A baseline is a debt written down, which is the only kind worth having. */
{
  const { swiftSources } = await import('../tools/extract-strings.mjs');
  const iosRoot = join(root, 'apps', 'ios');
  const files = swiftSources(iosRoot).filter(f => !/\/Tests\//.test(f));
  const design = join(iosRoot, 'Packages', 'CSDesign', 'Sources', 'CSDesign');
  const src = files.map(f => ({
    path: f,
    rel: f.slice(root.length).replace(/^\//, ''),
    inDesign: f.startsWith(design),
    lines: readFileSync(f, 'utf8').split('\n'),
  }));

  /** Every line matching `re`, as "path:line text", skipping files by regex. */
  const scan = (re, { skip = null, only = null, max = 400 } = {}) => {
    const out = [];
    for (const f of src) {
      if (skip && skip.test(f.rel)) continue;
      if (only && !only.test(f.rel)) continue;
      f.lines.forEach((line, i) => {
        if (line.trimStart().startsWith('//')) return;          // a comment is not a call site
        if (re.test(line) && out.length < max) out.push(`${f.rel}:${i + 1} ${line.trim().slice(0, 90)}`);
      });
    }
    return out;
  };

  /* LINT-01 · no face by PostScript string. The four names live in one file;
     everywhere else `.custom("` is how D258 happens — silently, in SF Pro. */
  lint('LINT-01', 'no face named by string outside the type file',
       scan(/\.custom\(\s*"/, { skip: /CSDesign\/(Type|Typography)\.swift/ }),
       'CSType holds the four names, read from the files’ own name table');

  /* LINT-03 · no bare system font. A size typed at a call site is a size that
     is in no table, scales against no text style and declares no leading. */
  lint('LINT-03', 'no bare system font outside the type file',
       scan(/\.system\(size:/, { skip: /CSDesign\// }),
       'nine roles, fourteen symbols — no surface may name a size');

  /* LINT-04 · no colour literal in Swift (check 15's sibling, scoped to the
     forms a component reaches for). Generated/Tokens.swift is the one source. */
  /* `CredentialDev` and the developer harness draw a GREYSCALE stand-in
     subject on purpose — the scrim's worst case is a nearly-white patch, and a
     plausible warm portrait would have flattered it. Both are `#if DEBUG` and
     neither ships, so they are exempt BY NAME rather than by a baseline: a
     baseline on a zero-tolerance check is a hole with a number written on it. */
  lint('LINT-04', 'no colour invented in Swift',
       scan(/(Color|UIColor)\((red|white|hue):/, { skip: /Generated\/|CredentialDev\.swift|DeveloperHarness\.swift/ }),
       'every value comes from tokens.json; the two DEBUG fixtures are exempt by name');

  /* LINT-09 · no border. The system has NO BORDER TOKEN; the only outlines are
     the focus ring, the face's inset ring, the leaf's light edge and the
     scorecard marks. `.stroke(` anywhere else is a box coming back. */
  lint('LINT-09', 'no border outside the four outlines the system allows',
       scan(/\.stroke\(/, { skip: /CSDesign\// }),
       'focus ring · face ring · leaf edge (light) · the scorecard marks');

  /* LINT-10 · no rounded rectangle outside CSDesign. 338 hand-rolled
     containers against 34 component uses is the audit's whole finding. */
  lint('LINT-10', 'no container shape drawn outside CSDesign',
       scan(/(RoundedRectangle\(|Capsule\(\))/, { skip: /CSDesign\// }),
       'band · rule · rail · panel · leaf · object');

  /* LINT-12 · no emoji. Reactions keep the six canon glyphs; everything else
     is a drawn stroke. The range is the pictographic block plus the two
     dingbat runs the audit actually found in the product. */
  lint('LINT-12', 'no emoji outside the six reactions',
       scan(/[\u{1F300}-\u{1FAFF}\u{2600}-\u{27BF}\u{2B00}-\u{2BFF}]/u,
            { skip: /Reactions\.swift|CSDesign\/Generated\// }),
       'the six canon reactions and a golfer’s own typed text');

  /* LINT-13 · no typed arrow inside a produced string. The set is the one §17
     names; `−` (minus), `–` (en dash) and `—` (em dash) are
     explicitly exempt, because a first draft that matched a bare `v` and a
     bare `^` failed thousands of innocent strings and would have been turned
     off on its first run. */
  lint('LINT-13', 'no typed arrow in a produced string',
       scan(/"[^"]*[→←▲▼↑↓⇧⇩][^"]*"/),
       'movement is a drawn mark; a link’s arrow is absorbed into its underline');

  /* LINT-14 · no uppercasing in a string. Case is a role's job; `.uppercased()`
     breaks VoiceOver and localisation, and the shipped product produces the
     same label three ways. */
  lint('LINT-14', 'case is a role’s job, never a string’s',
       scan(/\.uppercased\(\)/, { skip: /CSDesign\/Generated\// }),
       '.textCase(.uppercase) is the one way');

  /* LINT-22 · no spinner in content. A spinner inside a CONTROL is legal and
     is three mono dots that tally; a spinner inside content is the loading
     state the system replaces with the destination's own geometry. */
  lint('LINT-22', 'no spinner inside content',
       scan(/ProgressView\(/, { skip: /CSDesign\/Controls\.swift/ }),
       'loading is the destination’s own geometry, redacted');

  /* LINT-25 · one dismiss verb. Three verbs in three colours at two positions
     plus an xmark circle is the single most visible inconsistency a golfer
     meets, because they meet it on 84 sheets and 11 covers. */
  lint('LINT-25', 'one dismiss verb, and it is Close',
       scan(/(Button\("(Done|Cancel|Dismiss)"|systemName: "xmark)/),
       'Close, a toolbar tertiary at topBarTrailing, never ember');

  /* LINT-28 · the pennant is reserved to the tab band and the app icon. Nine
     flags carrying seven meanings, on the product's core symbol, is ICO-12.
     `MainTabView` joins the skip in Wave 1: the band is the product's own now
     (§12.1) and its five glyphs are DECLARED there, so the one site that names
     the flag legitimately is the tab band's own item list. The check's job is
     unchanged — a pennant anywhere else is still a failure. */
  lint('LINT-28', 'the pennant is reserved',
       scan(/\.pennant\b/, { skip: /CSDesign\/(Chrome)\.swift|Dev\/|Main\/MainTabView\.swift/ }),
       'the tab band and the app icon, and nowhere else');

  /* LINT-29 · `dim` is a hairline/dot tier, never a word. IOS-013 already
     routes web `dim` text to `mut` on the phone; this stops it coming back. */
  lint('LINT-29', '`dim` is never a word',
       scan(/foregroundStyle\((cs|palette)\.dim\)/, { skip: /CSDesign\// }),
       'dimText is the tier that passes AA');

  /* LINT-30 · the four retired M0 components, counted while they wait. Each is
     kept ONLY until the wave that migrates its call sites — Waves 1–7 take the
     surfaces, Wave 8 the remainder, Wave 9 deletes the declarations. A shim
     with no named removal is not a shim; it is a second system. This is what
     stops anything NEW being written against them in the meantime. */
  lint('LINT-30', 'nothing new is written against a retired component',
       scan(/\b(CSCard|CSStat|CSEmptyState|CSHairline|CSButton)\s*[(<]/, { skip: /CSDesign\/(Components|Surfaces)\.swift/ }),
       'band · rule · panel · leaf · CSFigure · CSEmpty · CSRule · the three ButtonStyles');

  /* LINT-31 · a face drawn before its surface plumbed the profile id through.
     §6.2a keys the pigment to the GOLFER; `.unkeyed` keys it to the marker, so
     two golfers who chose the same glyph share a coin. Deterministic, frozen,
     named — and ratcheted to zero rather than allowed to spread. */
  lint('LINT-31', 'every face is keyed to a golfer, not to a glyph',
       scan(/CSFace\.Model\.unkeyed|\.unkeyed\(marker:/, { skip: /CSDesign\// }),
       'Waves 1, 3 and 8 plumb the id through the four rows that lack it');
}

console.log(`\n${fails ? 'FAIL' : 'PASS'} — ${fails} failure(s), ${warns} warning(s)`);
process.exit(fails ? 1 : 0);
