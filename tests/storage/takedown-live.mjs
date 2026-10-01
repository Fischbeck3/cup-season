// D403 · LIVE proof against a real LOCAL Supabase stack (Storage + imgproxy + PostgREST +
// Auth + the Edge runtime) — never production. It refuses to run unless every URL is
// localhost / 127.0.0.1. It proves what the SQL suite and the mocked worker tests
// cannot:
//   1 · URLs minted BEFORE a photo takedown — original signed, transformed signed, the
//       shared public copy and its transformed preview — stop serving once the real
//       share-cleanup function has run against real Storage; the evidence sits in the
//       private moderation-hold bucket, which no client can read or sign.
//   2 · the PostgREST pre-request gate really runs: a removed golfer's still-valid
//       token is refused on the API and on Storage; restored, it works again.
//   3 · the scan function refuses a revoked consent before any reservation (and so
//       before any provider call) — the server half of the A/B regression.
//
// Setup (docs/ios/app-store-package-2026-09-30.md, "Live local proof"):
//   supabase start --workdir <scratch> (migrations applied as postgres), then
//   supabase functions serve share-cleanup scan --workdir <scratch> --env-file <env>
//   CS_LOCAL_URL=http://127.0.0.1:54421 CS_LOCAL_ANON=… CS_LOCAL_SERVICE=… CS_LOCAL_DB_URL=… \
//   CS_CLEANUP_SECRET=… node --test tests/storage/takedown-live.mjs
// Keys are the local stack's own (supabase status); nothing here is a production secret.
import { test } from 'node:test';
import assert from 'node:assert/strict';
import { randomUUID, randomBytes } from 'node:crypto';
import { execFileSync } from 'node:child_process';

const URL_ = process.env.CS_LOCAL_URL ?? '';
const ANON = process.env.CS_LOCAL_ANON ?? '';
const SERVICE = process.env.CS_LOCAL_SERVICE ?? '';
const FN = process.env.CS_LOCAL_FN_URL ?? (URL_ ? URL_ + '/functions/v1' : '');
const SECRET = process.env.CS_CLEANUP_SECRET ?? '';
// fixtures are written as the server would (postgres), on the LOCAL database only
const DB = process.env.CS_LOCAL_DB_URL ?? '';
const PSQL = process.env.PSQL ?? 'psql';
const local = (u) => { try { return ['127.0.0.1', 'localhost'].includes(new URL(u).hostname); } catch { return false; } };
const ready = URL_ && ANON && SERVICE && SECRET && DB && local(URL_) && local(FN) && local(DB.replace(/^postgres(ql)?:/, 'http:'));
const skip = ready ? false : 'needs a LOCAL stack: CS_LOCAL_URL, CS_LOCAL_ANON, CS_LOCAL_SERVICE, CS_LOCAL_DB_URL, CS_CLEANUP_SECRET (localhost only)';
const sql = (q) => execFileSync(PSQL, [DB, '-X', '-A', '-t', '-v', 'ON_ERROR_STOP=1', '-c', q], { encoding: 'utf8' }).trim();

