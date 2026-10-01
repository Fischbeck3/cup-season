// D403 (corrected 2026-10-01) · the web's scan-consent recovery, run as the real
// index.html functions against a shared stand-in for the server. The server's "no"
// is authoritative: a refusal for consent clears what the page believed and asks;
// the page writes a yes only for a tap on the sheet, for the account that tapped,
// and retries one scan on it at most once. The Edge side (zero provider calls
// without a stored yes) is proven separately in edge-security-courses-scan.test.mjs;
// here "provider calls" counts what the stand-in Edge would have sent to Anthropic.
//
// CS_INDEX=<path> runs the same scenarios against another build of index.html
// (used to show the regression fails on b3472292).
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const source = readFileSync(process.env.CS_INDEX || new URL('../index.html', import.meta.url), 'utf8');
const between = (a, b) => {
  const i = source.indexOf(a), j = source.indexOf(b, i);
  assert.ok(i >= 0 && j > i, `slice ${a}`);
  return source.slice(i, j);
};
const consentCode = between('const CS_SCAN_CONSENT = {', '/* D376 ');
const runCode = between('async function csRunScan(f){', 'function scanPickRow(scan){');

const settle = async () => { for (let i = 0; i < 30; i++) await new Promise(r => setImmediate(r)); };

/* One server, shared by every tab and device. consent: uid → bool. */
function makeServer({consent = {}, readFails = false} = {}) {
  return {consent: {...consent}, readFails, writes: [], scanCalls: 0, providerCalls: 0};
}

/* One signed-in tab. Its profile is whatever the server held when it loaded. */
function tab(server, uid, {deviceFlag = false, writeGate = null} = {}) {
  const store = deviceFlag ? {cs_scan_consent: '1'} : {};
  const toasts = [], sheets = [], picked = [];
  let buttons = {};
  const CS = {user: {id: uid}, profile: {id: uid, scan_consent_at: server.consent[uid] ? '2026-09-30T12:00:00Z' : null}};
  const sb = {
    rpc: async (name, args) => {
      assert.equal(name, 'set_scan_consent');
      const who = CS.user?.id;                       // the JWT at the moment of the call
      if (writeGate) await writeGate.promise;
      server.writes.push({uid: who, on: args.p_on});
      if (writeGate?.fail) return {error: {message: 'network'}};
      server.consent[who] = args.p_on;
      return {data: args.p_on};
    },
    functions: {invoke: async name => {
      assert.equal(name, 'scan');
      server.scanCalls++;
      const who = CS.user?.id;
      if (server.readFails || !server.consent[who]) {
        return {error: {context: {json: async () => ({unavailable: true, reason: 'no_consent'})}}};
      }
      server.providerCalls++;
      return {data: {ok: true, scan: {players: [{name: 'Me', holes: Array(18).fill(4)}], par_row: Array(18).fill(4)}}};
    }},
  };
  const btn = {innerHTML: 'Scan', disabled: false, textContent: ''};
  const context = vm.createContext({
    window: {CS, sb}, state: {demo: false}, console,
    localStorage: {getItem: k => store[k] ?? null, setItem: (k, v) => { store[k] = String(v); }, removeItem: k => { delete store[k]; }},
    toast: t => toasts.push(t), esc: s => String(s),
    openSheet: title => { sheets.push(title); buttons = {}; },
    closeSheet: () => {},
    document: {getElementById: id => {
      if (id !== 'scnYes' && id !== 'scnNo') return null;
      return {addEventListener: (_, fn) => { buttons[id] = fn; }};
    }},
    $: sel => sel === '#postScanBtn' ? btn : null,
    compressPhoto: async b => b, b64ofBlob: async () => 'AAAA',
    refreshPostPhotoUI: () => {}, scanPickRow: scan => picked.push(scan),
  });
  vm.runInContext(consentCode + runCode, context);
  return {
    CS, store, toasts, sheets, picked,
    consented: () => context.csScanConsented(),
    setConsent: on => context.csSetScanConsent(on),
    scan: () => context.csRunScan({name: 'card.jpg'}),
    /* the composer's scan button: ask first unless the page believes it holds a yes */
    tapScan: async () => { if (context.csScanConsented()) await context.csRunScan({name: 'card.jpg'}); else context.csAskScanConsent(() => context.csRunScan({name: 'card.jpg'})); },
    tapYes: async () => { assert.ok(buttons.scnYes, 'the consent sheet is open'); buttons.scnYes(); await settle(); },
    tapNo: async () => { assert.ok(buttons.scnNo, 'the consent sheet is open'); buttons.scnNo(); await settle(); },
  };
}

const A = '00000000-0000-0000-0000-00000000000a';
const B = '00000000-0000-0000-0000-00000000000b';
const NOT_SAVED = 'Your yes to scanning didn’t save — type your nines in, or try the scan again.';

