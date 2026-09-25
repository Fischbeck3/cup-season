// The paid-API guards (review 2026-09-25: C-04 courses, C-07 scan).
// Run: node --experimental-strip-types --test tests/edge-security-courses-scan.test.mjs
//
// courses/reserve.ts is imported as it ships; both handlers run for real inside
// a vm against in-memory Supabase and a counting upstream mock. The point of
// every handler test is the same number: upstream calls made when the ledger
// said no, or could not say anything. It must be zero.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as normalize from '../supabase/functions/courses/normalize.ts';
import * as reserve from '../supabase/functions/courses/reserve.ts';

const { unitsFor, reservation, SEARCH_DETAIL_FETCHES } = reserve;

function load(rel, allowed, globals) {
  const src = readFileSync(new URL(rel, import.meta.url), 'utf8').replace(/^import .*$/gm, (line) => {
    if (!allowed.test(line)) throw new Error('unexpected import: ' + line);
    return '';
  });
  let handler;
  vm.runInNewContext(stripTypeScriptTypes(src), { ...globals, Response, URL, console: { log() {}, error() {} },
    Deno: { env: { get: (k) => globals.env[k] }, serve: (h) => { handler = h; } } });
  return handler;
}

/* ---- units: the most a request can spend upstream ------------------------- */

test('a search books its search call plus every detail fetch it may make', () => {
  assert.equal(SEARCH_DETAIL_FETCHES, 3);
  assert.equal(unitsFor('search', { q: 'papago' }), 4);
  assert.equal(unitsFor('search', { q: 12345 }), 4);
  assert.equal(unitsFor('cache', { id: '1001' }), 1);
});

test('a request that cannot reach the provider books nothing', () => {
  assert.equal(unitsFor('search', { q: 'pa' }), 0);
  assert.equal(unitsFor('search', { q: '  pa  ' }), 0);
  assert.equal(unitsFor('search', {}), 0);
  assert.equal(unitsFor('cache', { id: '   ' }), 0);
  assert.equal(unitsFor('delete-everything', { q: 'papago' }), 0);
  assert.equal(unitsFor(undefined, null), 0);
});

test('only a clean ok spends; every other answer refuses, and never with a 200', () => {
  assert.deepEqual(reservation('ok', null), { ok: true });
  assert.equal(reservation('user_cap', null).status, 429);
  assert.equal(reservation('global_cap', null).status, 429);
  assert.notEqual(reservation('global_cap', null).error, reservation('user_cap', null).error);
  for (const [d, e] of [['ok', { message: 'boom' }], [null, null], ['bad_request', null], ['OK', null], [undefined, { message: 'x' }]]) {
    assert.equal(reservation(d, e).status, 503, JSON.stringify([d, e]));
  }
});

/* ---- the courses handler -------------------------------------------------- */

