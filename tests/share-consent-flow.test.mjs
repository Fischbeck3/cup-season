// Exercise the actual web orchestration, including failed storage/RPC calls.
// Two servers: an OLDER database without the D385 lifecycle (the legacy D380 path, kept for
// deploy skew) and one with it (prepare_round_share / finish_round_share / round_share_status).
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const source = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const plan = source.slice(source.indexOf('function csShareConsentPlan('), source.indexOf('const CS_SHARE_PHOTO_INCLUDE'));
// the delivery helper, the lifecycle and csShareLink itself
const share = source.slice(source.indexOf('async function csDeliverLink('), source.indexOf('/* W2 (D380) · ONE Share'));
const revoke = source.slice(source.indexOf('async function csRevokeLink('), source.indexOf('/* ---- M2 / D17'));
const cleanup = source.slice(source.indexOf('async function csRemoveShareCopies('), source.indexOf('async function csWithdrawRoundLinks('));

const MISSING = {message: 'Could not find the function public.prepare_round_share in the schema cache', code: 'PGRST202'};
const isMissing = e => /schema cache|could not find the function|pgrst202/i.test(String((e && (e.code || '')) + ' ' + (e && e.message || '')));

function session({files = [], failList = false, failRemove = false, failRevoke = false, featureReady = true,
                  lifecycle = false, prep = {token: 'T', created: true, include_photo: false}, statusToken = null, cleanupPending = false,
                  shareThrows = null, noShare = false, clipboard = true} = {}) {
  const objects = new Set(files), sent = [], calls = [], messages = [], sheets = [], finished = [];
  let retired = false;
  const bucket = {
    list: async (_, {search}) => failList ? {error: new Error('list unavailable')} : {data: objects.has(search) ? [{name: search}] : []},
    remove: async names => { calls.push('remove'); if (failRemove) return {error: new Error('remove failed')}; names.forEach(x => objects.delete(x)); return {data: []}; },
    upload: async name => { calls.push('upload:' + name); objects.add(name); return {data: {path: name}}; },
  };
  const sb = {storage: {from: () => bucket}, from: () => ({select: () => ({eq: () => ({maybeSingle: async () => ({data: null})})})}),
    rpc: async (name, args) => {
    calls.push(name);
    if (!lifecycle && ['prepare_round_share', 'finish_round_share', 'round_share_status', 'confirm_share_cleanup', 'withdraw_round_shares'].includes(name)) return {error: MISSING};
    if (name === 'prepare_round_share') return {data: prep};
    if (name === 'finish_round_share') { finished.push(args.p_completed); return {data: {state: args.p_completed ? 'completed' : 'cancelled'}}; }
    if (name === 'round_share_status') return {data: {token: retired ? null : statusToken, cleanup_pending: cleanupPending && objects.size > 0}};
    if (name === 'withdraw_round_shares') {
      if (failRevoke) return {error: new Error('revoke failed')};
      retired = true; return {data: [...new Set([...objects].map(n => n.replace(/\.(jpg|png)$/, '')).concat(statusToken ? [statusToken] : []))]};
    }
    if (name === 'confirm_share_cleanup') return {data: {status: objects.size ? 'error' : 'completed'}};
    if (name === 'can_drop_share_copy') return {data: featureReady};
    if (name === 'revoke_share') {
      if (failRevoke) return {error: new Error('revoke failed')};
      retired = true; return {data: true};
    }
    return {data: retired ? 'fresh' : 'old'};
  }};
  const store = {};
  const nav = noShare ? {} : {share: async payload => { if (shareThrows) throw shareThrows; sent.push(payload); }};
  if (clipboard) nav.clipboard = {writeText: async () => {}};
  const context = vm.createContext({sb, window: {sb, compressPhoto: async b => b}, location: {origin: 'https://cupseason.app'},
    navigator: nav, console, crypto: {randomUUID: () => 'attempt-1'},
    localStorage: {getItem: k => store[k] ?? null, setItem: (k, v) => { store[k] = String(v); }},
    toast: text => messages.push(text), humanError: (_, prefix) => prefix, csMissingFn: isMissing,
    openSheet: (title) => sheets.push(title), esc: s => String(s), document: {getElementById: () => null},
    setTimeout: () => 0, URL, CS_SHARE_CLEANUP: {pending: 'still being removed'},
    growthEvent: () => {}, File});
  vm.runInContext(plan + share + revoke + cleanup, context);
  return {objects, sent, calls, messages, sheets, finished,
          share: (opts = {includePhoto: false}) => context.csShareLink('round', 'round', 'A round', null, opts),
          revoke: () => context.csRevokeLink('round', 'round'),
          refresh: button => context.csUpdateRoundLinkControl(button, 'round')};
}
const legacy = calls => calls.filter(c => c !== 'prepare_round_share' && c !== 'round_share_status' && c !== 'withdraw_round_shares');

// ── an OLDER database: the D380 path, unchanged after the one skew probe ──────────────
test('legacy · opt-out retires a photo-bearing PNG even when no JPEG exists', async () => {
  const s = session({files: ['old.png']});
  await s.share();
  assert.equal(s.objects.has('old.png'), false);
  assert.equal(s.sent[0].url, 'https://cupseason.app/?share=fresh');
  assert.equal(s.calls[0], 'prepare_round_share');
  assert.deepEqual(legacy(s.calls).slice(0, 5), ['create_share', 'can_drop_share_copy', 'remove', 'revoke_share', 'create_share']);
});

for (const failure of ['failList', 'failRemove', 'failRevoke']) {
  test(`legacy · ${failure} cannot share the old token after an opt-out`, async () => {
    const s = session({files: ['old.jpg', 'old.png'], [failure]: true});
    await s.share();
    assert.equal(s.sent.length, 0);
    assert.ok(s.messages.includes('Could not make the link.'));
  });
}

