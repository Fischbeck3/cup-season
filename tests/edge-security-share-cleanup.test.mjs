// share-cleanup's second queue: a deleted account's photos (D395, contract §Account deletion).
// Run: node --experimental-strip-types --test tests/edge-security-share-cleanup.test.mjs
//
// The real handler runs in a vm (the tests/share-cleanup.test.mjs pattern) against a mock
// Storage that answers list() the way Storage does — files carry an id, folders do not —
// in pages, and a mock RPC layer whose report re-reads the mock bucket, like
// _media_cleanup_report re-reads storage.objects.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const source = stripTypeScriptTypes(readFileSync(new URL('../supabase/functions/share-cleanup/index.ts', import.meta.url), 'utf8')
  .replace("import { createClient } from 'npm:@supabase/supabase-js@2';", ''));
const A = '0b6f3a52-1c2d-4e5f-8a9b-0c1d2e3f4a5b', B = '9f8e7d6c-5b4a-4392-8170-6f5e4d3c2b1a', C = '11111111-2222-4333-8444-555555555555';

function worker({ objects = [], leagueObjects = {}, due = [], dueError = null, listFails = new Set(), removeFailsOnce = false,
                  takedowns = [], takedownDueError = null, moveFails = false, holdObjects = [] } = {}) {
  const media = new Set(objects);
  const hold = new Set(holdObjects);
  const leagueMedia = new Map(Object.entries(leagueObjects).flatMap(([owner, paths]) => paths.map((path) => [path, owner])));
  const log = { lists: [], batches: [], reports: [] };
  let removeFailed = false;
  const bucket = (name) => ({
    remove: async (paths) => {
      if (name === 'league-media') {
        const gone = paths.filter((p) => leagueMedia.delete(p));
        return { data: gone.map((p) => ({ name: p })), error: null };
      }
      if (name === 'moderation-hold') { const gone = paths.filter((p) => hold.delete(p)); return { data: gone.map((p) => ({ name: p })), error: null }; }
      if (name !== 'media') return { data: [], error: null };
      log.batches.push(paths.length);
      if (removeFailsOnce && !removeFailed) { removeFailed = true; return { data: null, error: { message: 'storage busy' } }; }
      const gone = paths.filter((p) => media.delete(p));
      return { data: gone.map((p) => ({ name: p })), error: null };
    },
    move: async (from, to, opts) => {
      log.moves = (log.moves ?? []).concat([{ name, from, to, dest: opts?.destinationBucket }]);
      if (moveFails) return { data: null, error: { message: 'move not supported' } };
      if (name !== 'media' || !media.has(from)) return { data: null, error: { message: 'Object not found' } };
      media.delete(from); hold.add(to);
      return { data: { message: 'Successfully moved' }, error: null };
    },
    list: async (prefix, { limit, offset }) => {
      log.lists.push(prefix);
      if ([...listFails].some((p) => prefix.startsWith(p))) return { data: null, error: { message: 'list refused' } };
      const kids = new Map();
      for (const o of media) {
        if (!o.startsWith(prefix + '/')) continue;
        const rest = o.slice(prefix.length + 1), cut = rest.indexOf('/');
        if (cut < 0) kids.set(rest, { name: rest, id: 'obj-' + rest, metadata: { size: 1 } });
        else kids.set(rest.slice(0, cut), { name: rest.slice(0, cut), id: null, metadata: null });
      }
      return { data: [...kids.values()].sort((x, y) => x.name.localeCompare(y.name)).slice(offset, offset + limit), error: null };
    },
  });
  const sb = {
    storage: { from: bucket },
    rpc: async (name, args) => {
      if (name === '_expire_share_attempts') return { error: null };
      if (name === '_share_cleanup_due') return { data: [] };
      if (name === '_media_cleanup_due') return dueError ? { data: null, error: { message: dueError } } : { data: due, error: null };
      if (name === '_takedown_cleanup_due') {
        if (takedownDueError) return { data: null, error: takedownDueError };
        return { data: takedowns.filter((t) => !t.done), error: null };
      }
      if (name === '_takedown_cleanup_report') {
        log.takedownReports = (log.takedownReports ?? []).concat([{ ...args }]);
        const t = takedowns.find((x) => x.id === args.p_id);
        // like the SQL: re-read storage itself
        if (args.p_phase === 'remove') {
          if (media.has(t.path)) return { data: 'error', error: null };
          t.done = true; t.kept = hold.has(t.hold_path); return { data: 'removed', error: null };
        }
        if (hold.has(t.hold_path)) return { data: 'error', error: null };
        t.done = true; return { data: 'purged', error: null };
      }
      if (name === '_league_media_cleanup_paths') {
        return { data: [...leagueMedia].filter(([, owner]) => owner === args.p_profile).map(([path]) => path), error: null };
      }
      if (name === '_media_cleanup_report') {
        log.reports.push({ ...args });
        const left = [...media].some((o) => o.startsWith(args.p_profile + '/')) ||
          [...leagueMedia.values()].includes(args.p_profile);
        return { data: left ? 'error' : 'completed', error: null };
      }
      throw Error(name);
    },
  };
  let handler;
  vm.runInNewContext(source, { createClient: () => sb, Response, console: { log: () => {} },
    Deno: { env: { get: (k) => (k === 'SHARE_CLEANUP_SECRET' ? 'test-secret' : 'local') }, serve: (fn) => { handler = fn; } } });
  const run = () => handler(new Request('http://localhost/cleanup', { method: 'POST', headers: { 'x-cleanup-secret': 'test-secret' } }));
  return { run, media, leagueMedia, log, hold, takedowns };
}
const range = (n, f) => Array.from({ length: n }, (_, i) => f(i));