const JPEG = Buffer.from('/9j/4AAQSkZJRgABAQAASABIAAD/4QCARXhpZgAATU0AKgAAAAgABAEaAAUAAAABAAAAPgEbAAUAAAABAAAARgEoAAMAAAABAAIAAIdpAAQAAAABAAAATgAAAAAAAABIAAAAAQAAAEgAAAABAAOgAQADAAAAAQABAACgAgAEAAAAAQAAABCgAwAEAAAAAQAAABAAAAAA/+0AOFBob3Rvc2hvcCAzLjAAOEJJTQQEAAAAAAAAOEJJTQQlAAAAAAAQ1B2M2Y8AsgTpgAmY7PhCfv/AABEIABAAEAMBIgACEQEDEQH/xAAfAAABBQEBAQEBAQAAAAAAAAAAAQIDBAUGBwgJCgv/xAC1EAACAQMDAgQDBQUEBAAAAX0BAgMABBEFEiExQQYTUWEHInEUMoGRoQgjQrHBFVLR8CQzYnKCCQoWFxgZGiUmJygpKjQ1Njc4OTpDREVGR0hJSlNUVVZXWFlaY2RlZmdoaWpzdHV2d3h5eoOEhYaHiImKkpOUlZaXmJmaoqOkpaanqKmqsrO0tba3uLm6wsPExcbHyMnK0tPU1dbX2Nna4eLj5OXm5+jp6vHy8/T19vf4+fr/xAAfAQADAQEBAQEBAQEBAAAAAAAAAQIDBAUGBwgJCgv/xAC1EQACAQIEBAMEBwUEBAABAncAAQIDEQQFITEGEkFRB2FxEyIygQgUQpGhscEJIzNS8BVictEKFiQ04SXxFxgZGiYnKCkqNTY3ODk6Q0RFRkdISUpTVFVWV1hZWmNkZWZnaGlqc3R1dnd4eXqCg4SFhoeIiYqSk5SVlpeYmZqio6Slpqeoqaqys7S1tre4ubrCw8TFxsfIycrS09TV1tfY2dri4+Tl5ufo6ery8/T19vf4+fr/2wBDAAICAgICAgMCAgMFAwMDBQYFBQUFBggGBgYGBggKCAgICAgICgoKCgoKCgoMDAwMDAwODg4ODg8PDw8PDw8PDw//2wBDAQICAgQEBAcEBAcQCwkLEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBD/3QAEAAH/2gAMAwEAAhEDEQA/APnOiiivwc/Iz//Z', 'base64');

async function call(path, { method = 'GET', token = ANON, apikey = ANON, body, headers = {}, raw = false } = {}) {
  const h = { apikey, authorization: 'Bearer ' + token, ...headers };
  let payload = body;
  if (body !== undefined && !(body instanceof Uint8Array)) { h['content-type'] = 'application/json'; payload = JSON.stringify(body); }
  const res = await fetch(URL_ + path, { method, headers: h, body: payload });
  if (raw) return res;
  const text = await res.text();
  let json = null; try { json = JSON.parse(text); } catch { /* not json */ }
  return { status: res.status, json, text };
}
const svc = (path, opts = {}) => call(path, { token: SERVICE, apikey: SERVICE, ...opts });
const status = async (absUrl) => (await fetch(absUrl)).status;

async function golfer(tag) {
  const email = `${tag}.${randomUUID().slice(0, 8)}@example.invalid`;
  const password = randomBytes(18).toString('base64url');          // generated here, never stored
  const made = await svc('/auth/v1/admin/users', { method: 'POST', body: { email, password, email_confirm: true } });
  assert.equal(made.status, 200, 'create user: ' + made.text);
  const signed = await call('/auth/v1/token?grant_type=password', { method: 'POST', body: { email, password } });
  assert.equal(signed.status, 200, 'sign in: ' + signed.text);
  return { id: made.json.id, token: signed.json.access_token };
}
const upload = (who, bucket, path) => call(`/storage/v1/object/${bucket}/${path}`, {
  method: 'POST', token: who.token, body: new Uint8Array(JPEG), headers: { 'content-type': 'image/jpeg', 'x-upsert': 'false' } });
async function sign(who, path, transform) {
  const r = await call(`/storage/v1/object/sign/media/${path}`, { method: 'POST', token: who.token,
    body: transform ? { expiresIn: 3600, transform } : { expiresIn: 3600 } });
  return { status: r.status, url: r.json?.signedURL ? URL_ + '/storage/v1' + r.json.signedURL : null, text: r.text };
}
const sweep = async () => {
  const r = await fetch(FN + '/share-cleanup', { method: 'POST', headers: { 'x-cleanup-secret': SECRET } });
  return { status: r.status, json: await r.json() };
};