test('legacy · a fresh photo-less share keeps its token', async () => {
  const s = session(); await s.share();
  assert.equal(s.sent[0].url, 'https://cupseason.app/?share=old');
  assert.deepEqual(legacy(s.calls), ['create_share', 'can_drop_share_copy']);
});

test('legacy · explicit revoke deletes both public copies before retiring the token', async () => {
  const s = session({files: ['old.jpg', 'old.png']}); await s.revoke();
  assert.equal(s.objects.size, 0);
  assert.deepEqual(legacy(s.calls), ['create_share', 'can_drop_share_copy', 'remove', 'revoke_share']);
});

test('legacy · client deployed before PNG policy support cannot share an old token', async () => {
  const s = session({files: ['old.png'], featureReady: false}); await s.share();
  assert.equal(s.sent.length, 0);
  assert.deepEqual(legacy(s.calls), ['create_share', 'can_drop_share_copy']);
});

// ── the D385 lifecycle (prepare → copies only when created → deliver → finish) ────────
test('lifecycle · a completed share acknowledges completion; the copy is uploaded only for a new link', async () => {
  const blob = new Blob(['card']);
  const s = session({lifecycle: true});
  await s.share({includePhoto: false, cardBlob: blob});
  assert.equal(s.sent.length, 1);
  assert.equal(s.sent[0].text.endsWith('https://cupseason.app/?share=T') || s.sent[0].url === 'https://cupseason.app/?share=T', true);
  assert.ok(s.calls.includes('upload:T.png'));
  assert.deepEqual(s.finished, [true]);
  assert.ok(!s.calls.includes('create_share'));
});

test('lifecycle · a REUSED link uploads nothing (it keeps its original artifact)', async () => {
  const s = session({lifecycle: true, prep: {token: 'L', created: false, include_photo: false}});
  await s.share({includePhoto: false, cardBlob: new Blob(['card'])});
  assert.ok(!s.calls.some(c => c.startsWith('upload:')));
  assert.deepEqual(s.finished, [true]);
});

test('lifecycle · a cancelled sheet acknowledges NOT completed (the server retires only a new token)', async () => {
  const abort = Object.assign(new Error('cancelled'), {name: 'AbortError'});
  const s = session({lifecycle: true, shareThrows: abort});
  await s.share();
  assert.deepEqual(s.finished, [false]);
  assert.equal(s.messages.length, 0);
});

test('lifecycle · no share sheet and no clipboard: the link is SHOWN, never claimed as copied', async () => {
  const s = session({lifecycle: true, noShare: true, clipboard: false});
  await s.share();
  assert.deepEqual(s.sheets, ['Your round link']);
  assert.ok(!s.messages.some(m => /copied/i.test(m)));
  assert.deepEqual(s.finished, [true]);
});

test('lifecycle · a copy that succeeded is the only thing called "copied"', async () => {
  const s = session({lifecycle: true, noShare: true, clipboard: true});
  await s.share();
  assert.ok(s.messages.some(m => /^Link copied/.test(m)));
});

test('lifecycle · turning off a link never mints one first', async () => {
  const s = session({lifecycle: true, statusToken: null});
  await s.revoke();
  assert.ok(!s.calls.includes('create_share'));
  assert.deepEqual(s.messages, ['There is no live link to turn off.']);
});

test('lifecycle · turning off a live link revokes it and has the server confirm the copies are gone', async () => {
  const s = session({lifecycle: true, statusToken: 'L', files: ['L.jpg', 'L.png']});
  await s.revoke();
  assert.deepEqual(s.calls.filter(c => c !== 'remove'), ['withdraw_round_shares', 'confirm_share_cleanup']);
  assert.equal(s.objects.size, 0);
  assert.ok(s.messages[0].startsWith('Link is off'));
});

test('opting out clears a previous decoded image without mutating the source round', async () => {
  const rendered = [];
  const context = vm.createContext({window: {sb: {}}, state: {demo: false}, Blob,
    photoDrawable: async () => ({decoded: true}),
    drawRecapCard: data => { rendered.push(data); return {toBlob: done => done(new Blob(['card']))}; },
    csShareLink: async () => {}, csUpdateRoundLinkControl: async () => {}, document: {getElementById: () => null}, console, toast: () => {}});
  vm.runInContext(source.slice(source.indexOf('async function csShareRound('), source.indexOf('window.csShareRound =')), context);
  const original = {photo: 'owned-photo', _img: {oldDecodedImage: true}};
  await context.csShareRound(original, 'round', false, 'caption');
  assert.equal(rendered[0].photo, null);
  assert.equal(rendered[0]._img, null);
  assert.equal(original.photo, 'owned-photo');
  assert.equal(original._img.oldDecodedImage, true);
  await context.csShareRound(original, 'round', true, 'caption');
  assert.equal(rendered[1].photo, 'owned-photo');
  assert.equal(rendered[1]._img.decoded, true);
});


test('a receipt keeps cleanup retry visible after its live token is gone', async () => {
  const s=session({lifecycle:true,files:['old.jpg'],cleanupPending:true});
  const button={style:{display:'none'},textContent:''};
  await s.refresh(button);assert.equal(button.style.display,'');assert.equal(button.textContent,'Retry image cleanup');
  await s.revoke();await s.refresh(button);assert.equal(button.style.display,'none');assert.equal(s.objects.size,0);
});
test('failed withdrawal keeps the live link control available', async () => {
  const s=session({lifecycle:true,statusToken:'L',failRevoke:true});
  const button={style:{display:''},textContent:'Turn off this link'};
  await s.revoke();await s.refresh(button);assert.equal(button.style.display,'');assert.equal(button.textContent,'Turn off this link');
});
