// D403 (review of a3115801) · the consent write's account race, through the REAL shipped
// SDK. index.html's consent and scan functions run against an actual supabase-js client
// of the exact version index.html imports; only its fetch (a stand-in server) and its
// auth storage (another tab's sign-in writes there) are supplied. A storage read can be
// held open, which is where the race lives: supabase-js's fetchWithAuth resolves the
// token by awaiting the session when a request is SENT, then fills Authorization only
// when the request carries none.
//
// Needs the SDK on disk (the repo has no runtime dependencies):
//   npm install --prefix <dir> @supabase/supabase-js@<version index.html imports>
//   CS_SUPABASE_JS=<dir>/node_modules/@supabase/supabase-js node --test tests/scan-consent-sdk.test.mjs
// Without CS_SUPABASE_JS the tests are skipped (tests/scan-consent-flow.test.mjs covers the
// same boundary with a model of it). CS_INDEX=<path> runs another build of index.html.
import {readFileSync} from 'node:fs';
import {join} from 'node:path';
import {pathToFileURL} from 'node:url';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const source = readFileSync(process.env.CS_INDEX || new URL('../index.html', import.meta.url), 'utf8');
const sdkDir = process.env.CS_SUPABASE_JS || '';
const skip = sdkDir ? false : 'CS_SUPABASE_JS is not set (path to the supabase-js package index.html imports)';
const shipped = (readFileSync(new URL('../index.html', import.meta.url), 'utf8').match(/esm\.sh\/@supabase\/supabase-js@(\d+\.\d+\.\d+)/) || [])[1];

const between = (a, b) => {
  const i = source.indexOf(a), j = source.indexOf(b, i);
  assert.ok(i >= 0 && j > i, `slice ${a}`);
  return source.slice(i, j);
};
const consentCode = between('const CS_SCAN_CONSENT = {', '/* D376 ');
const runCode = between('async function csRunScan(f){', 'function scanPickRow(scan');
const settle = async () => { for (let i = 0; i < 60; i++) await new Promise((r) => setImmediate(r)); };
const deferred = () => { let resolve; const promise = new Promise((r) => { resolve = r; }); return { promise, resolve }; };
const b64u = (o) => Buffer.from(JSON.stringify(o)).toString('base64url');
const tokenFor = (uid, v = 1) => `${b64u({ alg: 'none' })}.${b64u({ sub: uid, v, exp: Math.floor(Date.now() / 1000) + 3600 })}.x`;
const subOf = (h) => { try { return JSON.parse(Buffer.from(String(h).replace(/^Bearer /, '').split('.')[1], 'base64url')).sub || null; } catch { return null; } };
const A = '00000000-0000-4000-8000-00000000000a';
const B = '00000000-0000-4000-8000-00000000000b';
const KEY = 'sb-cs-test-auth-token';
const sessionFor = (uid, v = 1) => JSON.stringify({
  access_token: tokenFor(uid, v), refresh_token: `refresh-${uid}-${v}`, token_type: 'bearer',
  expires_in: 3600, expires_at: Math.floor(Date.now() / 1000) + 3600,
  user: { id: uid, aud: 'authenticated', role: 'authenticated', email: `${uid}@example.test`,
          app_metadata: {}, user_metadata: {}, created_at: '2026-10-01T00:00:00Z' },
});
const json = (body, status = 200) => new Response(JSON.stringify(body), { status, headers: { 'content-type': 'application/json' } });

let createClient = null;
async function sdk() {
  if (!createClient) {
    const pkg = JSON.parse(readFileSync(join(sdkDir, 'package.json'), 'utf8'));
    assert.equal(pkg.version, shipped, `CS_SUPABASE_JS is ${pkg.version}; index.html imports ${shipped}`);
    ({ createClient } = await import(pathToFileURL(join(sdkDir, 'dist/index.mjs')).href));
  }
  return createClient;
}

/* One browser profile's storage, shared by its tabs: another tab's sign-in lands here
   first. `holdRead(n)` holds the nth session read from now open. */
function profileStorage() {
  const map = new Map();
  let reads = 0, holds = new Map();
  return {
    map,
    holdRead(n) { const d = deferred(); holds.set(reads + n, d); return d; },
    getItem: async (k) => {
      if (k === KEY) { const i = ++reads; const h = holds.get(i); if (h) await h.promise; }
      return map.has(k) ? map.get(k) : null;
    },
    setItem: async (k, v) => { map.set(k, v); },
    removeItem: async (k) => { map.delete(k); },
  };
}

