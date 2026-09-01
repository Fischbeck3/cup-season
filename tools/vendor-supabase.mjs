#!/usr/bin/env node
/* ============================================================================
 * vendor-supabase.mjs — pull a PINNED supabase-js browser build into vendor/.
 *
 * WHY: the client used to boot from `import … from 'https://esm.sh/…@2'`, the
 * first line of the ONE module block that holds every door handler and boot
 * itself. A filtered network, a DNS blocklist or a CDN outage meant the module
 * never executed: the door rendered perfectly and every button did nothing,
 * with no watchdog (it is module-side) and no error bar (debug-gated off).
 * Reproduced exactly in a sandbox whose proxy blocked esm.sh, 2026-09-01.
 * The library is now same-origin, cached by the service worker, and pinned to
 * an exact version so two users on the same stamped build run the same code.
 *
 * STABLE FILENAME, version in the manifest. A versioned filename would couple
 * three hand-edited lines (the script tag, sw.js's SHELL, stamp-version.sh)
 * that must move together on every bump — the exact collision pattern
 * CLAUDE.md rule 2 killed for the version line. One command rewrites one file.
 *
 *   node tools/vendor-supabase.mjs [version]   re-vendor (default: pinned)
 *   node tools/vendor-supabase.mjs --check     verify sha256, exit 1 on drift
 * ========================================================================== */
import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { mkdtempSync, readFileSync, writeFileSync, rmSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const OUT = join(root, 'vendor', 'supabase-js.js');
const MAN = join(root, 'vendor', 'manifest.json');
const PKG = '@supabase/supabase-js';
/* The pin. Bump deliberately: `node tools/vendor-supabase.mjs 2.113.0`, then
   commit vendor/supabase-js.js and vendor/manifest.json together. */
const PINNED = '2.112.4';

const sha256 = (buf) => createHash('sha256').update(buf).digest('hex');

if (process.argv.includes('--check')) {
  let man, lib;
  try {
    man = JSON.parse(readFileSync(MAN, 'utf8'));
    lib = readFileSync(OUT);
  } catch (e) {
    console.error('[vendor] MISSING — run `node tools/vendor-supabase.mjs`:', e.message);
    process.exit(1);
  }
  const got = sha256(lib);
  if (got !== man.sha256) {
    console.error(`[vendor] DRIFT — vendor/supabase-js.js does not match the manifest.\n  manifest ${man.sha256}\n  file     ${got}`);
    process.exit(1);
  }
  console.log(`[vendor] ok — ${man.package}@${man.version}, ${lib.length} bytes, sha256 ${got.slice(0, 12)}…`);
  process.exit(0);
}

const version = process.argv[2] && !process.argv[2].startsWith('-') ? process.argv[2] : PINNED;
const tmp = mkdtempSync(join(tmpdir(), 'cs-vendor-'));
try {
  console.log(`[vendor] npm pack ${PKG}@${version}`);
  const tgz = execFileSync('npm', ['pack', `${PKG}@${version}`, '--silent', '--pack-destination', tmp],
    { encoding: 'utf8' }).trim().split('\n').pop();
  execFileSync('tar', ['-xzf', join(tmp, tgz), '-C', tmp]);

  /* dist/umd/supabase.js is the self-contained browser build: it defines the
     global `supabase` and needs no bundler. dist/index.mjs is NOT usable
     directly — it carries bare specifiers (@supabase/auth-js et al). */
  const src = readFileSync(join(tmp, 'package', 'dist', 'umd', 'supabase.js'));
  if (!src.length) throw new Error('umd build is empty');

  mkdirSync(join(root, 'vendor'), { recursive: true });
  writeFileSync(OUT, src);
  const hash = sha256(src);
  writeFileSync(MAN, JSON.stringify({
    package: PKG,
    version,
    file: 'vendor/supabase-js.js',
    bytes: src.length,
    sha256: hash,
    global: 'supabase',
    source: 'npm dist/umd/supabase.js',
    why: 'same-origin + pinned; see the header of tools/vendor-supabase.mjs',
  }, null, 2) + '\n');
  console.log(`[vendor] wrote vendor/supabase-js.js — ${src.length} bytes, sha256 ${hash.slice(0, 12)}…`);
  console.log('[vendor] remember: sw.js SHELL and stamp-version.sh already reference this path.');
} finally {
  rmSync(tmp, { recursive: true, force: true });
}