function courses({ verdict = 'ok', rpcError = null } = {}) {
  const log = { reserve: [], upstream: 0, inserts: [], order: [] };
  const table = () => {
    const q = { select: () => q, eq: () => q, in: () => q, maybeSingle: () => q,
      insert: (row) => { log.inserts.push(row); return q; },
      then: (res, rej) => Promise.resolve({ data: null, count: 0, error: null }).then(res, rej) };
    return q;
  };
  const client = (_u, _k, o) => ({
    auth: { getUser: async () => ({ data: { user: /Bearer user:/.test(o?.global?.headers?.Authorization ?? '') ? { id: 'u1' } : null } }) },
    from: table,
    rpc: async (name, args) => {
      if (name === '_courses_reserve') { log.order.push('reserve'); log.reserve.push(JSON.parse(JSON.stringify(args))); return { data: rpcError ? null : verdict, error: rpcError }; }
      if (name === 'cache_course_card') return { data: String(args.p_course.id), error: null };
      throw new Error('unexpected rpc ' + name);
    },
  });
  const fetch = async (url) => {
    assert.match(String(url), /^https:\/\/api\.golfcourseapi\.com\//);
    log.upstream++; log.order.push('upstream');
    if (String(url).includes('/v1/search')) return new Response(JSON.stringify({ courses: [1, 2, 3, 4].map((i) => ({ id: 1000 + i, club_name: 'C' + i, tees: { male: 8 } })) }));
    const id = Number(String(url).split('/').pop());
    return new Response(JSON.stringify({ course: { id: String(id), location: {}, tees: { male: [{ tee_name: 'Blue', course_rating: 70.1, slope_rating: 125, holes: [{ par: 4 }] }] } } }));
  };
  const handler = load('../supabase/functions/courses/index.ts', /esm\.sh\/@supabase\/supabase-js|\.\/normalize\.ts|\.\/reserve\.ts/,
    { ...normalize, ...reserve, createClient: client, fetch, JSON, env: { GOLFCOURSE_API_KEY: 'k', SUPABASE_URL: 'http://mock', SUPABASE_SERVICE_ROLE_KEY: 'svc', SUPABASE_ANON_KEY: 'anon' } });
  const call = (body) => handler(new Request('http://fn/courses', { method: 'POST', headers: { Authorization: 'Bearer user:u1' }, body: JSON.stringify(body) }));
  return { call, log };
}

test('C-04 · a search reserves its worst case BEFORE the first upstream call, once', async () => {
  const c = courses();
  const r = await c.call({ action: 'search', q: 'papago' });
  assert.equal(r.status, 200);
  assert.deepEqual(c.log.reserve, [{ p_profile: 'u1', p_action: 'search', p_units: 4 }]);
  assert.equal(c.log.order[0], 'reserve', 'booked before the first upstream call');
  assert.ok(c.log.upstream <= 4, `spent ${c.log.upstream} of the 4 it booked`);
  assert.deepEqual(c.log.inserts, [], 'no fire-and-forget ledger write any more');
});

test('C-04 · a refused or unreadable reservation spends nothing upstream', async () => {
  for (const [opts, status, err] of [
    [{ verdict: 'user_cap' }, 429, 'daily course-lookup limit reached'],
    [{ verdict: 'global_cap' }, 429, 'course lookups are paused for today'],
    [{ rpcError: { message: 'function _courses_reserve does not exist' } }, 503, 'course lookup unavailable'],
    [{ verdict: 'bad_request' }, 503, 'course lookup unavailable'],
    [{ verdict: null }, 503, 'course lookup unavailable'],
  ]) {
    const c = courses(opts);
    const r = await c.call({ action: 'search', q: 'papago' });
    assert.equal(r.status, status, JSON.stringify(opts));
    assert.equal((await r.json()).error, err);
    assert.equal(c.log.upstream, 0, `${JSON.stringify(opts)} made an upstream call`);
  }
});

test('C-04 · a cache pull books one unit; a short query books none and calls nobody', async () => {
  const c = courses();
  assert.equal((await c.call({ action: 'cache', id: '1001' })).status, 200);
  assert.deepEqual(c.log.reserve.map((a) => a.p_units), [1]);
  const s = courses({ verdict: 'user_cap' });
  const r = await s.call({ action: 'search', q: 'pa' });
  assert.deepEqual(await r.json(), { courses: [] });
  assert.deepEqual(s.log.reserve, []);
  assert.equal(s.log.upstream, 0);
});

/* ---- the scan handler ----------------------------------------------------- */

function scan({ flag, insertFails = false, countFails = false } = {}) {
  const log = { paid: 0, inserted: 0, deleted: 0 };
  const table = (t) => {
    let op = 'select', count = false;
    const q = {
      select: (_c, o) => { if (o?.count) count = true; return q; },
      insert: () => { op = 'insert'; return q; }, update: () => { op = 'update'; return q; }, delete: () => { op = 'delete'; return q; },
      eq: () => q, gte: () => q, maybeSingle: () => q, single: () => q,
      then: (res, rej) => {
        let out = { data: null, error: null };
        if (t === 'app_flags') out = { data: flag === undefined ? null : { value: flag }, error: null };
        else if (op === 'insert') { if (insertFails) out = { data: null, error: { message: 'insert failed' } }; else { log.inserted++; out = { data: { id: 'resv-1' }, error: null }; } }
        else if (op === 'delete') log.deleted++;
        else if (count) out = countFails ? { count: null, data: null, error: { message: 'count failed' } } : { count: 1, data: null, error: null };
        return Promise.resolve(out).then(res, rej);
      },
    };
    return q;
  };
  const client = (_u, _k, o) => ({
    auth: { getUser: async () => ({ data: { user: /Bearer user:/.test(o?.global?.headers?.Authorization ?? '') ? { id: 'u1' } : null } }) },
    from: table,
  });
  const fetch = async (url) => {
    assert.equal(String(url), 'https://api.anthropic.com/v1/messages');
    log.paid++;
    return new Response(JSON.stringify({ stop_reason: 'end_turn', content: [{ type: 'text', text: JSON.stringify({ course_name: '', date: '', par_row: [], players: [{ name: 'a', holes: [4], total: 72 }] }) }] }));
  };
  const handler = load('../supabase/functions/scan/index.ts', /esm\.sh\/@supabase\/supabase-js/,
    { createClient: client, fetch, JSON, Date, env: { ANTHROPIC_API_KEY: 'k', SUPABASE_URL: 'http://mock', SUPABASE_SERVICE_ROLE_KEY: 'svc', SUPABASE_ANON_KEY: 'anon' } });
  const call = () => handler(new Request('http://fn/scan', { method: 'POST', headers: { Authorization: 'Bearer user:u1' }, body: JSON.stringify({ image: 'A'.repeat(2000) }) }));
  return { call, log };
}

test('C-07 · the kill switch fails closed: a missing flag, a flag without enabled, or enabled:false is OFF', async () => {
  for (const flag of [undefined, {}, { enabled: false }, { enabled: 'true' }, { daily_per_user: 5 }]) {
    const s = scan({ flag });
    assert.deepEqual(await (await s.call()).json(), { unavailable: true, reason: 'disabled' }, JSON.stringify(flag));
    assert.equal(s.log.paid, 0);
    assert.equal(s.log.inserted, 0);
  }
});

test('C-07 · no reservation, or an unreadable count, means no paid call', async () => {
  const a = scan({ flag: { enabled: true }, insertFails: true });
  assert.deepEqual(await (await a.call()).json(), { unavailable: true, reason: 'unavailable' });
  assert.equal(a.log.paid, 0);
  const b = scan({ flag: { enabled: true }, countFails: true });
  assert.deepEqual(await (await b.call()).json(), { unavailable: true, reason: 'unavailable' });
  assert.equal(b.log.paid, 0);
  assert.equal(b.log.deleted, 1, 'the reservation is withdrawn');
});

test('C-07 · an enabled flag with room under both caps still scans (one paid call)', async () => {
  const s = scan({ flag: { enabled: true, daily_per_user: 5, monthly_global: 400 } });
  const j = await (await s.call()).json();
  assert.equal(j.ok, true);
  assert.equal(s.log.paid, 1);
});