/* The server applies every request to the account its Authorization header names. */
function server(consent = {}) {
  const s = { consent: { ...consent }, writes: [], sentAs: [], providerCalls: 0, unexpected: [], responseGate: null };
  s.fetch = async (input, init = {}) => {
    const url = String(typeof input === 'string' ? input : input.url);
    const who = subOf(new Headers(init.headers).get('Authorization'));
    if (url.includes('/rest/v1/rpc/set_scan_consent')) {
      const on = JSON.parse(init.body).p_on;
      if (s.responseGate) await s.responseGate.promise;
      s.writes.push({ uid: who, on });
      if (!who) return json({ message: 'JWT required' }, 401);
      s.consent[who] = on;
      return json(on);
    }
    if (url.includes('/functions/v1/scan')) {
      s.sentAs.push(who);
      if (!s.consent[who]) return json({ unavailable: true, reason: 'no_consent' }, 403);
      s.providerCalls++;
      return json({ ok: true, scan: { players: [{ name: 'Me', holes: Array(18).fill(4) }], par_row: Array(18).fill(4) } });
    }
    s.unexpected.push(url);
    return json({ message: 'unexpected' }, 500);
  };
  return s;
}

/* A signed-in tab: the real SDK client, the real page functions. */
async function tab(srv, uid) {
  const storage = profileStorage();
  storage.map.set(KEY, sessionFor(uid));
  const sb = (await sdk())('http://127.0.0.1:54321', 'sb_publishable_cs_test_only', {
    auth: { storage, storageKey: KEY, autoRefreshToken: false, persistSession: true, detectSessionInUrl: false },
    global: { fetch: srv.fetch },
  });
  await sb.auth.getSession();                          // initialised before the race starts
  const toasts = [], sheets = [], picked = [];
  let buttons = {};
  const CS = { user: { id: uid }, profile: { id: uid, scan_consent_at: srv.consent[uid] ? '2026-09-30T12:00:00Z' : null } };
  const win = { CS, csAuthGen: 1, sb };
  const btn = { innerHTML: 'Scan', disabled: false, textContent: '' };
  const context = vm.createContext({
    window: win, state: { demo: false }, console, atob: (x) => Buffer.from(x, 'base64').toString('binary'),
    localStorage: { getItem: () => null, setItem: () => {}, removeItem: () => {} },
    toast: (t) => toasts.push(t), esc: (x) => String(x),
    openSheet: (title) => { sheets.push(title); buttons = {}; }, closeSheet: () => {},
    document: { getElementById: (id) => (id === 'scnYes' || id === 'scnNo') ? { addEventListener: (_, fn) => { buttons[id] = fn; } } : null },
    $: (sel) => sel === '#postScanBtn' ? btn : null,
    compressPhoto: async (b) => b, b64ofBlob: async () => 'AAAA',
    refreshPostPhotoUI: () => {}, scanPickRow: (scan, stale) => picked.push({ scan, stale }),
  });
  vm.runInContext(consentCode + runCode, context);
  return {
    CS, toasts, sheets, picked, storage,
    tapScan: () => { if (context.csScanConsented()) context.csRunScan({ name: 'card.jpg' }); else context.csAskScanConsent(() => context.csRunScan({ name: 'card.jpg' })); },
    tapYes: () => { assert.ok(buttons.scnYes, 'the consent sheet is open'); buttons.scnYes(); },
    setConsent: (on) => context.csSetScanConsent(on),
    /* another tab signs in as `next`: the shared storage changes at once; this page's
       auth handler (the generation, then a boot) follows later */
    otherTabSignsIn: (next, { reached = false, boot = false } = {}) => {
      storage.map.set(KEY, sessionFor(next));
      if (reached) win.csAuthGen++;
      if (boot) { CS.user = { id: next }; CS.profile = { id: next, scan_consent_at: srv.consent[next] ? 'x' : null }; }
    },
    reachPage: (next) => { win.csAuthGen++; CS.user = { id: next }; CS.profile = { id: next, scan_consent_at: srv.consent[next] ? 'x' : null }; },
    otherTabSignsOut: ({ reached = false } = {}) => { storage.map.delete(KEY); if (reached) { win.csAuthGen++; CS.user = null; CS.profile = null; } },
    refreshed: () => storage.map.set(KEY, sessionFor(uid, 2)),
  };
}

test('the SDK under test is the version index.html imports', { skip }, async () => {
  await sdk();
});

