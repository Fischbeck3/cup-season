// D403 · share-cleanup's takedown queue: only the taken-down object is ever moved or deleted.
// Run: node --experimental-strip-types --test tests/edge-security-takedown-cleanup.test.mjs
//
// The real handler runs in a vm against a model of Storage that behaves as Storage does —
// move and remove act on WHATEVER is at a path, a move onto an existing destination fails —
// and a model of the SQL queue: rows are claimed (an overlapping run never gets one), the
// claim says whether the taken-down version is still stored, and the report re-reads the
// model storage and refuses a stale claim. MOCKED STORAGE: this is not live proof; the
// real-Storage run is tests/storage/takedown-live.mjs.
//
// CS_WORKER=<path> runs the same scenarios against another build of the worker (the review's
// reproduction: on 0e463792 a retry after a failed report deletes a replacement photo).
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';

const source = stripTypeScriptTypes(readFileSync(process.env.CS_WORKER || new URL('../supabase/functions/share-cleanup/index.ts', import.meta.url), 'utf8')
  .replace("import { createClient } from 'npm:@supabase/supabase-js@2';", ''));
const A = '0b6f3a52-1c2d-4e5f-8a9b-0c1d2e3f4a5b', B = '9f8e7d6c-5b4a-4392-8170-6f5e4d3c2b1a';
const T1 = 'aaaaaaaa-0000-4000-8000-000000000001', T2 = 'aaaaaaaa-0000-4000-8000-000000000002';
const tick = () => new Promise((r) => setImmediate(r));

/* One storage + one queue, shared by every run of the handler (so runs can overlap). */
function world({ media = {}, hold = [], takedowns = [], moveFails = false, reportFailsOnce = false, accountDue = [] } = {}) {
  // media: path -> { v: version time, tag }   (a replacement has a later v)
  const store = { media: new Map(Object.entries(media)), hold: new Map(hold.map((p) => [p, { v: 0, tag: 'pre-existing' }])) };
  const rows = takedowns.map((t) => ({ status: 'pending', keep: true, taken_at: 1, claim: null, owner: A, ...t }));
  const log = { moves: [], removes: [], reports: [] };
  let claims = 0, reportFailed = false;
  const bucket = (name) => ({
    move: async (from, to, opts) => {
      await tick();
      log.moves.push({ from, to, dest: opts?.destinationBucket });
      if (moveFails) return { data: null, error: { message: 'move not supported' } };
      if (name !== 'media' || !store.media.has(from)) return { data: null, error: { message: 'Object not found' } };
      if (store.hold.has(to)) return { data: null, error: { message: 'The resource already exists' } };
      store.hold.set(to, store.media.get(from)); store.media.delete(from);
      return { data: { message: 'Successfully moved' }, error: null };
    },
    remove: async (paths) => {
      await tick();
      log.removes.push({ bucket: name, paths });
      const m = name === 'moderation-hold' ? store.hold : store.media;
      const gone = paths.filter((p) => m.delete(p));
      return { data: gone.map((p) => ({ name: p })), error: null };
    },
    list: async () => ({ data: [], error: null }),
  });
  const takenVersionStored = (r) => store.media.has(r.path) && store.media.get(r.path).v <= r.taken_at;
  const sb = {
    storage: { from: bucket },
    rpc: async (name, args) => {
      if (name === '_expire_share_attempts') return { error: null };
      if (name === '_share_cleanup_due') return { data: [] };
      if (name === '_media_cleanup_due') return { data: accountDue, error: null };
      if (name === '_league_media_cleanup_paths') return { data: [], error: null };
      if (name === '_held_media_cleanup_paths') {
        const mine = rows.filter((r) => r.owner === args.p_profile && r.hold_path && store.hold.has(r.hold_path)).map((r) => r.hold_path);
        return { data: mine, error: null };
      }
      if (name === '_media_cleanup_report') {
        const left = rows.some((r) => r.owner === args.p_profile && r.hold_path && store.hold.has(r.hold_path));
        return { data: left ? 'error' : 'completed', error: null };
      }
      if (name === '_takedown_cleanup_due') {
        const out = [];
        for (const r of rows) {
          if (r.claim) continue;                                   // claimed by another run (lease live)
          const remove = r.status === 'pending' || r.status === 'error';
          const purge = r.status === 'removed' && r.hold_path && (r.purgeDue || !r.keep);
          if (!remove && !purge) continue;
          r.claim = 'claim-' + (++claims);
          out.push({ id: r.id, claim: r.claim, phase: remove ? 'remove' : 'purge', bucket: 'media', path: r.path,
                     hold_path: r.hold_path, present: takenVersionStored(r), keep: r.keep });
        }
        return { data: out, error: null };
      }
      if (name === '_takedown_cleanup_report') {
        log.reports.push({ ...args });
        if (reportFailsOnce && !reportFailed) { reportFailed = true; return { data: null, error: { message: 'connection reset' } }; }
        const r = rows.find((x) => x.id === args.p_id);
        if (!args.p_claim || args.p_claim !== r.claim) return { data: 'stale', error: null };
        r.claim = null;
        if ((args.p_phase ?? 'remove') === 'remove') {
          if (takenVersionStored(r)) { r.status = 'error'; return { data: 'error', error: null }; }
          r.status = 'removed';
          if (!store.hold.has(r.hold_path)) r.hold_path = null;
          return { data: 'removed', error: null };
        }
        if (store.hold.has(r.hold_path)) return { data: 'error', error: null };
        r.status = 'purged'; return { data: 'purged', error: null };
      }
      throw Error(name);
    },
  };
  let handler;
  vm.runInNewContext(source, { createClient: () => sb, Response, console: { log: () => {} },
    Deno: { env: { get: (k) => (k === 'SHARE_CLEANUP_SECRET' ? 'test-secret' : 'local') }, serve: (fn) => { handler = fn; } } });
  const run = async () => (await handler(new Request('http://localhost/cleanup', { method: 'POST', headers: { 'x-cleanup-secret': 'test-secret' } }))).json();
  /* a lease that ran out: the next run may claim the row again */
  const expireLeases = () => rows.forEach((r) => { r.claim = null; });
  return { run, store, rows, log, expireLeases };
}
const avatar = `${A}/avatar.jpg`;
const hold1 = `${T1}/${avatar}`;

