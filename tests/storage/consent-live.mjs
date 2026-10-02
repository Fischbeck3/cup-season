// D403 (review of a3115801) · LIVE proof of the consent write's binding, against a real
// LOCAL Supabase stack (Auth issuing real JWTs, PostgREST running set_scan_consent) and
// the real supabase-js the web imports — never production. It refuses to run unless every
// URL is localhost / 127.0.0.1.
//   1 · a request bound with setHeader is applied to the token's golfer, whoever the
//       client's own session belongs to; unbound, the client's session decides (the race)
//   2 · index.html's own consent functions on that real client: B signing in while A's yes
//       resolves its token writes nothing for B; a switch after A's token is resolved still
//       lands A's yes on A
//
// Setup: as tests/storage/takedown-live.mjs, plus the SDK on disk (see
// tests/scan-consent-sdk.test.mjs):
//   CS_LOCAL_URL=… CS_LOCAL_ANON=… CS_LOCAL_SERVICE=… CS_LOCAL_DB_URL=… \
//   CS_SUPABASE_JS=<dir>/node_modules/@supabase/supabase-js node --test tests/storage/consent-live.mjs
// Users are created here with generated passwords that are never stored or printed.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID, randomBytes } from 'node:crypto';
import { execFileSync } from 'node:child_process';
import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { pathToFileURL } from 'node:url';
import vm from 'node:vm';

const URL_ = process.env.CS_LOCAL_URL ?? '';
const ANON = process.env.CS_LOCAL_ANON ?? '';
const SERVICE = process.env.CS_LOCAL_SERVICE ?? '';
const DB = process.env.CS_LOCAL_DB_URL ?? '';
const SDK = process.env.CS_SUPABASE_JS ?? '';
const PSQL = process.env.PSQL ?? 'psql';
const local = (u) => { try { return ['127.0.0.1', 'localhost'].includes(new URL(u).hostname); } catch { return false; } };
const ready = URL_ && ANON && SERVICE && DB && SDK && local(URL_) && local(DB.replace(/^postgres(ql)?:/, 'http:'));
const skip = ready ? false : 'needs a LOCAL stack and the SDK: CS_LOCAL_URL, CS_LOCAL_ANON, CS_LOCAL_SERVICE, CS_LOCAL_DB_URL, CS_SUPABASE_JS (localhost only)';
const sql = (q) => execFileSync(PSQL, [DB, '-X', '-A', '-t', '-v', 'ON_ERROR_STOP=1', '-c', q], { encoding: 'utf8' }).trim();
const consented = (who) => sql(`select scan_consent_at is not null from profiles where id = '${who.id}'`) === 't';

const source = readFileSync(process.env.CS_INDEX || new URL('../../index.html', import.meta.url), 'utf8');
const between = (a, b) => { const i = source.indexOf(a), j = source.indexOf(b, i); assert.ok(i >= 0 && j > i, `slice ${a}`); return source.slice(i, j); };
const consentCode = between('const CS_SCAN_CONSENT = {', '/* D376 ');
const runCode = between('async function csRunScan(f){', 'function scanPickRow(scan');
const settle = async () => { for (let i = 0; i < 80; i++) await new Promise((r) => setImmediate(r)); };
const deferred = () => { let resolve; const promise = new Promise((r) => { resolve = r; }); return { promise, resolve }; };
const KEY = 'sb-cs-live-auth-token';

async function golfer(tag) {
  const email = `${tag}.${randomUUID().slice(0, 8)}@example.invalid`;
  const password = randomBytes(18).toString('base64url');          // generated here, never stored
  const made = await fetch(URL_ + '/auth/v1/admin/users', { method: 'POST',
    headers: { apikey: SERVICE, authorization: 'Bearer ' + SERVICE, 'content-type': 'application/json' },
    body: JSON.stringify({ email, password, email_confirm: true }) });
  const user = await made.json();
  assert.equal(made.status, 200, 'create user');
  const signed = await fetch(URL_ + '/auth/v1/token?grant_type=password', { method: 'POST',
    headers: { apikey: ANON, 'content-type': 'application/json' }, body: JSON.stringify({ email, password }) });
  const session = await signed.json();
  assert.equal(signed.status, 200, 'sign in');
  return { id: user.id, token: session.access_token, session: JSON.stringify(session) };
}

