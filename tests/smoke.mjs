#!/usr/bin/env node
/* ============================================================================
 * smoke.mjs — drive the REAL built dist/ in a real browser.
 *
 * WHY: every other check in this repo is static. The failure that prompted this
 * one was not: the sign-in door rendered pixel-perfect while every button on it
 * silently did nothing, because the data layer came from a CDN that a filtered
 * network could not reach (D186). Nothing in preflight could see that, no
 * telemetry recorded it (the reporter was inside the dead module), and the
 * console was clean. It was found by a human clicking a button.
 *
 * It runs against dist/, not the repo root, on purpose: dist/ is what Netlify
 * publishes, so a missing entry in stamp-version.sh's allowlist — the single
 * highest-consequence line in the client — fails HERE instead of in production.
 *
 *   node tests/smoke.mjs           (expects dist/ built, playwright installed)
 * ========================================================================== */
import { chromium } from 'playwright';
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';
import { existsSync } from 'node:fs';
import { join, extname, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const DIST = join(root, 'dist');
if (!existsSync(join(DIST, 'index.html'))) {
  console.error('X  dist/index.html missing — run `bash ./stamp-version.sh` first');
  process.exit(1);
}
const MIME = { '.html':'text/html', '.js':'text/javascript', '.css':'text/css', '.png':'image/png',
  '.svg':'image/svg+xml', '.webmanifest':'application/manifest+json', '.json':'application/json' };

let fails = 0;
const ok   = (n, note='') => console.log(`  PASS  ${n}${note ? ' — ' + note : ''}`);
const bad  = (n, note)    => { fails++; console.log(`X FAIL  ${n} — ${note}`); };
const is   = (n, got, want) => got === want ? ok(n) : bad(n, `got ${JSON.stringify(got)}, want ${JSON.stringify(want)}`);

const server = createServer(async (req, res) => {
  const p = decodeURIComponent(req.url.split('?')[0]);
  const f = join(DIST, p === '/' ? 'index.html' : p);
  try {
    const body = await readFile(f);
    res.writeHead(200, { 'content-type': MIME[extname(f)] || 'application/octet-stream' });
    res.end(body);
  } catch { res.writeHead(404).end('nope'); }
});
await new Promise(r => server.listen(0, r));
const base = `http://127.0.0.1:${server.address().port}/`;

const browser = await chromium.launch({
  executablePath: process.env.CHROMIUM_PATH || undefined,
  args: ['--no-sandbox'],
});

try {
  /* ---- 1 · the door boots and its controls are WIRED -------------------- */
  {
    const ctx = await browser.newContext({ viewport:{width:390,height:844}, reducedMotion:'reduce' });
    const page = await ctx.newPage();
    const errors = [];
    page.on('pageerror', e => errors.push(String(e).slice(0,160)));
    const offOrigin = [];
    page.on('request', r => { if (!r.url().startsWith(base) && !r.url().startsWith('data:')) offOrigin.push(r.url()); });

    await page.goto(base, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(9000);

    is('door: the data layer loaded', await page.evaluate(() => typeof window.supabase), 'object');
    is('door: the classic<->module bridge is up', await page.evaluate(() => typeof window.sb), 'object');
    is('door: no dead-boot banner', await page.evaluate(() => !!window.__csDead), false);

    /* THE regression: a beautiful door whose buttons do nothing. */
    await page.evaluate(() => document.getElementById('obEmail')?.click());
    await page.waitForTimeout(700);
    is('door: "Continue with email" actually opens the box',
       await page.evaluate(() => { const e = document.getElementById('obEmailIn'); return !!(e && e.offsetParent !== null); }), true);

    /* D189 · the story is static, so it must read even here */
    is('door: the how-it-works story is present',
       await page.evaluate(() => document.querySelectorAll('#obMore .obm-row').length), 5);

    /* nothing on the boot path may be cross-origin (D186). Fonts are a
       stylesheet, not the boot path — allow only that host. */
    const badOrigins = offOrigin.filter(u => !/^https:\/\/fonts\.(googleapis|gstatic)\.com\//.test(u));
    badOrigins.length === 0
      ? ok('door: nothing off-origin on the boot path', `${offOrigin.length} font request(s) only`)
      : bad('door: something off-origin loaded', badOrigins.slice(0,3).join(' · '));

    errors.length === 0 ? ok('door: no uncaught page errors') : bad('door: uncaught page errors', errors.join(' | '));
    await ctx.close();
  }

  /* ---- 2 · a dead data layer SAYS SO ------------------------------------ */
  {
    const ctx = await browser.newContext({ viewport:{width:390,height:844}, reducedMotion:'reduce' });
    const page = await ctx.newPage();
    await page.route('**/vendor/supabase-js.js', r => r.abort());
    await page.goto(base, { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(3500);
    const s = await page.evaluate(() => ({
      dead: !!window.__csDead,
      status: (document.getElementById('obStatus') || {}).textContent || '',
      reload: !!document.getElementById('csReload'),
      emailDisabled: document.getElementById('obEmail')?.hasAttribute('disabled') === true,
      story: document.querySelectorAll('#obMore .obm-row').length,
    }));
    is('dead boot: the detector fires', s.dead, true);
    s.status.length > 10 ? ok('dead boot: it says so on screen', s.status.slice(0,44)) : bad('dead boot: silent', JSON.stringify(s));
    is('dead boot: a Reload control appears', s.reload, true);
    is('dead boot: the dead CTA is disabled', s.emailDisabled, true);
    is('dead boot: the static story still reads', s.story, 5);
    await ctx.close();
  }

  /* ---- 3 · the a11y floor holds in a real browser (D190) ---------------- */
  {
    const ctx = await browser.newContext({ viewport:{width:390,height:844}, reducedMotion:'reduce' });
    const page = await ctx.newPage();
    await page.goto(base + '?exit', { waitUntil: 'domcontentloaded' });
    await page.waitForTimeout(9000);
    await page.evaluate(() => { const o = document.getElementById('onboard'); if (o) { o.classList.add('hide'); o.style.display='none'; } });

    const fails4 = await page.evaluate(() => {
      const lum = h => { const m = h.match(/[\d.]+/g); if (!m) return null;
        const [r,g,b] = m.slice(0,3).map(Number).map(c => c/255);
        const f = c => c <= 0.03928 ? c/12.92 : Math.pow((c+0.055)/1.055, 2.4);
        return 0.2126*f(r) + 0.7152*f(g) + 0.0722*f(b); };
      const bgOf = el => { let n = el;
        while (n && n !== document.documentElement) {
          const c = getComputedStyle(n).backgroundColor;
          if (c && !/rgba\(0, 0, 0, 0\)|transparent/.test(c)) return c;
          n = n.parentElement; }
        return getComputedStyle(document.body).backgroundColor; };
      const out = [];
      document.querySelectorAll('body *').forEach(el => {
        if (!el.offsetParent) return;
        if (![...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim().length > 1)) return;
        const cs = getComputedStyle(el);
        if (cs.visibility === 'hidden' || cs.opacity === '0') return;
        const lf = lum(cs.color), lb = lum(bgOf(el));
        if (lf == null || lb == null) return;
        const r = (Math.max(lf,lb)+0.05) / (Math.min(lf,lb)+0.05);
        /* --brand accent pairs are a known, recorded exception (D190) */
        if (r < 4.5 && !/var\(--brand\)/.test(cs.color) && r < 3.5)
          out.push(`${el.className || el.tagName} ${r.toFixed(2)}:1 "${el.textContent.trim().slice(0,20)}"`);
      });
      return out;
    });
    fails4.length === 0 ? ok('a11y: no text under 3.5:1 in dark') : bad('a11y: low-contrast text', fails4.slice(0,4).join(' · '));

    const trap = await page.evaluate(async () => {
      const t = document.createElement('button'); t.id='smokeTrap'; document.body.appendChild(t); t.focus();
      openSheet('Smoke','S','<button id="si">in</button>');
      await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
      const inside = document.getElementById('sheet').contains(document.activeElement);
      const inert = document.querySelector('.shell')?.inert === true;
      closeSheet();
      await new Promise(r => setTimeout(r, 60));
      const back = document.activeElement.id;
      const left = document.querySelectorAll('[inert]').length;
      t.remove();
      return { inside, inert, back, left };
    });
    is('a11y: focus moves into an open dialog', trap.inside, true);
    is('a11y: the page behind goes inert', trap.inert, true);
    is('a11y: focus returns to the trigger', trap.back, 'smokeTrap');
    is('a11y: nothing is left inert', trap.left, 0);
    await ctx.close();
  }
} finally {
  await browser.close();
  server.close();
}

console.log(`\n${fails ? 'FAIL' : 'PASS'} — ${fails} failure(s)`);
process.exit(fails ? 1 : 0);