test('a takedown stops every URL minted before it, once the real worker has moved the file', { skip }, async () => {
  const founder = await golfer('founder'), owner = await golfer('owner'), mate = await golfer('mate');
  sql(`update profiles set is_founder = false where is_founder; update profiles set is_founder = true where id = '${founder.id}'`);
  const league = randomUUID();
  sql(`insert into leagues (id, name, code, commissioner_id, phase) values ('${league}', 'Live QA', 'LQ${league.slice(0, 4).toUpperCase()}', '${owner.id}', 'season');
       insert into league_members (league_id, profile_id, role) values ('${league}', '${owner.id}', 'commissioner'), ('${league}', '${mate.id}', 'player')`);

  // the owner's photos, uploaded through Storage under row security
  const roundPath = `${owner.id}/round-live.jpg`, avatarPath = `${owner.id}/avatar.jpg`;
  assert.equal((await upload(owner, 'media', roundPath)).status, 200);
  assert.equal((await upload(owner, 'media', avatarPath)).status, 200);
  const round = await call('/rest/v1/rounds', { method: 'POST', token: owner.token, headers: { prefer: 'return=representation' },
    body: { course_label: 'Live QA Links', gross: 84, rating: 70.2, slope: 119, played_on: '2026-09-30', photo_path: roundPath } });
  assert.equal(round.status, 201, round.text);
  const roundId = round.json[0].id;
  sql(`update profiles set photo_path = '${avatarPath}' where id = '${owner.id}'`);
  // a public share copy (the preview a link unfurls)
  const token = randomUUID();
  sql(`insert into shares (token, kind, ref_id, created_by) values ('${token}', 'round', '${roundId}', '${owner.id}')`);
  assert.equal((await upload(owner, 'shared', `${token}.jpg`)).status, 200);

  // every URL a viewer could hold, minted BEFORE the takedown
  const before = {
    'round · signed (league-mate)': (await sign(mate, roundPath)).url,
    'round · signed transform': (await sign(mate, roundPath, { width: 8, height: 8 })).url,
    'avatar · signed (owner)': (await sign(owner, avatarPath)).url,
    'avatar · signed transform': (await sign(mate, avatarPath, { width: 8, height: 8 })).url,
    'share copy · public': `${URL_}/storage/v1/object/public/shared/${token}.jpg`,
    'share preview · public transform': `${URL_}/storage/v1/render/image/public/shared/${token}.jpg?width=8&height=8`,
  };
  for (const [k, u] of Object.entries(before)) {
    assert.ok(u, `${k}: no URL minted`);
    assert.equal(await status(u), 200, `${k}: should serve before the takedown`);
  }

  // the founder takes both photos down
  for (const [kind, target] of [['round_photo', roundId], ['profile_photo', owner.id]]) {
    const r = await call('/rest/v1/rpc/takedown_photo', { method: 'POST', token: founder.token, body: { p_kind: kind, p_target: target, p_reason: 'QA live takedown' } });
    assert.equal(r.status, 200, r.text);
    assert.equal(r.json.file, 'queued', 'the file removal is reported as queued, not done');
  }
  // at once: no NEW link can be minted, by anyone, the owner included
  assert.notEqual((await sign(mate, roundPath)).status, 200, 'a new link was minted after the takedown');
  assert.notEqual((await sign(owner, avatarPath)).status, 200, 'the owner minted a new link after the takedown');
  // the honest gap, measured: before the worker runs, a previously minted signed URL
  // is still honoured on its signature (this is why the file must move)
  const gap = await status(before['round · signed (league-mate)']);

  // the real share-cleanup function, against real Storage
  const run = await sweep();
  assert.equal(run.status, 200, JSON.stringify(run.json));
  // (a reused stack may hold earlier rows; ours are checked one by one below)
  assert.equal(run.json.takedowns.failed, 0, JSON.stringify(run.json.takedowns));
  assert.ok(run.json.takedowns.removed >= 2, JSON.stringify(run.json.takedowns));
  for (const [k, u] of Object.entries(before)) {
    const s = await status(u);
    assert.ok(s >= 400, `${k}: still serving (${s}) after the worker ran`);
  }
  // the evidence is kept, privately: the service role sees it; no golfer can sign it
  const rows = JSON.parse(sql(`select coalesce(json_agg(t), '[]') from (select status, hold_path, purge_after, path from media_takedowns
                                where path in ('${roundPath}', '${avatarPath}')) t`));
  assert.equal(rows.length, 2);
  for (const row of rows) {
    assert.equal(row.status, 'removed');
    assert.ok(row.hold_path && row.purge_after, 'evidence kept with a purge date');
    assert.equal((await svc(`/storage/v1/object/moderation-hold/${row.hold_path}`, { raw: true })).status, 200, 'service role reads the evidence');
    const theirs = await call(`/storage/v1/object/sign/moderation-hold/${row.hold_path}`, { method: 'POST', token: founder.token, body: { expiresIn: 60 } });
    assert.notEqual(theirs.status, 200, 'a golfer (even the founder) could sign the evidence');
  }
  // a second sweep does no further work and stays healthy
  const again = await sweep();
  assert.equal(again.status, 200);
  assert.equal(again.json.takedowns.processed, 0);
  console.log(`[live] signed URL before the worker ran: HTTP ${gap} (expected 200 — the bound is the worker's next run)`);
});

