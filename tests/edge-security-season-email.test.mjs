// season-email's cancellation branch mails only what the database holds (review 2026-09-25, C-11).
// Run: node --experimental-strip-types --test tests/edge-security-season-email.test.mjs
//
// The real handler runs in a vm against a mock cancellation_notices table and a
// recording Brevo; the request body plays the part of anyone holding the shared secret.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as header from '../supabase/functions/season-email/header.ts';

const SRC = stripTypeScriptTypes(readFileSync(new URL('../supabase/functions/season-email/index.ts', import.meta.url), 'utf8')
  .replace(/^import .*$/gm, (line) => {
    if (!/npm:@supabase\/supabase-js|\.\/header\.ts/.test(line)) throw new Error('unexpected import: ' + line);
    return '';
  }));
const ID = '5d0c6d2e-8b1a-4f3e-9c2d-1a2b3c4d5e6f';
const DB_NOTICE = { id: ID, sent_at: null, payload: { league: 'PIGL', recipients: [
  { email: 'ann@gmail.com', name: 'Ann', cents: 5000 }, { email: 'bo@gmail.com', name: 'Bo', cents: 0 }] } };

function worker({ notices = [DB_NOTICE], readError = null, payload = null } = {}) {
  const log = { brevo: [], inits: [], rpc: [], reads: 0 };
  const sb = {
    from: (t) => {
      assert.equal(t, 'cancellation_notices');
      let id;
      const q = { select: () => q, eq: (_c, v) => { id = v; return q; }, maybeSingle: () => q,
        then: (res, rej) => { log.reads++; return Promise.resolve(readError ? { data: null, error: { message: readError } }
          : { data: notices.find((n) => n.id === id) ?? null, error: null }).then(res, rej); } };
      return q;
    },
    rpc: async (name, args) => { log.rpc.push([name, JSON.parse(JSON.stringify(args))]);
      return name === 'season_email_payload' ? { data: payload, error: null } : { data: null, error: null }; },
  };
  const fetch = async (url, init) => {
    assert.equal(url, 'https://api.brevo.com/v3/smtp/email');
    log.inits.push(init); log.brevo.push(JSON.parse(init.body));
    return new Response('{}', { status: 201 });
  };
  let handler;
  vm.runInNewContext(SRC, { ...header, createClient: () => sb, fetch, Response, AbortSignal, console: { log() {}, error() {} },
    Deno: { env: { get: (k) => ({ PUSH_WEBHOOK_SECRET: 's3cret', BREVO_API_KEY: 'k' })[k] }, serve: (h) => { handler = h; } } });
  const hook = (body) => handler(new Request('http://fn/season-email', { method: 'POST', headers: { 'x-push-secret': 's3cret' }, body: JSON.stringify(body) }));
  return { hook, log };
}
const forged = (id, extra = {}) => ({ type: 'INSERT', table: 'cancellation_notices', record: { id, sent_at: null, ...extra,
  payload: { league: 'Your account is locked', recipients: [{ email: 'cfo@victim-corp.com', name: 'CFO', cents: 99999 }] } } });

test('C-11 · the addresses in a request body are ignored; the notice is re-read by id', async () => {
  const w = worker();
  const r = await w.hook(forged(ID));
  assert.equal(r.status, 200);
  assert.deepEqual(w.log.brevo.map((m) => m.to[0].email), ['ann@gmail.com', 'bo@gmail.com']);
  assert.ok(w.log.brevo.every((m) => !JSON.stringify(m).includes('victim-corp') && !m.subject.includes('locked')));
  assert.deepEqual(w.log.rpc, [['mark_cancellation_sent', { p_id: ID, p_error: null }]]);
  assert.ok(w.log.inits.every((i) => i.signal && typeof i.signal.aborted === 'boolean'), 'each Brevo call has a clock');
});

test('C-11 · an unknown, malformed or already-sent notice mails nobody', async () => {
  for (const [w, body, text] of [
    [worker(), forged('00000000-0000-4000-8000-000000000000'), 'no such notice'],
    [worker(), forged('not-a-uuid'), 'no such notice'],
    [worker(), forged(undefined), 'no such notice'],
    [worker({ notices: [{ ...DB_NOTICE, sent_at: '2026-09-20T00:00:00Z' }] }), forged(ID), 'already sent'],
  ]) {
    const r = await w.hook(body);
    assert.equal(await r.text(), text);
    assert.equal(w.log.brevo.length, 0);
    assert.deepEqual(w.log.rpc, []);
  }
});

test('C-11 · a notice the database cannot read is a 500, not a send', async () => {
  const w = worker({ readError: 'connection reset' });
  const r = await w.hook(forged(ID));
  assert.equal(r.status, 500);
  assert.equal(w.log.brevo.length, 0);
});

test('C-11 · a hostile league name is one capped header line and escaped HTML', async () => {
  const league = '<img src=https://evil.example/p.gif>Refund\r\nBcc: all@x.example ' + 'x'.repeat(200);
  const w = worker({ notices: [{ ...DB_NOTICE, payload: { league, recipients: [{ email: 'ann@gmail.com', name: 'Ann\r\nX-Evil: 1', cents: 5000 }] } }] });
  await w.hook(forged(ID));
  const [m] = w.log.brevo;
  assert.doesNotMatch(m.subject, /[\r\n]/);
  assert.ok(Array.from(m.subject).length <= header.SUBJECT_MAX);
  assert.doesNotMatch(m.to[0].name, /[\r\n]/);
  assert.doesNotMatch(m.htmlContent, /<img src=https:\/\/evil/);
  assert.match(m.htmlContent, /&lt;img src=https:\/\/evil\.example\/p\.gif&gt;/);
});

test('the season recap still sends from the database payload', async () => {
  const payload = { season_id: 's1', league: 'PIGL', champion: 'Mudsharks', runner_up: 'Birdies', points_king: null,
    champion_score: 412, runnerup_score: 388, tiebreak: null, starts_on: '2026-04-01', ends_on: '2026-09-01', solo: false,
    rows: [{ name: 'Mudsharks', points: 412 }], recipients: [{ email: 'ann@gmail.com', name: 'Ann', token: 't1', cents: 0 }] };
  const w = worker({ payload });
  const r = await w.hook({ type: 'INSERT', table: 'email_queue', record: { id: 'q1', season_id: 's1', sent_at: null } });
  assert.equal(r.status, 200);
  assert.equal(w.log.brevo.length, 1);
  assert.equal(w.log.brevo[0].subject, 'The Cup goes to Mudsharks by 24 — PIGL');
  assert.deepEqual(w.log.rpc.map((x) => x[0]), ['season_email_payload', 'mark_email_sent']);
});
