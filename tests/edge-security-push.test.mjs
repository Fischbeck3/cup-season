// The push function's security fixes (review 2026-09-25: C-01, C-02, C-08).
// Run: node --experimental-strip-types --test tests/edge-security-push.test.mjs
//
// The pure rules are imported as they ship (push/guards.ts). The handler itself
// runs for real, inside a vm, against in-memory Supabase / web-push / fetch
// mocks (the tests/share-cleanup.test.mjs pattern). Nothing leaves the machine.
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import vm from 'node:vm';
import { test } from 'node:test';
import assert from 'node:assert/strict';
import * as guards from '../supabase/functions/push/guards.ts';
import * as header from '../supabase/functions/season-email/header.ts';

const { escapeHtml, mailName, oneLine, SUBJECT_MAX, emailSkip, nudgeAuthor, withTimeout } = guards;
const HOSTILE = '<a/href="https://evil.example/verify">Verify&nbsp;your&nbsp;account</a>';

/* ---- the pure rules ------------------------------------------------------- */

test('escapeHtml neutralises every markup character, and nothing else', () => {
  assert.equal(escapeHtml(`<img/src=x onerror='a'>&"`), '&lt;img/src=x onerror=&#39;a&#39;&gt;&amp;&quot;');
  assert.equal(escapeHtml('Jerecho'), 'Jerecho');
  assert.equal(escapeHtml(null), '');
  assert.doesNotMatch(escapeHtml(HOSTILE), /[<>"']/);
});

test('a requester is named by letters only: no link, no number, nothing to click', () => {
  assert.equal(mailName('Jerecho Fischbeck'), 'Jerecho');
  assert.equal(mailName("O'Brien-Smith"), "O'Brien-Smith");
  assert.equal(mailName('José'), 'José');
  assert.equal(mailName('https://evil.example/login'), 'httpsevilexamplelogi');
  assert.equal(mailName(HOSTILE), 'ahrefhttpsevilexampl');
  for (const n of ['1-800-555-0100', '', null, '   ', '🏌️', '...']) assert.equal(mailName(n), 'A golfer', String(n));
});

test('a subject is one line, free of control characters, and capped by code point', () => {
  assert.equal(oneLine('Mallory\r\nBcc: victim@x.example\u2028 wants\tin', SUBJECT_MAX), 'Mallory Bcc: victim@x.example wants in');
  assert.equal(oneLine('\u0000\u001b[31mred\u007f', SUBJECT_MAX), '[31mred');
  const long = oneLine('⛳'.repeat(300), SUBJECT_MAX);
  assert.equal(Array.from(long).length, SUBJECT_MAX);
  assert.ok(long.endsWith('…'));
  assert.doesNotMatch(long, /[\uD800-\uDBFF](?![\uDC00-\uDFFF])/, 'no half an emoji at the cut');
  assert.equal(oneLine('short', SUBJECT_MAX), 'short');
});

test('the season-email copy of oneLine is the same rule as push', () => {
  for (const s of ['a\r\nb', '\u0000x\u2029y', 'é'.repeat(200), '  spaced   out  ', '⛳'.repeat(130), null, 42]) {
    assert.equal(header.oneLine(s, SUBJECT_MAX), oneLine(s, SUBJECT_MAX), JSON.stringify(s));
  }
  assert.equal(header.SUBJECT_MAX, SUBJECT_MAX);
});

test('only a finished, live golfer card on a deliverable address is emailed', () => {
  const card = { email: 'golfer@gmail.com', handle: 'jf', deleted_at: null };
  assert.equal(emailSkip(card), null);
  assert.equal(emailSkip(null), 'no-profile');
  assert.equal(emailSkip({ ...card, handle: null }), 'unfinished-card');
  assert.equal(emailSkip({ ...card, handle: '  ' }), 'unfinished-card');
  assert.equal(emailSkip({ ...card, deleted_at: '2026-09-25T00:00:00Z' }), 'deleted');
  for (const e of ['deleted+1@cupseason.invalid', 'bot@cupseason.test', 'x@evil.example', 'a@b.localhost', '', null]) {
    assert.equal(emailSkip({ ...card, email: e }), 'undeliverable', String(e));
  }
});

test('the nudge author is the server-stamped sender, else the payload (system rows)', () => {
  assert.equal(nudgeAuthor({ sender_id: 'mallory' }, { profile_id: 'someone-else' }), 'mallory');
  assert.equal(nudgeAuthor({ sender_id: 'mallory' }, {}), 'mallory');
  assert.equal(nudgeAuthor({ sender_id: null }, { profile_id: 'host' }), 'host');
  assert.equal(nudgeAuthor({}, { profile_id: 'host' }), 'host');
  assert.equal(nudgeAuthor({ sender_id: '' }, {}), null);
  assert.equal(nudgeAuthor(null, null), null);
});

test('withTimeout lets a fast answer through and cuts a hang', async () => {
  assert.equal(await withTimeout(Promise.resolve(7), 50, 'x'), 7);
  const t0 = Date.now();
  await assert.rejects(withTimeout(new Promise(() => {}), 40, 'web push'), /web push timed out after 40ms/);
  assert.ok(Date.now() - t0 < 1000);
});

/* ---- the real handler ----------------------------------------------------- */

const SOURCE = readFileSync(new URL('../supabase/functions/push/index.ts', import.meta.url), 'utf8');
const FAST_MS = 150;

function world({ tables = {}, env = {}, webpush = {}, fetchImpl } = {}) {
  const log = { brevo: [], web: [], apns: [], fetchInits: [], deleted: [] };
  class Q {
    constructor(t) { this.t = t; this.f = []; this.one = false; this.op = 'select'; }
    select() { return this; }
    eq(c, v) { this.f.push((r) => r[c] === v); return this; }
    in(c, vs) { this.f.push((r) => vs.includes(r[c])); return this; }
    or() { return this; }
    delete() { this.op = 'delete'; return this; }
    update() { this.op = 'update'; return this; }
    maybeSingle() { this.one = true; return this; }
    then(res, rej) {
      const rows = (tables[this.t] ?? []).filter((r) => this.f.every((g) => g(r)));
      if (this.op === 'delete') {
        tables[this.t] = (tables[this.t] ?? []).filter((r) => !rows.includes(r));
        log.deleted.push(...rows.map((r) => `${this.t}:${r.id ?? r.token}`));
      }
      return Promise.resolve({ data: this.one ? rows[0] ?? null : rows, error: null }).then(res, rej);
    }
  }
  const sb = { from: (t) => new Q(t), rpc: async () => ({ data: 1, error: null }) };
  const wp = {
    setVapidDetails() {},
    sendNotification(sub, payload, opts) {
      log.web.push({ endpoint: sub.endpoint, payload, opts, at: Date.now() });
      return (webpush.send ?? (() => Promise.resolve({ statusCode: 201 })))(sub);
    },
  };
  const fetch = async (url, init) => {
    log.fetchInits.push({ url, init });
    if (url === 'https://api.brevo.com/v3/smtp/email') { log.brevo.push(JSON.parse(init.body)); return new Response('{}', { status: 201 }); }
    if (/^https:\/\/api(\.sandbox)?\.push\.apple\.com\//.test(url)) {
      log.apns.push({ url, at: Date.now() });
      return fetchImpl ? fetchImpl(url, init) : new Response('', { status: 200 });
    }
    throw new Error('unexpected network ' + url);
  };
  const src = SOURCE
    .replace(/^import .*$/gm, (line) => {
      if (!/npm:@supabase\/supabase-js|npm:web-push|\.\/guards\.ts/.test(line)) throw new Error('unexpected import: ' + line);
      return '';
    })
    .replace('const OUTBOUND_MS = 8000;', `const OUTBOUND_MS = ${FAST_MS};`);
  assert.match(src, new RegExp(`const OUTBOUND_MS = ${FAST_MS};`), 'the timeout constant is where the test expects it');
  const allEnv = { SUPABASE_URL: 'http://mock', SUPABASE_SERVICE_ROLE_KEY: 'svc', VAPID_PUBLIC_KEY: 'x', VAPID_PRIVATE_KEY: 'y', PUSH_WEBHOOK_SECRET: 's3cret', ...env };
  let handler;
  vm.runInNewContext(stripTypeScriptTypes(src), {
    ...guards, createClient: () => sb, webpush: wp, fetch, Response, AbortSignal, crypto, atob, btoa, TextEncoder,
    console: { log() {}, warn() {}, error() {} },
    Deno: { env: { get: (k) => allEnv[k] }, serve: (h) => { handler = h; } },
  });
  const hook = (body) => handler(new Request('http://fn/push', { method: 'POST', headers: { 'x-push-secret': 's3cret' }, body: JSON.stringify(body) }));
  return { hook, log, tables };
}
const reason = async (r) => (await r.json()).reason;
const friendRow = { table: 'friendships', type: 'INSERT', record: { id: 'f1', requester: 'mallory', addressee: 'victim', status: 'pending' } };
const people = (addressee = {}) => ({
  profiles: [
    { id: 'mallory', display_name: HOSTILE, handle: 'mal', email: 'm@gmail.com', deleted_at: null },
    { id: 'victim', display_name: '<img/src=https://evil.example/open.gif>Invoice&nbsp;overdue', handle: 'vic', email: 'cfo@victim-corp.com', deleted_at: null, ...addressee },
  ],
  mutes: [],
});

test('C-01 · a hostile display name reaches the email as text, never as markup', async () => {
  const w = world({ tables: people(), env: { BREVO_API_KEY: 'k' } });
  assert.equal(await reason(await w.hook(friendRow)), 'sent');
  assert.equal(w.log.brevo.length, 1);
  const mail = w.log.brevo[0];
  assert.doesNotMatch(mail.htmlContent, /<a\/href|<img\/src/);
  assert.match(mail.htmlContent, /<strong>ahrefhttpsevilexampl<\/strong> wants in your crew/);
  assert.doesNotMatch(mail.htmlContent, /verify/, "nothing of the requester's link survives");
  // the addressee's own name is theirs, and is escaped, not cut
  assert.match(mail.htmlContent, /Hi &lt;img\/src=https:\/\/evil\.example\/open\.gif&gt;Invoice&amp;nbsp;overdue,/);
  assert.equal(mail.subject, 'ahrefhttpsevilexampl wants in your crew');
  assert.doesNotMatch(mail.to[0].name ?? '', /[\r\n]/);
  const signal = w.log.fetchInits.find((f) => f.url.includes('brevo')).init.signal;
  assert.ok(signal && typeof signal.aborted === 'boolean', 'the Brevo call carries an abort signal');
});

test('C-01 · no email to an unfinished card, a deleted account, or someone who blocked the requester', async () => {
  for (const [addressee, why] of [[{ handle: null }, 'unfinished-card'], [{ deleted_at: '2026-09-01' }, 'deleted'],
    [{ email: 'deleted+victim@cupseason.invalid' }, 'undeliverable']]) {
    const w = world({ tables: people(addressee), env: { BREVO_API_KEY: 'k' } });
    const r = await w.hook(friendRow);
    const j = await r.json();
    assert.equal(j.reason, 'email-skipped'); assert.equal(j.why, why);
    assert.equal(w.log.brevo.length, 0, why);
  }
  const t = people(); t.mutes = [{ muter: 'victim', muted: 'mallory' }];
  const w = world({ tables: t, env: { BREVO_API_KEY: 'k' } });
  assert.equal(await reason(await w.hook(friendRow)), 'muted');
  assert.equal(w.log.brevo.length, 0);
});

test('C-02 · a mute stops an invite through the server-stamped sender, even with no author in the payload', async () => {
  const tables = { mutes: [{ muter: 'victim', muted: 'mallory' }],
    push_subscriptions: [{ id: 's1', profile_id: 'victim', endpoint: 'https://fcm.googleapis.com/fcm/send/abc', p256dh: 'k', auth: 'a' }] };
  const invite = { id: 'n1', profile_id: 'victim', kind: 'invite', sender_id: 'mallory', title: 'URGENT: your Apple ID is locked', body: 'x', payload: { invite_id: 'i1', league_id: 'l1' } };
  const w = world({ tables });
  assert.equal(await reason(await w.hook({ table: 'push_nudges', type: 'INSERT', record: invite })), 'muted');
  assert.equal(w.log.web.length, 0);
  // an unmuted sender still rings
  const w2 = world({ tables: { ...tables, mutes: [] } });
  assert.equal(await reason(await w2.hook({ table: 'push_nudges', type: 'INSERT', record: invite })), 'sent');
  assert.equal(w2.log.web.length, 1);
  // a system row (no sender) keeps the payload's author, as before
  const sys = { ...invite, kind: 'request', sender_id: null, payload: { request_id: 'r1', profile_id: 'mallory' } };
  const w3 = world({ tables });
  assert.equal(await reason(await w3.hook({ table: 'push_nudges', type: 'INSERT', record: sys })), 'muted');
});

async function apnsKey() {
  const kp = await crypto.subtle.generateKey({ name: 'ECDSA', namedCurve: 'P-256' }, true, ['sign', 'verify']);
  const der = Buffer.from(await crypto.subtle.exportKey('pkcs8', kp.privateKey)).toString('base64');
  return { APNS_P8: `-----BEGIN PRIVATE KEY-----\n${der}\n-----END PRIVATE KEY-----`, APNS_KEY_ID: 'K', APNS_TEAM_ID: 'T' };
}
const league = () => ({
  leagues: [{ id: 'L', name: 'PIGL', notify_system: true }],
  league_members: [
    { id: 'm1', profile_id: 'attacker', league_id: 'L', profiles: {} },
    { id: 'm2', profile_id: 'alice', league_id: 'L', profiles: {} },
    { id: 'm3', profile_id: 'bob', league_id: 'L', profiles: {} },
  ],
  mutes: [],
  device_tokens: [{ token: 'bb'.repeat(32), profile_id: 'bob', platform: 'ios' }],
  push_subscriptions: [
    { id: 'tarpit', profile_id: 'attacker', endpoint: 'https://tarpit.attacker.example/x', p256dh: 'k', auth: 'a' },
    { id: 'gone', profile_id: 'bob', endpoint: 'https://fcm.googleapis.com/fcm/send/gone', p256dh: 'k', auth: 'a' },
  ],
});
const post = { table: 'posts', type: 'INSERT', record: { id: 'p1', league_id: 'L', member_id: 'm2', kind: 'round', body: 'Alice posted 79 at Papago.' } };

test('C-08 · a web-push endpoint that never answers cannot hold APNs, and a dead one is still pruned', async () => {
  const w = world({ tables: league(), env: await apnsKey(), webpush: { send: (sub) =>
    sub.endpoint.includes('tarpit') ? new Promise(() => {})
      : Promise.reject(Object.assign(new Error('gone'), { statusCode: 410 })) } });
  const t0 = Date.now();
  const r = await w.hook(post);
  const took = Date.now() - t0;
  assert.equal(await reason(r), 'sent');
  assert.equal(w.log.apns.length, 1, 'bob\'s iPhone rang');
  assert.ok(w.log.apns[0].at - t0 < FAST_MS, `APNs went out at ${w.log.apns[0].at - t0}ms, before the web-push clock (${FAST_MS}ms)`);
  assert.ok(took >= FAST_MS && took < 3000, `the handler finished after the timeout (${took}ms), not never`);
  assert.ok(w.log.web.every((x) => x.opts?.timeout === FAST_MS), 'web-push gets its own socket timeout too');
  assert.deepEqual(w.log.deleted, ['push_subscriptions:gone'], 'the 410 is pruned; the timed-out one is kept');
});

test('C-08 · an APNs call that never answers is aborted by its own clock, and web push still goes', async () => {
  const w = world({ tables: { ...league(), push_subscriptions: [league().push_subscriptions[1]] }, env: await apnsKey(),
    fetchImpl: (_u, init) => new Promise((_, reject) => init.signal.addEventListener('abort', () => reject(init.signal.reason))) });
  const t0 = Date.now();
  assert.equal(await reason(await w.hook(post)), 'sent');
  const took = Date.now() - t0;
  assert.ok(took >= FAST_MS - 20 && took < 3000, `aborted after ${took}ms`);
  assert.equal(w.log.web.length, 1);
  assert.deepEqual(w.log.deleted, [], 'a timeout is not a dead token');
});