test('the PostgREST gate refuses a removed golfer\'s still-valid token, on the API and on Storage', { skip }, async () => {
  const founder = await golfer('founder2'), target = await golfer('target');
  sql(`update profiles set is_founder = false where is_founder; update profiles set is_founder = true where id = '${founder.id}'`);
  const handle = 'qa_' + target.id.slice(0, 8);
  sql(`update profiles set handle = '${handle}', display_name = 'QA Target' where id = '${target.id}'`);
  assert.equal((await call('/rest/v1/profiles?select=id&limit=1', { token: target.token })).status, 200);

  const ban = await call('/rest/v1/rpc/ban_account', { method: 'POST', token: founder.token, body: { p_profile: target.id, p_confirm: handle, p_reason: 'QA live ban' } });
  assert.equal(ban.status, 200, ban.text);
  const refused = await call('/rest/v1/profiles?select=id&limit=1', { token: target.token });
  assert.equal(refused.status, 403, 'the API answered a removed golfer: ' + refused.text);
  assert.match(refused.text, /This account has been closed\./);
  const rpc = await call('/rest/v1/rpc/set_scan_consent', { method: 'POST', token: target.token, body: { p_on: true } });
  assert.equal(rpc.status, 403, 'an RPC answered a removed golfer');
  const up = await upload(target, 'media', `${target.id}/after-ban.jpg`);
  assert.ok(up.status >= 400, 'Storage took an upload from a removed golfer: ' + up.status);
  // and the founder's own requests are untouched
  assert.equal((await call('/rest/v1/profiles?select=id&limit=1', { token: founder.token })).status, 200);

  const lift = await call('/rest/v1/rpc/unban_account', { method: 'POST', token: founder.token, body: { p_profile: target.id, p_reason: 'QA live restore' } });
  assert.equal(lift.status, 200, lift.text);
  assert.equal((await call('/rest/v1/profiles?select=id&limit=1', { token: target.token })).status, 200, 'a restored golfer is still refused');
});