for (const reached of [false, true]) {
  test(`real SDK · the review's reproduction${reached ? ' (sign-in already reached the page)' : ''}: B signs in while A's yes resolves its token — B's consent is unchanged`, { skip }, async () => {
    const srv = server({ [B]: false });
    const t = await tab(srv, A);
    t.tapScan();                                       // asked for A
    const hold = t.storage.holdRead(1);                // the next session read: the write's token
    t.tapYes(); await settle();
    t.otherTabSignsIn(B, { reached });
    hold.resolve(); await settle();
    t.reachPage(B); await settle();
    assert.deepEqual(srv.writes.filter((w) => w.uid === B), [], "A's yes went out as B");
    assert.equal(srv.consent[B], false, "B's consent changed");
    assert.deepEqual(srv.sentAs, [], 'a photo went out');
    assert.equal(t.picked.length, 0);
    assert.deepEqual(t.sheets, ['Scan with Claude?']);
    assert.equal(t.toasts.length, 0);
    assert.deepEqual(srv.unexpected, []);
  });
}

test("real SDK · A's token resolved, B signs in while fetchWithAuth resolves its own: the request still carries A's token", { skip }, async () => {
  const srv = server({ [B]: false });
  const t = await tab(srv, A);
  t.tapScan();
  const hold = t.storage.holdRead(2);                  // read 1: the golfer's token; read 2: the SDK's
  t.tapYes(); await settle();
  t.otherTabSignsIn(B);
  hold.resolve(); await settle();
  assert.deepEqual(srv.writes, [{ uid: A, on: true }], "setHeader did not survive the SDK's own token resolution");
  assert.equal(srv.consent[B], false);
  assert.deepEqual(srv.sentAs, [], "A's photo went out on B's token");
});

test("real SDK · A's revocation, B signs in while it resolves its token: B's yes stands", { skip }, async () => {
  const srv = server({ [A]: true, [B]: true });
  const t = await tab(srv, A);
  const hold = t.storage.holdRead(1);
  const answer = t.setConsent(false); await settle();
  t.otherTabSignsIn(B);
  hold.resolve();
  const result = await answer;
  assert.deepEqual(srv.writes.filter((w) => w.uid === B), [], "A's revocation went out as B");
  assert.equal(srv.consent[B], true);
  assert.equal(result, null);
});

test('real SDK · signed out in another tab while the write resolves: no request, no toast', { skip }, async () => {
  const srv = server();
  const t = await tab(srv, A);
  t.tapScan();
  const hold = t.storage.holdRead(1);
  t.tapYes(); await settle();
  t.otherTabSignsOut();
  hold.resolve(); await settle();
  assert.deepEqual(srv.writes, [], 'a request went out after sign-out');
  assert.equal(t.toasts.length, 0);
  assert.deepEqual(srv.sentAs, []);
});

test("real SDK · a token refresh while the write resolves: A's yes lands and the scan rides A's token", { skip }, async () => {
  const srv = server();
  const t = await tab(srv, A);
  t.tapScan();
  const hold = t.storage.holdRead(1);
  t.tapYes(); await settle();
  t.refreshed();
  hold.resolve(); await settle();
  assert.deepEqual(srv.writes, [{ uid: A, on: true }]);
  assert.deepEqual(srv.sentAs, [A]);
  assert.equal(srv.providerCalls, 1);
  assert.equal(t.picked.length, 1);
});

test("real SDK · an account switch while A's yes is in flight: it lands for A only, B's page takes nothing", { skip }, async () => {
  const srv = server({ [B]: false });
  srv.responseGate = deferred();
  const t = await tab(srv, A);
  t.tapScan();
  t.tapYes(); await settle();
  t.otherTabSignsIn(B, { reached: true, boot: true });
  srv.responseGate.resolve(); await settle();
  assert.deepEqual(srv.writes, [{ uid: A, on: true }]);
  assert.equal(srv.consent[B], false);
  assert.equal(t.CS.profile.scan_consent_at, null, "B's page took A's yes");
  assert.deepEqual(srv.sentAs, []);
  assert.equal(t.toasts.length, 0);
});

test('real SDK · normal scanning: the yes and the photo both carry the golfer\'s own token', { skip }, async () => {
  const srv = server();
  const t = await tab(srv, A);
  t.tapScan();
  t.tapYes(); await settle();
  assert.deepEqual(srv.writes, [{ uid: A, on: true }]);
  assert.deepEqual(srv.sentAs, [A]);
  assert.equal(t.picked.length, 1);
  assert.deepEqual(srv.unexpected, []);
});
