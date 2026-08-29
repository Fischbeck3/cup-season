#!/usr/bin/env node
// bx — a tiny persistent-browser CLI for blind usability agents.
//
//   node bx.mjs start <session> [--desktop]     start a headless Chromium daemon for <session>
//   node bx.mjs <session> <command> [args...]   send a command to that session
//   node bx.mjs <session> stop                  shut the daemon down
//
// Commands (all print plain text; errors print "ERR: ..."):
//   goto <url>                 navigate (waits for load + 1.2s settle)
//   text                       visible text of the page (what a user can read right now)
//   tree                       accessibility tree (roles + names — what a user can tap)
//   shot [label]               save a screenshot PNG and print its path (Read it to LOOK)
//   click <text|css=...|role=button name=...>   click the first visible match
//   fill <css-or-label> <value>                 fill an input (by CSS selector, placeholder, or label text)
//   type <text>                type into the focused element
//   press <key>                press a key (Enter, Escape, Tab, ArrowDown...)
//   scroll <dy>                scroll the page by dy pixels (negative = up)
//   back                       history back
//   url                        current URL
//   eval <js>                  evaluate JS in the page (returns JSON)
//   console                    dump recent console errors/warnings (then clears)
//   wait <ms>                  sleep
//
// Sessions persist localStorage across commands (the daemon keeps the page alive).
import { chromium, devices } from 'playwright';
import net from 'node:net';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const here = path.dirname(fileURLToPath(import.meta.url));
const sessDir = path.join(here, 'sessions');
const shotDir = path.join(here, 'shots');
fs.mkdirSync(sessDir, { recursive: true });
fs.mkdirSync(shotDir, { recursive: true });

const [, , a, b, ...rest] = process.argv;
if (!a) { console.log(fs.readFileSync(fileURLToPath(import.meta.url), 'utf8').split('\n').slice(1, 26).join('\n')); process.exit(0); }

if (a === 'start') {
  const session = b;
  if (!session) { console.error('ERR: session name required'); process.exit(1); }
  const sock = portOf(session);
  if (await probe(sock)) { console.log(`session ${session} already running`); process.exit(0); }
  const desktop = rest.includes('--desktop');
  const child = spawn(process.execPath, [fileURLToPath(import.meta.url), '__daemon', session, desktop ? '--desktop' : ''], {
    detached: true, stdio: ['ignore', fs.openSync(path.join(sessDir, session + '.log'), 'a'), fs.openSync(path.join(sessDir, session + '.log'), 'a')],
  });
  child.unref();
  // wait for the socket
  for (let i = 0; i < 100; i++) {
    await new Promise(r => setTimeout(r, 150));
    if (await probe(sock)) { console.log(`session ${session} started (${desktop ? 'desktop' : 'iPhone'} viewport)`); process.exit(0); }
  }
  console.error('ERR: daemon did not come up; see ' + path.join(sessDir, session + '.log'));
  process.exit(1);
}

if (a === '__daemon') { await daemon(b, rest.includes('--desktop')); }
else { await client(a, b, rest); }

function portOf(session) { let h = 7; for (const ch of session) h = (h * 31 + ch.charCodeAt(0)) % 100000; return 45000 + (h % 5000); }
function probe(port) {
  return new Promise(res => {
    const c = net.createConnection({ port, host: '127.0.0.1' });
    c.on('connect', () => { c.write(JSON.stringify({ cmd: 'ping' }) + '\n'); });
    c.on('data', () => { c.end(); res(true); });
    c.on('error', () => res(false));
    setTimeout(() => { try { c.destroy(); } catch { } res(false); }, 1500);
  });
}

async function client(session, cmd, args) {
  const port = portOf(session);
  if (!(await probe(port))) { console.error(`ERR: no session '${session}' — run: node bx.mjs start ${session}`); process.exit(1); }
  await new Promise((resolve) => {
    const c = net.createConnection({ port, host: '127.0.0.1' });
    let buf = '';
    c.on('connect', () => c.write(JSON.stringify({ cmd, args }) + '\n'));
    c.on('data', d => { buf += d.toString(); });
    c.on('end', () => { process.stdout.write(buf.endsWith('\n') ? buf : buf + '\n'); resolve(); });
    c.on('error', e => { console.error('ERR: ' + e.message); resolve(); });
  });
}