test('regression: grant in A, load B, revoke in A, scan in B — B writes nothing and nothing reaches Anthropic until the golfer says yes again', async () => {
  const server = makeServer();
  const a = tab(server, A);
  await a.tapScan(); await a.tapYes();              // the golfer grants in session A
  assert.equal(server.consent[A], true);
  const b = tab(server, A);                          // a second tab/device loads with the yes
  assert.equal(b.consented(), true);
  assert.equal(await a.setConsent(false), true);     // revoked in A (Settings)
  const writesBefore = server.writes.length, providerBefore = server.providerCalls;

  await b.scan();                                    // B still believes the stale yes
  assert.equal(server.writes.length, writesBefore, 'B wrote no consent on its own');
  assert.equal(server.providerCalls, providerBefore, 'no provider call');
  assert.equal(server.consent[A], false, 'the revocation stands');
  assert.deepEqual(b.sheets, ['Scan with Claude?'], 'B asks explicitly');
  assert.equal(b.consented(), false, 'the stale yes is gone from B');

  await b.tapYes();                                  // only now, a fresh affirmative choice
  assert.deepEqual(server.writes.slice(writesBefore), [{uid: A, on: true}]);
  assert.equal(server.providerCalls, providerBefore + 1);
  assert.equal(b.picked.length, 1);
});

test('a declined re-ask sends and writes nothing', async () => {
  const server = makeServer({consent: {[A]: true}});
  const b = tab(server, A);
  server.consent[A] = false;                         // revoked elsewhere
  await b.scan();
  await b.tapNo();
  assert.equal(server.writes.length, 0);
  assert.equal(server.providerCalls, 0);
  assert.equal(server.scanCalls, 1);
  assert.equal(b.toasts.at(-1), 'Nothing was sent — type your nines in');
});

test('an unreadable consent (the server refuses on a read error) never creates a yes and never loops', async () => {
  const server = makeServer({consent: {[A]: true}, readFails: true});
  const b = tab(server, A);
  await b.scan();                                    // refused: stale yes cleared, asked
  assert.equal(server.writes.length, 0);
  await b.tapYes();                                  // fresh yes written, one retry, still refused
  assert.equal(server.writes.length, 1);
  assert.equal(server.scanCalls, 2, 'one retry at most');
  assert.equal(server.providerCalls, 0);
  assert.equal(b.sheets.length, 1, 'asked once, not in a loop');
  assert.equal(b.toasts.at(-1), NOT_SAVED);
});

test('a device-only flag from an older build is not consent', async () => {
  const server = makeServer();
  const b = tab(server, A, {deviceFlag: true});
  assert.equal(b.consented(), false);
  await b.tapScan();
  assert.equal(server.scanCalls, 0, 'asked before anything is sent');
  assert.deepEqual(b.sheets, ['Scan with Claude?']);
});

test('a yes whose write fails sends nothing and keeps nothing on the device', async () => {
  const server = makeServer();
  const gate = {promise: Promise.resolve(), fail: true};
  const b = tab(server, A, {writeGate: gate});
  await b.tapScan(); await b.tapYes();
  assert.equal(server.scanCalls, 0);
  assert.equal(b.toasts.at(-1), NOT_SAVED);
  assert.equal(b.store.cs_scan_consent, undefined);
  assert.equal(b.consented(), false);
});

test('a pending yes is awaited: nothing is sent before the write lands', async () => {
  const server = makeServer();
  let release; const gate = {promise: new Promise(r => { release = r; })};
  const b = tab(server, A, {writeGate: gate});
  await b.tapScan(); await b.tapYes();
  assert.equal(server.scanCalls, 0, 'waiting on the write');
  release(); await settle();
  assert.equal(server.scanCalls, 1);
  assert.equal(server.providerCalls, 1);
});

test('account switch: a yes tapped for one golfer is never used for the next', async () => {
  const server = makeServer();
  let release; const gate = {promise: new Promise(r => { release = r; })};
  const t = tab(server, A, {writeGate: gate});
  await t.tapScan();
  t.tapYes();                                        // A taps yes; the write is still in flight
  t.CS.user = {id: B}; t.CS.profile = {id: B, scan_consent_at: null};   // signed out, B signs in
  assert.equal(t.consented(), false, "A's yes does not count for B");
  release(); await settle();                         // A's own scan stops: the account changed
  assert.equal(server.providerCalls, 0);
  assert.equal(server.consent[B], undefined, 'nothing written for B');
  await t.scan();                                    // B scans: refused, asked, nothing written
  assert.equal(server.consent[B], undefined);
  assert.equal(server.providerCalls, 0);
  assert.equal(t.sheets.at(-1), 'Scan with Claude?');
});

test('Settings off clears a fresh yes and a stale profile yes alike', async () => {
  const server = makeServer({consent: {[A]: true}});
  const b = tab(server, A);
  assert.equal(await b.setConsent(false), true);
  assert.equal(b.consented(), false);
  await b.tapScan();
  assert.equal(server.scanCalls, 0);
});
