// Exercise the actual web orchestration, including failed storage/RPC calls.
import {readFileSync} from 'node:fs';
import vm from 'node:vm';
import {test} from 'node:test';
import assert from 'node:assert/strict';

const source = readFileSync(new URL('../index.html', import.meta.url), 'utf8');
const plan = source.slice(source.indexOf('function csShareConsentPlan('), source.indexOf('const CS_SHARE_PHOTO_INCLUDE'));
const share = source.slice(source.indexOf('async function csShareLink('), source.indexOf('/* W2 (D380) · ONE Share'));
const revoke = source.slice(source.indexOf('async function csRevokeLink('), source.indexOf('/* ---- M2 / D17'));

function session({files = [], failList = false, failRemove = false, failRevoke = false, featureReady = true} = {}) {
  const objects = new Set(files), sent = [], calls = [], messages = [];
  let retired = false;
  const bucket = {
    list: async (_, {search}) => failList ? {error: new Error('list unavailable')} : {data: objects.has(search) ? [{name: search}] : []},
    remove: async names => { calls.push('remove'); if (failRemove) return {error: new Error('remove failed')}; names.forEach(x => objects.delete(x)); return {data: []}; },
    upload: async name => { calls.push('upload'); objects.add(name); return {data: {path: name}}; },
  };
  const sb = {storage: {from: () => bucket}, rpc: async name => {
    calls.push(name);
    if (name === 'can_drop_share_copy') return {data: featureReady};
    if (name === 'revoke_share') {
      if (failRevoke) return {error: new Error('revoke failed')};
      retired = true; return {data: true};
    }
    return {data: retired ? 'fresh' : 'old'};
  }};
  const context = vm.createContext({sb, window: {sb}, location: {origin: 'https://cupseason.app'},
    navigator: {share: async payload => sent.push(payload)}, console,
    toast: text => messages.push(text), humanError: (_, prefix) => prefix,
    growthEvent: () => {}, File});
  vm.runInContext(plan + share + revoke, context);
  return {objects, sent, calls, messages, share: () => context.csShareLink('round', 'round', 'A round', null, {includePhoto: false}), revoke: () => context.csRevokeLink('round', 'round')};
}

test('opt-out retires a photo-bearing PNG even when no JPEG exists', async () => {
  const s = session({files: ['old.png']});
  await s.share();
  assert.equal(s.objects.has('old.png'), false);
  assert.equal(s.sent[0].url, 'https://cupseason.app/?share=fresh');
  assert.deepEqual(s.calls.slice(0, 5), ['create_share', 'can_drop_share_copy', 'remove', 'revoke_share', 'create_share']);
});

for (const failure of ['failList', 'failRemove', 'failRevoke']) {
  test(`${failure} cannot share the old token after an opt-out`, async () => {
    const s = session({files: ['old.jpg', 'old.png'], [failure]: true});
    await s.share();
    assert.equal(s.sent.length, 0);
    assert.ok(s.messages.includes('Could not make the link.'));
  });
}

test('a fresh photo-less share keeps its token', async () => {
  const s = session(); await s.share();
  assert.equal(s.sent[0].url, 'https://cupseason.app/?share=old');
  assert.deepEqual(s.calls, ['create_share', 'can_drop_share_copy']);
});

test('explicit revoke deletes both public copies before retiring the token', async () => {
  const s = session({files: ['old.jpg', 'old.png']}); await s.revoke();
  assert.equal(s.objects.size, 0);
  assert.deepEqual(s.calls, ['create_share', 'can_drop_share_copy', 'remove', 'revoke_share']);
});

test('client deployed before PNG policy support cannot share an old token', async () => {
  const s = session({files: ['old.png'], featureReady: false}); await s.share();
  assert.equal(s.sent.length, 0);
  assert.deepEqual(s.calls, ['create_share', 'can_drop_share_copy']);
});

test('opting out clears a previous decoded image without mutating the source round', async () => {
  const rendered = [];
  const context = vm.createContext({window: {sb: {}}, state: {demo: false}, Blob,
    photoDrawable: async () => ({decoded: true}),
    drawRecapCard: data => { rendered.push(data); return {toBlob: done => done(new Blob(['card']))}; },
    csShareLink: async () => {}, console, toast: () => {}});
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