test('account deletion reclaims that uploader’s league images alongside their personal photos', async () => {
  const league = '22222222-3333-4444-8555-666666666666';
  const mine = [league + '/mine.png', league + '/retired.jpg'], theirs = league + '/another-pro.png';
  const w = worker({ objects: [A + '/avatar.jpg', B + '/avatar.jpg'],
    leagueObjects: { [A]: mine, [B]: [theirs] }, due: [A] });
  const j = await (await w.run()).json();
  assert.deepEqual([...w.media], [B + '/avatar.jpg']);
  assert.deepEqual([...w.leagueMedia.keys()], [theirs]);
  assert.equal(j.media.objects_removed, 3);
  assert.equal(j.media.completed, 1);
});

test('a deleted account loses every photo, nested folders and all, in batches of at most 100', async () => {
  const mine = [...range(250, (i) => `${A}/p${String(i).padStart(3, '0')}.jpg`), `${A}/avatar.jpg`,
    ...range(30, (i) => `${A}/rounds/2026/r${i}.jpg`), ...range(5, (i) => `${A}/rounds/2026/deep/d${i}.jpg`)];
  const theirs = [`${B}/avatar.jpg`, `${B}/p1.jpg`, `${A}x/not-a-child.jpg`];
  const w = worker({ objects: [...mine, ...theirs], due: [A] });
  const r = await w.run();
  assert.equal(r.status, 200);
  const j = await r.json();
  assert.deepEqual([...w.media].sort(), theirs.sort(), 'only that account, and all of it');
  assert.ok(w.log.batches.every((n) => n <= 100), `batches ${w.log.batches}`);
  assert.deepEqual(w.log.reports, [{ p_profile: A, p_error: null }]);
  assert.equal(j.media.processed, 1); assert.equal(j.media.completed, 1); assert.equal(j.media.objects_removed, mine.length);
  assert.equal(j.media.results[0].found, mine.length);
  assert.ok(w.log.lists.filter((p) => p === A).length >= 3, 'the root folder was paged (251 entries)');
});

test('folders nested past the depth cap stay, and the report says why instead of completed', async () => {
  const w = worker({ objects: [`${A}/a.jpg`, `${A}/l2/l3/l4/ok.jpg`, `${A}/l2/l3/l4/l5/too-deep.jpg`], due: [A] });
  const j = await (await w.run()).json();
  assert.deepEqual([...w.media], [`${A}/l2/l3/l4/l5/too-deep.jpg`]);
  assert.equal(j.media.results[0].status, 'error');
  assert.match(w.log.reports[0].p_error, /listing incomplete: folders nested deeper than 4/);
});

test('one run is bounded (5,000 entries); the rest waits for the backoff, and the run never claims completion', async () => {
  const w = worker({ objects: range(5100, (i) => `${A}/p${String(i).padStart(4, '0')}.jpg`), due: [A] });
  const j = await (await w.run()).json();
  assert.equal(j.media.objects_removed, 5000);
  assert.equal(w.media.size, 100);
  assert.equal(j.media.results[0].status, 'error');
  assert.match(w.log.reports[0].p_error, /listing incomplete: more than 5000 entries/);
});

test('one profile failing never stops the next, and each reports on its own', async () => {
  const w = worker({ objects: [`${A}/a.jpg`, `${B}/b.jpg`], due: [A, B], listFails: new Set([A]) });
  const j = await (await w.run()).json();
  assert.deepEqual(w.log.reports.map((x) => x.p_profile), [A, B]);
  assert.match(w.log.reports[0].p_error, /Storage API unreachable: list .*list refused/);
  assert.equal(w.log.reports[1].p_error, null);
  assert.deepEqual([...w.media], [`${A}/a.jpg`]);
  assert.equal(j.media.completed, 1); assert.equal(j.media.failed, 1);
});