async function daemon(session, desktop) {
  const port = portOf(session);
  const userDataDir = path.join(sessDir, session + '.profile');
  const ctxOpts = desktop
    ? { viewport: { width: 1280, height: 860 }, deviceScaleFactor: 1 }
    : { ...devices['iPhone 13'], };
  // reduceMotion helps screenshots settle; the app's splash animates.
  const context = await chromium.launchPersistentContext(userDataDir, { headless: true, reducedMotion: 'reduce', ...ctxOpts });
  const page = context.pages()[0] || await context.newPage();
  const consoleBuf = [];
  page.on('console', m => { if (['error', 'warning'].includes(m.type())) consoleBuf.push(`[${m.type()}] ${m.text()}`.slice(0, 400)); });
  page.on('pageerror', e => consoleBuf.push(`[pageerror] ${String(e.message || e).slice(0, 400)}`));
  page.on('dialog', async d => { consoleBuf.push(`[dialog:${d.type()}] ${d.message()}`); try { await d.accept(); } catch { } });
  let shotN = 0;
  const shotSess = path.join(shotDir, session); fs.mkdirSync(shotSess, { recursive: true });

  const server = net.createServer(c => {
    let buf = '';
    c.on('data', async d => {
      buf += d.toString();
      if (!buf.includes('\n')) return;
      let req; try { req = JSON.parse(buf.trim()); } catch { c.end('ERR: bad request'); return; }
      let out;
      try { out = await handle(req.cmd, req.args || []); } catch (e) { out = 'ERR: ' + (e && e.message ? e.message.split('\n')[0] : String(e)); }
      if (req.cmd === 'stop') { c.end(out); server.close(); await context.close().catch(() => { }); process.exit(0); }
      c.end(String(out));
    });
  });
  server.listen(port, '127.0.0.1');
  process.on('SIGTERM', () => { process.exit(0); });

  async function settle(ms = 1200) { await page.waitForTimeout(ms); }
  function loc(target) {
    if (target.startsWith('css=')) return page.locator(target.slice(4)).first();
    if (target.startsWith('role=')) {
      const m = target.match(/^role=(\w+)(?:\s+name=(.+))?$/);
      return page.getByRole(m[1], m[2] ? { name: m[2].replace(/^"|"$/g, ''), exact: false } : {}).first();
    }
    if (target.startsWith('text=')) return page.getByText(target.slice(5), { exact: false }).first();
    // default: visible text match, then button/link by name, then placeholder/label
    return page.getByText(target, { exact: false }).filter({ visible: true }).first();
  }
  async function handle(cmd, args) {
    switch (cmd) {
      case 'ping': return 'pong';
      case 'goto': { await page.goto(args[0], { waitUntil: 'load', timeout: 20000 }); await settle(); return 'ok ' + page.url(); }
      case 'url': return page.url();
      case 'back': { await page.goBack({ timeout: 10000 }).catch(() => { }); await settle(600); return 'ok ' + page.url(); }
      case 'wait': { await settle(Number(args[0]) || 500); return 'ok'; }
      case 'text': {
        const t = await page.evaluate(() => {
          const walk = (el) => {
            const st = getComputedStyle(el);
            if (st.display === 'none' || st.visibility === 'hidden' || el.hidden || st.opacity === '0' || el.getAttribute('aria-hidden') === 'true') return '';
            if (el.tagName === 'SCRIPT' || el.tagName === 'STYLE' || el.tagName === 'NOSCRIPT' || el.tagName === 'TEMPLATE') return '';
            let s = '';
            for (const n of el.childNodes) {
              if (n.nodeType === 3) s += n.textContent.replace(/\s+/g, ' ');
              else if (n.nodeType === 1) {
                const tag = n.tagName;
                const inner = walk(n);
                if (!inner.trim()) { if ((tag === 'INPUT' || tag === 'TEXTAREA') && (n.placeholder || n.value)) s += ` [${tag === 'INPUT' ? (n.type || 'input') : 'textarea'}: ${n.value ? 'value="' + n.value + '"' : 'placeholder="' + n.placeholder + '"'}]`; continue; }
                const block = /^(DIV|P|H[1-6]|LI|UL|OL|SECTION|ARTICLE|HEADER|FOOTER|NAV|TR|TD|TH|LABEL|BUTTON|A|DETAILS|SUMMARY|FORM|FIELDSET|DL|DT|DD|BLOCKQUOTE|PRE|TABLE|ASIDE|MAIN|FIGURE|FIGCAPTION|SELECT|OPTION)$/.test(tag);
                const btn = tag === 'BUTTON' || (tag === 'A' && n.getAttribute('href')) || n.getAttribute('role') === 'button';
                s += (block ? '\n' : ' ') + (btn ? '[' + inner.trim() + ']' : inner) + (block ? '\n' : ' ');
              }
            }
            return s;
          };
          return walk(document.body).replace(/[ \t]+/g, ' ').replace(/\n\s*\n+/g, '\n').trim();
        });
        const dlg = await page.evaluate(() => { const d = [...document.querySelectorAll('dialog[open], [role=dialog], .sheet, .modal')].filter(e => { const s = getComputedStyle(e); const r = e.getBoundingClientRect(); return s.display !== 'none' && s.visibility !== 'hidden' && r.width > 0 && r.height > 0; }); return d.length ? '[NOTE: a dialog/sheet is open — the user sees ONLY the dialog; page text below it is covered]\n' : ''; }).catch(() => '');
        const out = dlg + t;
        return out.length > 12000 ? out.slice(0, 12000) + '\n…[truncated; use scroll + text, or eval]' : out;
      }
      case 'tree': {
        const y = await page.locator('body').ariaSnapshot();
        return y.length > 14000 ? y.slice(0, 14000) + '\n…[truncated]' : y;
      }
      case 'shot': {
        shotN++;
        const label = (args[0] || 'shot').replace(/[^a-z0-9_-]+/gi, '-').slice(0, 40);
        const p = path.join(shotSess, String(shotN).padStart(2, '0') + '-' + label + '.png');
        await page.screenshot({ path: p, fullPage: false, animations: 'disabled', timeout: 15000, caret: 'hide' });
        return p;
      }
      case 'shotfull': {
        shotN++;
        const label = (args[0] || 'full').replace(/[^a-z0-9_-]+/gi, '-').slice(0, 40);
        const p = path.join(shotSess, String(shotN).padStart(2, '0') + '-' + label + '.png');
        await page.screenshot({ path: p, fullPage: true, animations: 'disabled', timeout: 20000, caret: 'hide' });
        return p;
      }
      case 'click': {
        const target = args.join(' ');
        let l = loc(target);
        if (!(await l.count())) {
          // fall back to buttons/links by accessible name
          l = page.getByRole('button', { name: target, exact: false }).first();
          if (!(await l.count())) l = page.getByRole('link', { name: target, exact: false }).first();
          if (!(await l.count())) l = page.locator(`[aria-label*="${target}" i], [title*="${target}" i], [placeholder*="${target}" i]`).first();
        }
        if (!(await l.count())) return `ERR: nothing matches "${target}" (use 'tree' to see names, or css=...)`;
        await l.scrollIntoViewIfNeeded({ timeout: 5000 }).catch(() => { });
        await l.click({ timeout: 8000 });
        await settle(900);
        return 'clicked ' + JSON.stringify(target);
      }
      case 'fill': {
        const [sel, ...v] = args; const value = v.join(' ');
        let l = sel.startsWith('css=') ? page.locator(sel.slice(4)).first() : page.locator(sel).first();
        if (!sel.startsWith('css=')) {
          if (!(await l.count().catch(() => 0))) l = page.getByPlaceholder(sel, { exact: false }).first();
          if (!(await l.count())) l = page.getByLabel(sel, { exact: false }).first();
        }
        if (!(await l.count())) return `ERR: no input matches "${sel}"`;
        await l.fill(value, { timeout: 8000 });
        await settle(300);
        return 'filled';
      }
      case 'type': { await page.keyboard.type(args.join(' '), { delay: 20 }); await settle(300); return 'typed'; }
      case 'press': { await page.keyboard.press(args[0]); await settle(700); return 'pressed ' + args[0]; }
      case 'scroll': {
        const dy = Number(args[0]) || 600;
        await page.evaluate((dy) => { const sc = document.scrollingElement; const els = [...document.querySelectorAll('*')].filter(e => { const s = getComputedStyle(e); return /(auto|scroll)/.test(s.overflowY) && e.scrollHeight > e.clientHeight + 10 && e.getBoundingClientRect().height > 200; }); (els[0] || sc).scrollBy(0, dy); if (els[0]) sc.scrollBy(0, dy); }, dy);
        await settle(500);
        return 'scrolled ' + dy;
      }
      case 'eval': { const r = await page.evaluate(args.join(' ')); return typeof r === 'string' ? r : JSON.stringify(r, null, 1); }
      case 'console': { const o = consoleBuf.splice(0).join('\n'); return o || '(no console errors/warnings)'; }
      case 'stop': return 'stopped';
      default: return 'ERR: unknown command ' + cmd;
    }
  }
}