async function client(storage) {
  const { createClient } = await import(pathToFileURL(join(SDK, 'dist/index.mjs')).href);
  const sb = createClient(URL_, ANON, { auth: { storage, storageKey: KEY, autoRefreshToken: false, persistSession: true, detectSessionInUrl: false } });
  await sb.auth.getSession();
  return sb;
}
function profileStorage(initial) {
  const map = new Map([[KEY, initial]]);
  let reads = 0; const holds = new Map();
  return { map, holdRead(n) { const d = deferred(); holds.set(reads + n, d); return d; },
    getItem: async (k) => { if (k === KEY) { const i = ++reads; const h = holds.get(i); if (h) await h.promise; } return map.get(k) ?? null; },
    setItem: async (k, v) => { map.set(k, v); }, removeItem: async (k) => { map.delete(k); } };
}
function page(sb, uid) {
  let buttons = {};
  const toasts = [], sheets = [];
  const win = { CS: { user: { id: uid }, profile: { id: uid, scan_consent_at: null } }, csAuthGen: 1, sb };
  const context = vm.createContext({
    window: win, state: { demo: false }, console, atob: (x) => Buffer.from(x, 'base64').toString('binary'),
    localStorage: { getItem: () => null, setItem: () => {}, removeItem: () => {} },
    toast: (t) => toasts.push(t), esc: (x) => String(x),
    openSheet: (t) => { sheets.push(t); buttons = {}; }, closeSheet: () => {},
    document: { getElementById: (id) => (id === 'scnYes' || id === 'scnNo') ? { addEventListener: (_, fn) => { buttons[id] = fn; } } : null },
    $: () => ({ innerHTML: '', disabled: false, textContent: '' }),
    compressPhoto: async (b) => b, b64ofBlob: async () => 'AAAA', refreshPostPhotoUI: () => {}, scanPickRow: () => {},
  });
  vm.runInContext(consentCode + runCode, context);
  return { toasts, sheets, win,
    ask: () => context.csAskScanConsent(() => {}),
    tapYes: () => buttons.scnYes() };
}

test('real stack · a bound request is applied to the token\'s golfer, whoever the client is signed in as', { skip }, async () => {
  const a = await golfer('consent-a'), b = await golfer('consent-b');
  const sb = await client(profileStorage(b.session));             // this client is signed in as B
  const bound = await sb.rpc('set_scan_consent', { p_on: true }).setHeader('Authorization', 'Bearer ' + a.token);
  assert.equal(bound.error, null);
  assert.equal(consented(a), true, "the bound request did not land on A");
  assert.equal(consented(b), false, "the bound request landed on B");
  // the race's root: unbound, the client's session at send time decides
  const unbound = await sb.rpc('set_scan_consent', { p_on: true });
  assert.equal(unbound.error, null);
  assert.equal(consented(b), true);
});

test("real stack · index.html's yes: B signs in while it resolves its token — nothing is written for B", { skip }, async () => {
  const a = await golfer('consent-a'), b = await golfer('consent-b');
  const storage = profileStorage(a.session);
  const p = page(await client(storage), a.id);
  p.ask();
  const hold = storage.holdRead(1);                                // the golfer's own token read
  p.tapYes(); await settle();
  storage.map.set(KEY, b.session);                                 // another tab signed in as B
  hold.resolve(); await settle();
  assert.equal(consented(b), false, "A's yes was written onto B");
  assert.equal(consented(a), false, 'a write went out after the account changed');
  assert.equal(p.toasts.length, 0);
});

test("real stack · index.html's yes: a switch after A's token is resolved still lands it on A only", { skip }, async () => {
  const a = await golfer('consent-a'), b = await golfer('consent-b');
  const storage = profileStorage(a.session);
  const p = page(await client(storage), a.id);
  p.ask();
  const hold = storage.holdRead(2);                                // the SDK's own read inside fetchWithAuth
  p.tapYes(); await settle();
  storage.map.set(KEY, b.session);
  hold.resolve(); await settle();
  assert.equal(consented(a), true, "A's yes did not land on A");
  assert.equal(consented(b), false, "A's yes landed on B");
});