test('normal removal: the taken-down file moves into the private hold, confirmed', async () => {
  const w = world({ media: { [avatar]: { v: 1, tag: 'original' } }, takedowns: [{ id: T1, path: avatar, hold_path: hold1 }] });
  const j = await w.run();
  assert.equal(j.takedowns.removed, 1);
  assert.ok(!w.store.media.has(avatar));
  assert.equal(w.store.hold.get(hold1).tag, 'original');
});

test('failed move: the published original is still removed, and the evidence says it was not kept', async () => {
  const w = world({ media: { [avatar]: { v: 1, tag: 'original' } }, moveFails: true, takedowns: [{ id: T1, path: avatar, hold_path: hold1 }] });
  const j = await w.run();
  assert.ok(!w.store.media.has(avatar));
  assert.equal(j.takedowns.results[0].status, 'removed');
  assert.match(w.log.reports[0].p_error, /move to moderation-hold: move not supported/);
});

test('a replacement uploaded before the first cleanup is never moved or deleted', async () => {
  // the original was already gone (the golfer deleted it) and a new photo sits at the path
  const w = world({ media: { [avatar]: { v: 2, tag: 'replacement' } }, takedowns: [{ id: T1, path: avatar, hold_path: hold1 }] });
  await w.run();
  assert.equal(w.store.media.get(avatar)?.tag, 'replacement', 'the replacement was touched');
  assert.equal(w.log.moves.length + w.log.removes.length, 0);
  assert.equal(w.rows[0].status, 'removed');
});

test("the review's reproduction: move lands, report fails, replacement uploaded, retry — the replacement survives", async () => {
  const w = world({ media: { [avatar]: { v: 1, tag: 'original' } }, reportFailsOnce: true,
                    takedowns: [{ id: T1, path: avatar, hold_path: hold1 }] });
  await w.run();                                              // moved; the report never landed
  assert.equal(w.store.hold.get(hold1).tag, 'original');
  assert.equal(w.rows[0].status, 'pending');
  w.store.media.set(avatar, { v: 2, tag: 'replacement' });    // (live, the path lock refuses this; modelled here)
  w.expireLeases();
  await w.run();                                              // the retry
  assert.equal(w.store.media.get(avatar)?.tag, 'replacement', 'the retry deleted or moved the replacement');
  assert.equal(w.store.hold.get(hold1).tag, 'original');
  assert.equal(w.rows[0].status, 'removed');
});

test('overlapping runs: one row, one worker — a second concurrent run never acts on it', async () => {
  const round = `${A}/round-1.jpg`;
  const w = world({ media: { [avatar]: { v: 1 }, [round]: { v: 1 } },
                    takedowns: [{ id: T1, path: avatar, hold_path: hold1 }, { id: T2, path: round, hold_path: `${T2}/${round}` }] });
  const [x, y] = await Promise.all([w.run(), w.run()]);
  assert.equal(w.log.moves.length, 2, 'each file moved exactly once');
  assert.equal(x.takedowns.processed + y.takedowns.processed, 2);
  assert.ok(w.rows.every((r) => r.status === 'removed'));
});

test('a stale run (lease lost) cannot report over the current one', async () => {
  const w = world({ media: { [avatar]: { v: 1 } }, takedowns: [{ id: T1, path: avatar, hold_path: hold1 }] });
  w.rows[0].claim = 'someone-else';                          // claimed by a live run
  const j = await w.run();
  assert.equal(j.takedowns.processed, 0);
  assert.ok(w.store.media.has(avatar));
});

test("a deleting golfer's pending takedown deletes the original instead of keeping evidence", async () => {
  const w = world({ media: { [avatar]: { v: 1 } }, takedowns: [{ id: T1, path: avatar, hold_path: hold1, keep: false }] });
  await w.run();
  assert.equal(w.log.moves.length, 0, 'evidence was kept for a deleted account');
  assert.ok(!w.store.media.has(avatar) && !w.store.hold.has(hold1));
});

test("account deletion removes that golfer's held copies, and only theirs", async () => {
  const theirs = `${T2}/${B}/avatar.jpg`;
  const w = world({ hold: [hold1, theirs], accountDue: [A],
                    takedowns: [{ id: T1, path: avatar, hold_path: hold1, status: 'removed', owner: A, keep: false },
                                { id: T2, path: `${B}/avatar.jpg`, hold_path: theirs, status: 'removed', owner: B }] });
  const j = await w.run();
  assert.ok(!w.store.hold.has(hold1), "the deleted golfer's evidence is still held");
  assert.ok(w.store.hold.has(theirs), "another golfer's evidence was removed");
  assert.equal(j.media.completed, 1);
});