test('scan: a consent revoked elsewhere is refused before any reservation or provider call', { skip }, async () => {
  const g = await golfer('scanner');
  const usage = async () => Number(sql(`select count(*) from scan_usage where profile_id = '${g.id}'`));
  const scan = () => fetch(FN + '/scan', { method: 'POST', headers: { apikey: ANON, authorization: 'Bearer ' + g.token, 'content-type': 'application/json' },
    body: JSON.stringify({ image: JPEG.toString('base64').repeat(2), media_type: 'image/jpeg' }) });
  // granted on device A, then revoked there
  assert.equal((await call('/rest/v1/rpc/set_scan_consent', { method: 'POST', token: g.token, body: { p_on: true } })).json, true);
  assert.equal((await call('/rest/v1/rpc/set_scan_consent', { method: 'POST', token: g.token, body: { p_on: false } })).json, false);
  // device B scans on its stale yes
  const r = await scan();
  const body = await r.json();
  assert.equal(r.status, 403, JSON.stringify(body));
  assert.equal(body.reason, 'no_consent');
  assert.equal(await usage(), 0, 'a reservation (the step before any provider call) was written');
  // positive control: the refusal above is the consent rule, not a failed read. With a
  // fresh yes the request passes the consent and ban checks and stops at the kill
  // switch (scan is not enabled on this stack), still with no reservation.
  sql(`update app_flags set value = jsonb_set(coalesce(value, '{}'::jsonb), '{enabled}', 'false') where key = 'scan'`);
  assert.equal((await call('/rest/v1/rpc/set_scan_consent', { method: 'POST', token: g.token, body: { p_on: true } })).json, true);
  const ok = await scan();
  const okBody = await ok.json();
  assert.equal(ok.status, 200, JSON.stringify(okBody));
  assert.equal(okBody.reason, 'disabled', 'a consenting golfer did not get past the consent check: ' + JSON.stringify(okBody));
  assert.equal(await usage(), 0);
});

// ---- D403 (review of 0e463792) · only the taken-down object; deletion reaches the hold ----
async function founderAndLeague(...golfers) {
  const founder = await golfer('founder');
  sql(`update profiles set is_founder = false where is_founder; update profiles set is_founder = true where id = '${founder.id}'`);
  const league = randomUUID();
  sql(`insert into leagues (id, name, code, commissioner_id, phase) values ('${league}', 'Live QA', 'LQ${league.slice(0, 4).toUpperCase()}', '${golfers[0].id}', 'season')`);
  for (const [i, g] of golfers.entries()) {
    sql(`insert into league_members (league_id, profile_id, role) values ('${league}', '${g.id}', '${i === 0 ? 'commissioner' : 'player'}')`);
  }
  return founder;
}
async function withAvatar(g) {
  const path = `${g.id}/avatar.jpg`;
  assert.equal((await upload(g, 'media', path)).status, 200);
  sql(`update profiles set photo_path = '${path}' where id = '${g.id}'`);
  return path;
}
async function takeDown(founder, kind, target) {
  const r = await call('/rest/v1/rpc/takedown_photo', { method: 'POST', token: founder.token, body: { p_kind: kind, p_target: target, p_reason: 'QA live takedown' } });
  assert.equal(r.status, 200, r.text);
  return r.json.takedown;
}
const row = (id) => JSON.parse(sql(`select row_to_json(t) from media_takedowns t where id = '${id}'`));
const stored = (bucket, name) => sql(`select count(*) from storage.objects where bucket_id = '${bucket}' and name = '${name}'`) === '1';
const replace = (g, path) => call(`/storage/v1/object/media/${path}`, {
  method: 'POST', token: g.token, body: new Uint8Array(JPEG), headers: { 'content-type': 'image/jpeg', 'x-upsert': 'true' } });

