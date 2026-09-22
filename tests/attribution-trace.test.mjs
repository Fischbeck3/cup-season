// W6 correction 6 — the attribution writer that ALREADY exists, traced on the
// web client and read statically on the phone. The server half (the RPC and the
// profile readback, in a disposable sandbox) is in tests/pilot/scorecard-db.test.mjs.
//
// The web path, in order:
//   1. intent persistence — `?claim=` / `?join=` are written to localStorage
//      (cs_claim / cs_code) at load, before any auth;
//   2. authentication — OTP, then a clean reload into boot();
//   3. the golfer-card gate returns BEFORE boot consumes cs_code, and
//      claimPendingRound refuses to run without a marker, so both intents are
//      still pending when the card is saved;
//   4. card completion emits profile_created with the pending intent — a claim
//      wins over a join, and neither means direct (kind null);
//   5. growthEvent sends exactly log_growth_event(p_node, p_kind, p_token, …).
// The functions below are extracted from index.html and run as written.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const html = readFileSync(join(root, 'index.html'), 'utf8');
const grab = (re, what) => { const m = html.match(re); assert.ok(m, `${what} not found in index.html`); return m[0]; };

const growthEventSrc = grab(/function growthEvent\(node, kind, token, props, league\)\{[\s\S]*?\n\}\nwindow\.growthEvent = growthEvent;/, 'growthEvent');
const emitSrc = grab(/\{ let via='direct', tok=null;[\s\S]*?window\.growthEvent\?\.\('profile_created'[^\n]*\}/, 'the card-save emit');

/** Save the card with these pending intents; return the RPC calls the page made. */
function saveCard(pending) {
  const calls = [];
  const store = new Map(Object.entries(pending));
  const window = { sb: { rpc: (name, args) => { calls.push({ name, args }); return Promise.resolve({ data: null, error: null }); } } };
  const ctx = vm.createContext({ window, localStorage: { getItem: k => (store.has(k) ? store.get(k) : null) } });
  vm.runInContext(growthEventSrc, ctx);
  vm.runInContext(emitSrc, ctx);
  return JSON.parse(JSON.stringify(calls));   // out of the vm's realm, so deepEqual compares values
}

test('a pending claim is sent as the claim, with its token', () => {
  assert.deepEqual(saveCard({ cs_claim: '00000000-0000-4000-a000-000000000002' }), [{ name: 'log_growth_event',
    args: { p_node: 'profile_created', p_kind: 'claim', p_token: '00000000-0000-4000-a000-000000000002', p_props: { via: 'claim' }, p_league: null } }]);
});

test('a pending join is sent as the join, with its code', () => {
  assert.deepEqual(saveCard({ cs_code: 'SYNTH1' })[0].args, { p_node: 'profile_created', p_kind: 'join', p_token: 'SYNTH1', p_props: { via: 'join' }, p_league: null });
});

test('a claim wins over a join, as on the phone', () => {
  const [c] = saveCard({ cs_claim: '00000000-0000-4000-a000-000000000002', cs_code: 'SYNTH1' });
  assert.equal(c.args.p_kind, 'claim');
});

test('a direct arrival sends no kind and no token — nothing to attribute', () => {
  assert.deepEqual(saveCard({})[0].args, { p_node: 'profile_created', p_kind: null, p_token: null, p_props: { via: 'direct' }, p_league: null });
});

test('the intents are still pending when the card is saved', () => {
  // 1 · captured at load, before auth
  assert.match(html, /const claimParam = new URLSearchParams\(window\.location\.search\)\.get\('claim'\);\nif\(claimParam\)\{\n  try\{ localStorage\.setItem\('cs_claim', claimParam\.trim\(\)\); \}catch\(_\)\{\}/);
  assert.match(html, /if\(joinParam\)\{\n  const jc = joinParam\.trim\(\)\.toUpperCase\(\);\n  try \{ localStorage\.setItem\('cs_code', jc\); \} catch\(_\)\{\}/);
  // 3 · boot(): the card gate returns before the first read-and-remove of cs_code
  const boot = grab(/async function boot\(\)\{[\s\S]*?\n\}\n/, 'boot()');
  const gate = boot.indexOf('showProfileGate();\n      return;');
  const consume = boot.indexOf("localStorage.getItem('cs_code')");
  assert.ok(gate > 0 && consume > gate, 'the profile gate must return before boot reads cs_code');
  // claimPendingRound does nothing until the card exists
  assert.match(html, /async function claimPendingRound\(\)\{\n  let tok=null; try\{ tok=localStorage\.getItem\('cs_claim'\); \}catch\(_\)\{\}\n  if\(!tok \|\| !CS\.user \|\| !CS\.profile\?\.marker\) return;/);
  // 4 · the card save emits BEFORE it continues into resumeAfterProfile (which spends both intents)
  const save = html.indexOf(emitSrc);
  const cont = html.indexOf('await continueAfterCard();', save);
  assert.ok(save > 0 && cont > save && cont - save < 800, 'the emit precedes continueAfterCard in the same handler');
});

test('the phone sends the same three shapes from the same moment (read, not run: native work runs locally)', () => {
  const growth = readFileSync(join(root, 'apps/ios/Packages/CupSeasonKit/Sources/CupSeasonKit/Growth.swift'), 'utf8');
  const gate = readFileSync(join(root, 'apps/ios/CupSeason/Onboarding/CardGateView.swift'), 'utf8');
  assert.match(gate, /Rpc\.set_profile\([^\n]*\n[\s\S]{0,300}CSGrowth\.profileCreated\(\)/);
  assert.match(growth, /if let claim = ClaimIntent\.pending\(\) \{\n\s+log\(\.profileCreated, kind: "claim", token: claim\.uuidString\.lowercased\(\)/);
  assert.match(growth, /\} else if let join = JoinIntent\.pending\(\) \{\n\s+log\(\.profileCreated, kind: "join", token: join\.code/);
  assert.match(growth, /\} else \{\n\s+log\(\.profileCreated, props: \["via": \.string\("direct"\)\]\)/);
  // a DEBUG build never logs: a device trace must use a Release/TestFlight build
  assert.match(growth, /#if DEBUG\n\s+return\n\s+#endif/);
});

test('there is exactly one writer of profiles.came_via_*', () => {
  const dir = join(root, 'supabase', 'migrations');
  const writers = readdirSync(dir).filter(f => /set\s+came_via_kind\s*=/i.test(readFileSync(join(dir, f), 'utf8')));
  assert.deepEqual(writers, ['20260828160000_growth_events.sql']);
});