test('a failed batch is reported and the other batches still go', async () => {
  const w = worker({ objects: range(150, (i) => `${C}/p${i}.jpg`), due: [C], removeFailsOnce: true });
  const j = await (await w.run()).json();
  assert.deepEqual(w.log.batches, [100, 50]);
  assert.equal(w.media.size, 100, 'the second batch went');
  assert.match(w.log.reports[0].p_error, /Storage API: storage busy/);
  assert.equal(j.media.results[0].status, 'error');
});

test('an id that is not a uuid is refused before Storage is asked — an empty prefix is the whole bucket', async () => {
  const w = worker({ objects: [`${A}/a.jpg`], due: ['', '../x', `${A}/..`] });
  const j = await (await w.run()).json();
  assert.deepEqual(w.log.lists, []);
  assert.deepEqual(w.log.reports, []);
  assert.equal(w.media.size, 1);
  assert.ok(j.media.results.every((x) => x.status === 'refused'));
});

test('an unreadable media queue is a 500 that still carries the share half, never an empty queue', async () => {
  const w = worker({ dueError: 'function public._media_cleanup_due(integer) does not exist' });
  const r = await w.run();
  assert.equal(r.status, 500);
  const j = await r.json();
  assert.equal(j.processed, 0);
  assert.equal(j.media.error, 'queue_unreadable');
  assert.match(j.media.detail, /does not exist/);
});

// ---- D403 · a taken-down photo's file (mocked Storage: NOT live proof — see
// tests/storage/takedown-live.mjs for the real Storage run) ------------------------------
const T1 = 'aaaaaaaa-0000-4000-8000-000000000001';
test('a takedown moves the file out of media into the private hold, and the server confirms it', async () => {
  const path = `${A}/round-1.jpg`;
  const w = worker({ objects: [path, `${A}/avatar.jpg`],
    takedowns: [{ id: T1, phase: 'remove', bucket: 'media', path, hold_path: `${T1}/${path}` }] });
  const j = await (await w.run()).json();
  assert.deepEqual(w.log.moves, [{ name: 'media', from: path, to: `${T1}/${path}`, dest: 'moderation-hold' }]);
  assert.ok(!w.media.has(path) && w.media.has(`${A}/avatar.jpg`));
  assert.ok(w.hold.has(`${T1}/${path}`));
  assert.equal(j.takedowns.removed, 1);
});

test('a failed move still removes the published file — removal beats retention — and says the evidence was not kept', async () => {
  const path = `${A}/round-2.jpg`;
  const w = worker({ objects: [path], moveFails: true,
    takedowns: [{ id: T1, phase: 'remove', bucket: 'media', path, hold_path: `${T1}/${path}` }] });
  const j = await (await w.run()).json();
  assert.ok(!w.media.has(path));
  assert.match(w.log.takedownReports[0].p_error, /move to moderation-hold: move not supported/);
  assert.equal(j.takedowns.results[0].status, 'removed');
});

test('a file Storage would not remove is reported for retry, never as removed', async () => {
  const path = `${A}/round-3.jpg`;
  const w = worker({ objects: [path], moveFails: true, removeFailsOnce: true,
    takedowns: [{ id: T1, phase: 'remove', bucket: 'media', path, hold_path: `${T1}/${path}` }] });
  const j = await (await w.run()).json();
  assert.ok(w.media.has(path));
  assert.equal(j.takedowns.results[0].status, 'error');
  assert.equal(j.takedowns.failed, 1);
});

test('only media paths are touched; a queue row for another bucket is refused before Storage', async () => {
  const w = worker({ objects: [`${A}/x.jpg`],
    takedowns: [{ id: T1, phase: 'remove', bucket: 'shared', path: 'tok.jpg', hold_path: `${T1}/tok.jpg` }] });
  const j = await (await w.run()).json();
  assert.equal(w.log.moves, undefined);
  assert.match(j.takedowns.results[0].error, /not a media path/);
});

test('kept evidence is purged from the hold when due, and confirmed', async () => {
  const w = worker({ holdObjects: [`${T1}/${A}/r.jpg`],
    takedowns: [{ id: T1, phase: 'purge', bucket: 'media', path: `${A}/r.jpg`, hold_path: `${T1}/${A}/r.jpg` }] });
  const j = await (await w.run()).json();
  assert.equal(w.hold.size, 0);
  assert.equal(j.takedowns.purged, 1);
});

test('the takedown queue not deployed yet is named, not an outage; an unreadable one is a 500', async () => {
  const skew = worker({ takedownDueError: { code: 'PGRST202', message: 'Could not find the function public._takedown_cleanup_due' } });
  const r1 = await skew.run();
  assert.equal(r1.status, 200);
  assert.equal((await r1.json()).takedowns.skipped, 'takedown queue not deployed');
  const down = worker({ takedownDueError: { message: 'permission denied' } });
  const r2 = await down.run();
  assert.equal(r2.status, 500);
  assert.equal((await r2.json()).takedowns.error, 'queue_unreadable');
});