test('a replacement at a taken-down path is refused until the original is confirmed gone, and is never touched after', { skip }, async () => {
  const owner = await golfer('owner3'), mate = await golfer('mate3');
  const founder = await founderAndLeague(owner, mate);
  const path = await withAvatar(owner);
  const id = await takeDown(founder, 'profile_photo', owner.id);
  // before the first cleanup: the path is locked (insert and upsert alike)
  assert.ok((await upload(owner, 'media', path)).status >= 400, 'a replacement was accepted before the first cleanup');
  assert.ok((await replace(owner, path)).status >= 400, 'an upsert replaced the taken-down object');
  const run = await sweep();
  assert.equal(run.status, 200);
  assert.equal(row(id).status, 'removed');
  assert.ok(stored('moderation-hold', row(id).hold_path) && !stored('media', path));
  // inside the grace the path stays locked; once it has run, the golfer's new photo is theirs
  assert.ok((await upload(owner, 'media', path)).status >= 400, 'the path unlocked inside the grace');
  sql(`update media_takedowns set removed_at = now() - interval '11 minutes' where id = '${id}'`);
  assert.equal((await replace(owner, path)).status, 200, 'the replacement was refused after the grace');
  await sweep(); await sweep();
  assert.ok(stored('media', path), 'a later sweep moved or deleted the replacement');
  const link = await sign(mate, path);
  assert.equal(link.status, 200, 'the replacement is hidden: ' + link.text);
  assert.equal(await status(link.url), 200);
});

test("a move that landed but whose report did not: the retry touches nothing at the path", { skip }, async () => {
  const owner = await golfer('owner4');
  const founder = await founderAndLeague(owner);
  const path = await withAvatar(owner);
  const id = await takeDown(founder, 'profile_photo', owner.id);
  // the first worker claimed the row and moved the file; its report never landed
  const claimed = await svc('/rest/v1/rpc/_takedown_cleanup_due', { method: 'POST', body: { p_limit: 50 } });
  assert.equal(claimed.status, 200, claimed.text);
  const mine = claimed.json.find((r) => r.id === id);
  assert.ok(mine?.present, 'the claim did not see the original');
  const moved = await svc(`/storage/v1/object/move`, { method: 'POST', body: { bucketId: 'media', sourceKey: path, destinationKey: row(id).hold_path, destinationBucket: 'moderation-hold' } });
  assert.equal(moved.status, 200, moved.text);
  // the golfer tries to put a new photo there in the meantime: locked
  assert.ok((await upload(owner, 'media', path)).status >= 400, 'a replacement landed while the report was outstanding');
  // the lease runs out; the next run reclaims the row and finds nothing stored
  sql(`update media_takedowns set claimed_until = now() - interval '1 second' where id = '${id}'`);
  const run = await sweep();
  assert.equal(run.status, 200);
  assert.equal(row(id).status, 'removed');
  assert.ok(stored('moderation-hold', row(id).hold_path), 'the evidence was lost');
});

test('overlapping sweeps: each file is moved once, nothing errors', { skip }, async () => {
  const golfers = await Promise.all([golfer('ov1'), golfer('ov2'), golfer('ov3')]);
  const founder = await founderAndLeague(...golfers);
  const ids = [];
  for (const g of golfers) { await withAvatar(g); ids.push(await takeDown(founder, 'profile_photo', g.id)); }
  const [a, b] = await Promise.all([sweep(), sweep()]);
  assert.equal(a.status, 200); assert.equal(b.status, 200);
  for (const id of ids) {
    const r = row(id);
    assert.equal(r.status, 'removed', JSON.stringify(r));
    assert.ok(r.hold_path && stored('moderation-hold', r.hold_path));
    assert.equal(r.attempts, 1, 'a row was worked twice');
  }
});

test('a failed move still removes the published original (the evidence destination already exists)', { skip }, async () => {
  const owner = await golfer('owner5');
  const founder = await founderAndLeague(owner);
  const path = await withAvatar(owner);
  const id = await takeDown(founder, 'profile_photo', owner.id);
  const hold = row(id).hold_path;
  assert.equal((await svc(`/storage/v1/object/moderation-hold/${hold}`, { method: 'POST', body: new Uint8Array(JPEG), headers: { 'content-type': 'image/jpeg' } })).status, 200);
  const run = await sweep();
  const mine = run.json.takedowns.results.find((r) => r.id === id);
  assert.match(mine?.error ?? '', /move to moderation-hold/, JSON.stringify(mine));
  assert.equal(row(id).status, 'removed');
  assert.ok(!stored('media', path), 'the published original survived a failed move');
});

test('account deletion removes the held copy — after quarantine, while pending, and while a move is in flight', { skip }, async () => {
  const after = await golfer('del-after'), pending = await golfer('del-pending'), flight = await golfer('del-flight'), other = await golfer('keeps');
  const founder = await founderAndLeague(other, after, pending, flight);   // the golfer who stays runs the league
  for (const g of [after, pending, flight, other]) await withAvatar(g);
  const idAfter = await takeDown(founder, 'profile_photo', after.id);
  const idOther = await takeDown(founder, 'profile_photo', other.id);
  await sweep();                                                   // both quarantined
  assert.ok(stored('moderation-hold', row(idAfter).hold_path) && stored('moderation-hold', row(idOther).hold_path));
  const idPending = await takeDown(founder, 'profile_photo', pending.id);
  const idFlight = await takeDown(founder, 'profile_photo', flight.id);
  // a worker claims the in-flight row (and everything else due) before the deletions
  const claimed = await svc('/rest/v1/rpc/_takedown_cleanup_due', { method: 'POST', body: { p_limit: 50 } });
  const flightClaim = claimed.json.find((r) => r.id === idFlight);
  assert.ok(flightClaim?.keep, 'setup: the in-flight claim should predate the deletion');
  // the pending row's claim is released (that worker died); the in-flight one is live
  sql(`update media_takedowns set claim = null, claimed_until = null where id = '${idPending}'`);
  for (const g of [after, pending, flight]) {
    const d = await call('/rest/v1/rpc/delete_account', { method: 'POST', token: g.token, body: {} });
    assert.ok(d.status < 300, 'delete_account: ' + d.text);
  }
  let run = await sweep();
  assert.equal(run.status, 200, JSON.stringify(run.json));
  const job = (g) => sql(`select status from account_media_cleanup where profile_id = '${g.id}'`);
  assert.equal(job(after), 'completed', 'the account with a held copy did not complete');
  assert.ok(!stored('moderation-hold', row(idAfter).hold_path ?? '-'), "a deleted golfer's evidence is still held");
  assert.equal(job(pending), 'completed');
  assert.equal(row(idPending).status, 'removed');
  assert.equal(row(idPending).hold_path, null, 'evidence was kept for an account deleted while its takedown was pending');
  assert.notEqual(job(flight), 'completed', 'deletion completed while a move of their photo was in flight');
  // the in-flight worker's move lands after all, and it reports
  const hold = row(idFlight).hold_path;
  const moved = await svc(`/storage/v1/object/move`, { method: 'POST', body: { bucketId: 'media', sourceKey: `${flight.id}/avatar.jpg`, destinationKey: hold, destinationBucket: 'moderation-hold' } });
  // (the account worker may already have removed the original; either way the report decides)
  const rep = await svc('/rest/v1/rpc/_takedown_cleanup_report', { method: 'POST', body: { p_id: idFlight, p_claim: flightClaim.claim, p_phase: 'remove', p_error: moved.status === 200 ? null : 'gone' } });
  assert.equal(rep.json, 'removed', rep.text);
  sql(`update account_media_cleanup set next_attempt_at = now() where profile_id = '${flight.id}'`);
  run = await sweep(); run = await sweep();
  assert.equal(job(flight), 'completed', JSON.stringify(run.json.media));
  assert.ok(!stored('moderation-hold', hold), 'the late copy was left behind after deletion');
  // another golfer's evidence is untouched
  assert.ok(stored('moderation-hold', row(idOther).hold_path), "another golfer's evidence was removed");
  assert.equal(row(idOther).keep_evidence, true);
});
